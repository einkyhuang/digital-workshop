import Foundation

/// Local private CRM helpers for Global Agent (Mac). Never logs full PII to chat — redact in summaries.
enum AgentCRM {
    static func privateCrmRoot(repoRoot: URL) -> URL {
        repoRoot.appendingPathComponent("超级工作台应用/data/private/crm")
    }

    static func settingsDir(repoRoot: URL) -> URL {
        privateCrmRoot(repoRoot: repoRoot).appendingPathComponent("settings")
    }

    static func searchCustomers(repoRoot: URL, query: String, page: Int, limit: Int) -> (Bool, String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let leadsDir = privateCrmRoot(repoRoot: repoRoot).appendingPathComponent("leads")
        let idxURL = leadsDir.appendingPathComponent("leads-index.json")
        guard let idxData = try? Data(contentsOf: idxURL),
              let idx = try? JSONSerialization.jsonObject(with: idxData) as? [String: Any] else {
            return (false, "missing private leads-index.json")
        }
        let pageCount = idx["pageCount"] as? Int ?? 0
        let pageSize = idx["pageSize"] as? Int ?? 100
        var hits: [[String: String]] = []
        let maxScan = min(pageCount, 30) // bound IO
        let startPage = max(0, page)
        for p in startPage..<min(startPage + 5, maxScan) {
            let file = leadsDir.appendingPathComponent(String(format: "page-%04d.json", p))
            guard let data = try? Data(contentsOf: file),
                  let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { continue }
            for row in arr {
                let id = str(row["id"])
                let company = str(row["company"])
                let country = str(row["country"])
                let status = str(row["status"])
                let contact = str(row["contact"])
                let email = str(row["email"])
                let blob = "\(id) \(company) \(country) \(status) \(contact) \(email)".lowercased()
                if q.isEmpty || blob.contains(q) {
                    hits.append([
                        "id": id,
                        "company": redact(company),
                        "country": country,
                        "status": status
                    ])
                }
                if hits.count >= limit { break }
            }
            if hits.count >= limit { break }
        }
        let payload: [String: Any] = [
            "query": query,
            "count": hits.count,
            "pageSize": pageSize,
            "note": "字段已脱敏；完整明细仅本地 private/crm",
            "results": hits
        ]
        return (true, jsonString(payload))
    }

    @MainActor
    static func openCustomer(store: WorkspaceStore, customerId: String) -> (Bool, String) {
        store.switchWorkbench("trade")
        // Prefer CRM module in host sidebar when leaving MagicHub full-bleed —
        // trade workbench currently embeds MagicHub; still set section for when user switches back.
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

    /// L3: never send — return blocked with recap for UI confirm path.
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
