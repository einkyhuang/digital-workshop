import Foundation

/// Local private CRM helpers for Global Agent (Mac). Never logs full PII to chat — redact in summaries.
///
/// 客户管理总数来源（与 TradeHub / WorkspaceStore.crmLeadsTotal 一致）：
/// 优先 `超级工作台应用/data/private/crm/leads/leads-index.json` 的 `total`，
/// 否则回退公开索引 `超级工作台应用/data/crm/leads-index.json`。
/// MagicHub「客户管理」页的 `leads.length` 来自 settings `magichub_leads`（工作集，可能小于全库）。
enum AgentCRM {
    static func privateCrmRoot(repoRoot: URL) -> URL {
        repoRoot.appendingPathComponent("超级工作台应用/data/private/crm")
    }

    static func settingsDir(repoRoot: URL) -> URL {
        privateCrmRoot(repoRoot: repoRoot).appendingPathComponent("settings")
    }

    static func leadsDir(repoRoot: URL) -> URL {
        privateCrmRoot(repoRoot: repoRoot).appendingPathComponent("leads")
    }

    /// Resolve index the same way TradeHubViews.loadInitial does.
    static func loadLeadsIndex(repoRoot: URL) -> [String: Any]? {
        let priv = leadsDir(repoRoot: repoRoot).appendingPathComponent("leads-index.json")
        let pub = repoRoot.appendingPathComponent("超级工作台应用/data/crm/leads-index.json")
        let url: URL
        if FileManager.default.fileExists(atPath: priv.path) {
            url = priv
        } else if FileManager.default.fileExists(atPath: pub.path) {
            url = pub
        } else {
            return nil
        }
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return obj
    }

    static func indexTotal(repoRoot: URL) -> Int {
        let idx = loadLeadsIndex(repoRoot: repoRoot)
        if let t = idx?["total"] as? Int { return t }
        if let n = idx?["total"] as? NSNumber { return n.intValue }
        return 0
    }

    /// MagicHub working-set size (CustomerSea `leads.length`).
    static func magichubLeadsCount(repoRoot: URL) -> Int {
        let url = settingsDir(repoRoot: repoRoot).appendingPathComponent("magichub_leads.json")
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) else { return 0 }
        if let arr = obj as? [Any] { return arr.count }
        if let d = obj as? [String: Any], let arr = d["data"] as? [Any] { return arr.count }
        return 0
    }

    // MARK: - Search (fuzzy + total match count)

    static func searchCustomers(
        repoRoot: URL,
        query: String,
        page: Int,
        limit: Int,
        countOnly: Bool = false
    ) -> (Bool, String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let tokens = q.split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == ";" || $0 == "/" })
            .map(String.init)
            .filter { !$0.isEmpty }
        guard let idx = loadLeadsIndex(repoRoot: repoRoot) else {
            return (false, "missing leads-index.json（private 或 data/crm）")
        }
        let pageCount = idx["pageCount"] as? Int ?? 0
        let pageSize = idx["pageSize"] as? Int ?? 100
        let indexTotal = self.indexTotal(repoRoot: repoRoot)
        let leadsRoot = leadsDir(repoRoot: repoRoot)
        let hasPages = FileManager.default.fileExists(
            atPath: leadsRoot.appendingPathComponent("page-0000.json").path
        )

        // No private pages: fall back to index sample only.
        if !hasPages {
            let sample = (idx["sample"] as? [[String: Any]]) ?? []
            let matched = sample.filter { rowMatches($0, tokens: tokens, rawQuery: q) }
            let payload: [String: Any] = [
                "query": query,
                "matchTotal": matched.count,
                "total": indexTotal,
            "indexTotal": indexTotal,
                "count": countOnly ? matched.count : min(matched.count, max(1, limit)),
                "countOnly": countOnly,
                "pageSize": pageSize,
                "note": "仅公开索引 sample（完整 page-*.json 在本地 private/crm/leads）；indexTotal=\(indexTotal)",
                "results": countOnly ? [] : Array(matched.prefix(max(1, limit))).map { redactRow($0) }
            ]
            return (true, jsonString(payload))
        }

        let maxScan = min(pageCount, 191)
        let startPage = max(0, page)
        // For aggregate accuracy, scan all pages when countOnly or query present; still bound.
        let pagesToScan: Range<Int>
        if countOnly || !tokens.isEmpty || q.isEmpty {
            pagesToScan = 0..<maxScan
        } else {
            pagesToScan = startPage..<min(startPage + 8, maxScan)
        }

        var matchTotal = 0
        var hits: [[String: String]] = []
        let resultLimit = max(1, min(limit <= 0 ? 30 : limit, 100))
        let skip = max(0, page) * (countOnly ? 0 : resultLimit)
        var skipped = 0

        for p in pagesToScan {
            let file = leadsRoot.appendingPathComponent(String(format: "page-%04d.json", p))
            guard let data = try? Data(contentsOf: file),
                  let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { continue }
            for row in arr {
                let ok: Bool
                if tokens.isEmpty && q.isEmpty {
                    ok = true
                } else {
                    ok = rowMatches(row, tokens: tokens, rawQuery: q)
                }
                guard ok else { continue }
                matchTotal += 1
                if countOnly { continue }
                if skipped < skip {
                    skipped += 1
                    continue
                }
                if hits.count < resultLimit {
                    hits.append(redactRow(row))
                }
            }
        }

        let payload: [String: Any] = [
            "query": query,
            "matchTotal": matchTotal,
            "indexTotal": indexTotal,
            "count": countOnly ? matchTotal : hits.count,
            "countOnly": countOnly,
            "page": page,
            "pageSize": pageSize,
            "returned": hits.count,
            "note": "fuzzy 匹配 company/country/product/notes/tags/contact/status；字段已脱敏。优先用 matchTotal / crm_stats，勿翻页扫全库。",
            "results": hits
        ]
        return (true, jsonString(payload))
    }

    // MARK: - Stats

    static func crmStats(repoRoot: URL, topN: Int = 8) -> (Bool, String) {
        let n = max(3, min(topN, 20))
        guard let idx = loadLeadsIndex(repoRoot: repoRoot) else {
            return (false, "missing leads-index.json")
        }
        let indexTotal = self.indexTotal(repoRoot: repoRoot)
        let pageCount = idx["pageCount"] as? Int ?? 0
        let pageSize = idx["pageSize"] as? Int ?? 100
        let mhCount = magichubLeadsCount(repoRoot: repoRoot)
        let leadsRoot = leadsDir(repoRoot: repoRoot)
        let hasPages = FileManager.default.fileExists(
            atPath: leadsRoot.appendingPathComponent("page-0000.json").path
        )

        var byCountry: [String: Int] = [:]
        var byStatus: [String: Int] = [:]
        var byStage: [String: Int] = [:]
        var byStar: [String: Int] = [:]
        var bySource: [String: Int] = [:]
        var recent: [[String: String]] = []
        var scanned = 0

        if hasPages {
            let maxScan = min(pageCount, 191)
            for p in 0..<maxScan {
                let file = leadsRoot.appendingPathComponent(String(format: "page-%04d.json", p))
                guard let data = try? Data(contentsOf: file),
                      let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { continue }
                for row in arr {
                    scanned += 1
                    bump(&byCountry, key: nonEmpty(str(row["country"]), fallback: "未知"))
                    bump(&byStatus, key: nonEmpty(str(row["status"]), fallback: nonEmpty(str(row["stage"]), fallback: "未知")))
                    bump(&byStage, key: nonEmpty(str(row["stage"]), fallback: nonEmpty(str(row["status"]), fallback: "未知")))
                    let star = str(row["star"]).isEmpty ? str(row["tier"]).isEmpty ? str(row["rating"]) : str(row["tier"]) : str(row["star"])
                    bump(&byStar, key: nonEmpty(star, fallback: "未分级"))
                    bump(&bySource, key: nonEmpty(str(row["source"]), fallback: "未知"))
                    if recent.count < n {
                        recent.append(redactRow(row))
                    }
                }
            }
        } else if let sample = idx["sample"] as? [[String: Any]] {
            for row in sample {
                bump(&byCountry, key: nonEmpty(str(row["country"]), fallback: "未知"))
                bump(&byStatus, key: nonEmpty(str(row["status"]), fallback: "未知"))
                recent.append(redactRow(row))
            }
            scanned = sample.count
        }

        let payload: [String: Any] = [
            "source": hasPages
                ? "private/crm/leads/leads-index.json + page-*.json"
                : "data/crm/leads-index.json (public index; pages missing)",
            "indexTotal": indexTotal,
            "magichubWorkingSet": mhCount,
            "scannedRows": scanned,
            "pageCount": pageCount,
            "pageSize": pageSize,
            "byCountry": topDict(byCountry, n: n),
            "byStatus": topDict(byStatus, n: n),
            "byStage": topDict(byStage, n: n),
            "byStarTier": topDict(byStar, n: n),
            "bySource": topDict(bySource, n: n),
            "recentSample": Array(recent.prefix(n)),
            "note": "indexTotal 与客户管理/CRM 看板同源（leads-index.total）。MagicHub 页 leads.length 为 magichubWorkingSet。明细脱敏。"
        ]
        return (true, jsonString(payload))
    }

    // MARK: - System overview

    static func systemOverview(repoRoot: URL, storeBots: Int, storeTasks: Int, storeProjects: Int) -> (Bool, String) {
        let customers = indexTotal(repoRoot: repoRoot)
        let mh = magichubLeadsCount(repoRoot: repoRoot)
        let deliverables = countDeliverables(repoRoot: repoRoot)
        let payload: [String: Any] = [
            "customers": customers,
            "customersIndexTotal": customers,
            "magichubWorkingSet": mh,
            "bots": storeBots,
            "tasks": storeTasks,
            "websiteProjects": storeProjects,
            "botDeliverableDirs": deliverables,
            "sources": [
                "customers": "leads-index.json total（private 优先）",
                "bots_tasks_projects": "workspace.json",
                "deliverables": "bots/*/*/deliverables 目录计数"
            ]
        ]
        return (true, jsonString(payload))
    }

    /// Compact one-liner for system prompt injection (totals only).
    static func liveSnapshotLine(repoRoot: URL, bots: Int, tasks: Int, projects: Int) -> String {
        let customers = indexTotal(repoRoot: repoRoot)
        let mh = magichubLeadsCount(repoRoot: repoRoot)
        return "实时快照：客户全库 \(customers)（MagicHub 工作集 \(mh)）· 员工 \(bots) · 任务 \(tasks) · 网站项目 \(projects）。问总数请直接用这些数字或 crm_stats / system_overview，禁止翻页扫库。"
    }

    // MARK: - Match helpers

    private static func rowMatches(_ row: [String: Any], tokens: [String], rawQuery: String) -> Bool {
        let company = str(row["company"])
        let country = str(row["country"])
        let product = str(row["product"]) + " " + str(row["products"]) + " " + str(row["mainProducts"])
        let notes = str(row["notes"]) + " " + str(row["note"]) + " " + str(row["remark"])
        let tags: String
        if let arr = row["tags"] as? [Any] {
            tags = arr.map { str($0) }.joined(separator: " ")
        } else {
            tags = str(row["tags"])
        }
        let contact = str(row["contact"])
        let status = str(row["status"]) + " " + str(row["stage"])
        let blob = "\(company) \(country) \(product) \(notes) \(tags) \(contact) \(status) \(str(row["id"]))".lowercased()
        if tokens.isEmpty {
            return rawQuery.isEmpty || blob.contains(rawQuery)
        }
        // All tokens must fuzzy-hit (substring).
        for t in tokens {
            if !blob.contains(t) { return false }
        }
        return true
    }

    private static func redactRow(_ row: [String: Any]) -> [String: String] {
        [
            "id": str(row["id"]),
            "company": redact(str(row["company"])),
            "country": str(row["country"]),
            "status": nonEmpty(str(row["status"]), fallback: str(row["stage"])),
            "stage": str(row["stage"]),
            "source": str(row["source"])
        ]
    }

    private static func bump(_ dict: inout [String: Int], key: String) {
        dict[key, default: 0] += 1
    }

    private static func topDict(_ dict: [String: Int], n: Int) -> [[String: Any]] {
        dict.sorted { $0.value > $1.value }.prefix(n).map { ["key": $0.key, "count": $0.value] }
    }

    private static func nonEmpty(_ s: String, fallback: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? fallback : t
    }

    private static func countDeliverables(repoRoot: URL) -> Int {
        let bots = repoRoot.appendingPathComponent("bots")
        guard let en = FileManager.default.enumerator(
            at: bots,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var n = 0
        var guardCount = 0
        while let url = en.nextObject() as? URL {
            guardCount += 1
            if guardCount > 20_000 { break }
            if url.lastPathComponent == "deliverables" {
                n += 1
                en.skipDescendants()
            }
        }
        return n
    }

    @MainActor
    static func openCustomer(store: WorkspaceStore, customerId: String) -> (Bool, String) {
        store.switchWorkbench("trade")
        store.selectedSection = .crmCustomers
        return (true, "switched to trade/crmCustomers; customerId=\(customerId)（请在 MagicHub 客户列表定位）")
    }

    static func upsertFollowup(repoRoot: URL, customerId: String, note: String) -> (Bool, String) {
        let url = settingsDir(repoRoot: repoRoot).appendingPathComponent("magichub_timeline_logs.json")
        var arr: [[String: Any]] = []
        if let data = try? Data(contentsOf: url),
           let obj = try? JSONSerialization.jsonObject(with: data) {
            if let a = obj as? [[String: Any]] { arr = a }
            else if let d = obj as? [String: Any], let a = d["data"] as? [[String: Any]] { arr = a }
        }
        let entry: [String: Any] = [
            "id": UUID().uuidString,
            "customerId": customerId,
            "note": note,
            "source": "global-agent",
            "at": ISO8601DateFormatter().string(from: Date())
        ]
        arr.append(entry)
        do {
            try FileManager.default.createDirectory(at: settingsDir(repoRoot: repoRoot), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted])
            try data.write(to: url, options: .atomic)
            return (true, "followup appended for customerId=\(customerId)")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    static func createQuoteDraft(repoRoot: URL, params: [String: Any]) -> (Bool, String) {
        guard let customerId = params["customerId"] as? String else { return (false, "missing customerId") }
        let url = settingsDir(repoRoot: repoRoot).appendingPathComponent("magichub_quote_logs.json")
        var arr: [[String: Any]] = []
        if let data = try? Data(contentsOf: url),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            arr = obj
        }
        let draft: [String: Any] = [
            "id": UUID().uuidString,
            "customerId": customerId,
            "title": params["title"] as? String ?? "报价草稿",
            "amount": params["amount"] as? String ?? "",
            "currency": params["currency"] as? String ?? "USD",
            "note": params["note"] as? String ?? "",
            "status": "draft",
            "source": "global-agent",
            "at": ISO8601DateFormatter().string(from: Date())
        ]
        arr.append(draft)
        do {
            try FileManager.default.createDirectory(at: settingsDir(repoRoot: repoRoot), withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted])
            try data.write(to: url, options: .atomic)
            return (true, "quote draft saved id=\(draft["id"] ?? "") customerId=\(customerId)")
        } catch {
            return (false, error.localizedDescription)
        }
    }

    static func blockedSendEmail(params: [String: Any]) -> (Bool, String) {
        let to = params["to"] as? String ?? ""
        let subject = params["subject"] as? String ?? ""
        let body = params["body"] as? String ?? ""
        return (false, "L3 已拦截：不会真发邮件。to=\(redact(to)) subject=\(subject) bodyLen=\(body.count)")
    }

    static func blockedPublish(params: [String: Any]) -> (Bool, String) {
        let channel = params["channel"] as? String ?? ""
        let summary = params["summary"] as? String ?? ""
        return (false, "L3 已拦截：不会对外发布。channel=\(channel) summary=\(String(summary.prefix(120)))")
    }

    private static func str(_ v: Any?) -> String {
        if let s = v as? String { return s }
        if let n = v as? NSNumber { return n.stringValue }
        return ""
    }

    private static func redact(_ s: String) -> String {
        guard s.count > 2 else { return "***" }
        return String(s.prefix(1)) + String(repeating: "*", count: min(6, s.count - 1))
    }

    private static func jsonString(_ obj: Any) -> String {
        guard JSONSerialization.isValidJSONObject(obj),
              let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }
}
