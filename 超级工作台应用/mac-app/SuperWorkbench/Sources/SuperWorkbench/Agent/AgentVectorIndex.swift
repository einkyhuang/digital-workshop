import Foundation
import CryptoKit

/// Local customer vector index under Application Support/超级工作台/vectors/.
/// Never written into the git repo. Cosine top-K in memory after load.
enum AgentVectorIndex {
    static let batchSize = 10
    static let defaultModel = "text-embedding-v4"
    static let fallbackModel = "text-embedding-v3"

    struct Progress: Equatable, Sendable {
        var phase: String
        var done: Int
        var total: Int
        var message: String
        var isRunning: Bool
        var lastError: String?

        static let idle = Progress(phase: "idle", done: 0, total: 0, message: "", isRunning: false, lastError: nil)
    }

    struct Hit: Sendable {
        var id: String
        var score: Double
        var company: String
        var country: String
        var industry: String
        var textPreview: String
    }

    struct Record: Sendable {
        var id: String
        var hash: String
        var text: String
        var company: String
        var country: String
        var industry: String
        var vector: [Float]
    }

    // MARK: - Paths

    static var vectorsDir: URL {
        SharedModelStore.supportDir.appendingPathComponent("vectors", isDirectory: true)
    }

    static var indexFile: URL {
        vectorsDir.appendingPathComponent("customers-index.json")
    }

    static func ensureDir() {
        try? FileManager.default.createDirectory(at: vectorsDir, withIntermediateDirectories: true)
    }

    // MARK: - Industry inference

    static func fieldBlob(_ row: [String: Any], _ key: String) -> String {
        if let arr = row[key] as? [Any] {
            return arr.map { AgentCRM.strPublic($0) }.joined(separator: " ")
        }
        return AgentCRM.strPublic(row[key])
    }

    static func inferIndustry(from row: [String: Any]) -> String {
        let blob = [
            fieldBlob(row, "industry"),
            fieldBlob(row, "product"),
            fieldBlob(row, "products"),
            fieldBlob(row, "mainProducts"),
            fieldBlob(row, "notes"),
            fieldBlob(row, "note"),
            fieldBlob(row, "remark"),
            fieldBlob(row, "company"),
            fieldBlob(row, "tags")
        ].joined(separator: " ").lowercased()
        return inferIndustry(blob: blob)
    }

    static func inferIndustry(blob: String) -> String {
        let auto = ["汽配", "汽车", "汽车零件", "automotive", "auto part", "autopart", "vehicle", "oem", "brake", "tire", "chassis", "engine"]
        let light = ["照明", "灯具", "led", "lighting", "lamp", "bulb", "fixture", "downlight", "筒灯", "灯"]
        let apparel = ["服装", "服饰", "纺织", "面料", "apparel", "garment", "clothing", "fashion", "textile", "fabric"]
        func hit(_ keys: [String]) -> Bool {
            for k in keys where blob.contains(k) { return true }
            return false
        }
        if hit(auto) { return "汽配" }
        if hit(light) { return "照明" }
        if hit(apparel) { return "服装" }
        return "其他"
    }

    // MARK: - Text + hash

    static func customerText(row: [String: Any]) -> String {
        let company = AgentCRM.strPublic(row["company"])
        let country = AgentCRM.strPublic(row["country"])
        let industry = inferIndustry(from: row)
        let products = [
            AgentCRM.strPublic(row["product"]),
            AgentCRM.strPublic(row["products"]),
            AgentCRM.strPublic(row["mainProducts"])
        ].filter { !$0.isEmpty }.joined(separator: " ")
        let notes = [
            AgentCRM.strPublic(row["notes"]),
            AgentCRM.strPublic(row["note"]),
            AgentCRM.strPublic(row["remark"])
        ].filter { !$0.isEmpty }.joined(separator: " ")
        return [
            "公司: \(company)",
            "国家: \(country)",
            "行业: \(industry)",
            "产品: \(products)",
            "备注: \(notes)"
        ].joined(separator: "\n")
    }

    static func contentHash(_ text: String) -> String {
        let data = Data(text.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Persist (JSON)

    private struct FilePayload: Codable {
        var version: Int
        var model: String
        var updatedAt: String
        var records: [FileRecord]
    }

    private struct FileRecord: Codable {
        var id: String
        var hash: String
        var text: String
        var company: String
        var country: String
        var industry: String
        var vector: [Float]
    }

    static func loadRecords() -> (model: String, records: [Record]) {
        ensureDir()
        guard FileManager.default.fileExists(atPath: indexFile.path),
              let data = try? Data(contentsOf: indexFile),
              let payload = try? JSONDecoder().decode(FilePayload.self, from: data) else {
            return ("", [])
        }
        let rows = payload.records.map {
            Record(id: $0.id, hash: $0.hash, text: $0.text, company: $0.company,
                   country: $0.country, industry: $0.industry, vector: $0.vector)
        }
        return (payload.model, rows)
    }

    static func saveRecords(model: String, records: [Record]) throws {
        ensureDir()
        let payload = FilePayload(
            version: 1,
            model: model,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            records: records.map {
                FileRecord(id: $0.id, hash: $0.hash, text: $0.text, company: $0.company,
                           country: $0.country, industry: $0.industry, vector: $0.vector)
            }
        )
        let data = try JSONEncoder().encode(payload)
        let tmp = indexFile.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: indexFile.path) {
            try FileManager.default.removeItem(at: indexFile)
        }
        try FileManager.default.moveItem(at: tmp, to: indexFile)
    }

    static func statusSummary() -> String {
        let (model, records) = loadRecords()
        if records.isEmpty {
            return "向量索引：未建（路径 \(vectorsDir.path)）"
        }
        return "向量索引：\(records.count) 条 · 模型 \(model.isEmpty ? "—" : model)"
    }

    // MARK: - Cosine

    static func cosine(_ a: [Float], _ b: [Float]) -> Double {
        let n = min(a.count, b.count)
        guard n > 0 else { return 0 }
        var dot: Double = 0
        var na: Double = 0
        var nb: Double = 0
        var i = 0
        while i < n {
            let x = Double(a[i])
            let y = Double(b[i])
            dot += x * y
            na += x * x
            nb += y * y
            i += 1
        }
        let denom = sqrt(na) * sqrt(nb)
        guard denom > 1e-12 else { return 0 }
        return dot / denom
    }

    static func topK(query: [Float], records: [Record], k: Int) -> [Hit] {
        let limit = max(1, min(k, 50))
        var scored: [(Record, Double)] = []
        scored.reserveCapacity(records.count)
        for r in records {
            guard !r.vector.isEmpty else { continue }
            scored.append((r, cosine(query, r.vector)))
        }
        scored.sort { $0.1 > $1.1 }
        return scored.prefix(limit).map { r, s in
            Hit(
                id: r.id,
                score: s,
                company: r.company,
                country: r.country,
                industry: r.industry,
                textPreview: String(r.text.prefix(160))
            )
        }
    }

    // MARK: - Embeddings API

    static func resolveEmbeddingEndpoint(baseURL: String) -> URL? {
        var base = SharedModelsAPI.normalizeBase(baseURL)
        if base.isEmpty { return nil }
        // OpenAI-compatible: .../v1/embeddings
        if !base.lowercased().hasSuffix("/v1") && !base.lowercased().contains("/compatible-mode/v1") {
            if base.lowercased().contains("dashscope") {
                // leave as-is if user already set compatible-mode/v1
            } else if !base.lowercased().hasSuffix("/v1") {
                base += "/v1"
            }
        }
        return URL(string: base + "/embeddings")
    }

    static func embedBatch(
        texts: [String],
        baseURL: String,
        apiKey: String,
        model: String
    ) async throws -> [[Float]] {
        guard !texts.isEmpty else { return [] }
        guard let url = resolveEmbeddingEndpoint(baseURL: baseURL) else {
            throw NSError(domain: "AgentVector", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效 embeddings URL"])
        }
        var body: [String: Any] = [
            "model": model,
            "input": texts
        ]
        // DashScope text-embedding-v3/v4 accept optional dimensions; omit for default.
        var req = URLRequest(url: url, timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if code >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP \(code)"
            throw NSError(domain: "AgentVector", code: code, userInfo: [NSLocalizedDescriptionKey: String(msg.prefix(400))])
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "AgentVector", code: 2, userInfo: [NSLocalizedDescriptionKey: "embeddings 非 JSON"])
        }
        // OpenAI shape: data: [{embedding, index}]
        if let arr = obj["data"] as? [[String: Any]] {
            let sorted = arr.sorted { (a, b) -> Bool in
                let ia = (a["index"] as? Int) ?? (a["index"] as? NSNumber)?.intValue ?? 0
                let ib = (b["index"] as? Int) ?? (b["index"] as? NSNumber)?.intValue ?? 0
                return ia < ib
            }
            var out: [[Float]] = []
            for row in sorted {
                if let emb = row["embedding"] as? [Double] {
                    out.append(emb.map { Float($0) })
                } else if let emb = row["embedding"] as? [NSNumber] {
                    out.append(emb.map { $0.floatValue })
                } else if let emb = row["embedding"] as? [Float] {
                    out.append(emb)
                } else {
                    throw NSError(domain: "AgentVector", code: 3, userInfo: [NSLocalizedDescriptionKey: "缺少 embedding 字段"])
                }
            }
            if out.count != texts.count {
                throw NSError(domain: "AgentVector", code: 4, userInfo: [NSLocalizedDescriptionKey: "embedding 数量不匹配"])
            }
            return out
        }
        throw NSError(domain: "AgentVector", code: 5, userInfo: [NSLocalizedDescriptionKey: "无法解析 embeddings 响应"])
    }

    static func embedBatchWithFallback(
        texts: [String],
        baseURL: String,
        apiKey: String,
        preferredModel: String
    ) async throws -> (model: String, vectors: [[Float]]) {
        let primary = preferredModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultModel : preferredModel
        do {
            let v = try await embedBatch(texts: texts, baseURL: baseURL, apiKey: apiKey, model: primary)
            return (primary, v)
        } catch {
            if primary != fallbackModel {
                let v = try await embedBatch(texts: texts, baseURL: baseURL, apiKey: apiKey, model: fallbackModel)
                return (fallbackModel, v)
            }
            throw error
        }
    }

    // MARK: - Collect CRM rows

    static func collectCustomerRows(repoRoot: URL) -> [[String: Any]] {
        guard let idx = AgentCRM.loadLeadsIndex(repoRoot: repoRoot) else { return [] }
        let pageCount = idx["pageCount"] as? Int ?? 0
        let leadsRoot = AgentCRM.leadsDir(repoRoot: repoRoot)
        let hasPages = FileManager.default.fileExists(
            atPath: leadsRoot.appendingPathComponent("page-0000.json").path
        )
        var rows: [[String: Any]] = []
        if hasPages {
            let maxScan = min(pageCount, 191)
            for p in 0..<maxScan {
                let file = leadsRoot.appendingPathComponent(String(format: "page-%04d.json", p))
                guard let data = try? Data(contentsOf: file),
                      let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { continue }
                rows.append(contentsOf: arr)
            }
        } else if let sample = idx["sample"] as? [[String: Any]] {
            rows = sample
        }
        return rows
    }

    // MARK: - Rebuild (incremental by hash)

    static func rebuild(
        repoRoot: URL,
        baseURL: String,
        apiKey: String,
        model: String,
        forceAll: Bool = false,
        onProgress: @escaping @Sendable (Progress) -> Void
    ) async -> (Bool, String) {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            return (false, "缺少 API Key（请在全局设置配置平台密钥）")
        }
        guard resolveEmbeddingEndpoint(baseURL: baseURL) != nil else {
            return (false, "无效 Base URL")
        }

        onProgress(Progress(phase: "scan", done: 0, total: 0, message: "扫描客户…", isRunning: true, lastError: nil))
        let sourceRows = collectCustomerRows(repoRoot: repoRoot)
        if sourceRows.isEmpty {
            onProgress(Progress(phase: "done", done: 0, total: 0, message: "无客户可索引", isRunning: false, lastError: nil))
            return (false, "无客户数据（检查 private/crm/leads）")
        }

        let (_, existing) = loadRecords()
        var byId: [String: Record] = [:]
        for r in existing { byId[r.id] = r }

        var pending: [(id: String, hash: String, text: String, company: String, country: String, industry: String)] = []
        var kept: [Record] = []
        for row in sourceRows {
            let id = AgentCRM.strPublic(row["id"])
            guard !id.isEmpty else { continue }
            let text = customerText(row: row)
            let hash = contentHash(text)
            let company = AgentCRM.strPublic(row["company"])
            let country = AgentCRM.strPublic(row["country"])
            let industry = inferIndustry(from: row)
            if !forceAll, let old = byId[id], old.hash == hash, !old.vector.isEmpty {
                kept.append(old)
            } else {
                pending.append((id, hash, text, company, country, industry))
            }
        }

        let total = pending.count
        onProgress(Progress(
            phase: "embed",
            done: 0,
            total: total,
            message: total == 0 ? "无需更新" : "待嵌入 \(total) 条（保留 \(kept.count)）",
            isRunning: true,
            lastError: nil
        ))

        var usedModel = model
        var embedded: [Record] = []
        var i = 0
        while i < pending.count {
            let end = min(i + batchSize, pending.count)
            let chunk = Array(pending[i..<end])
            let texts = chunk.map(\.text)
            do {
                let result = try await embedBatchWithFallback(
                    texts: texts,
                    baseURL: baseURL,
                    apiKey: key,
                    preferredModel: model
                )
                usedModel = result.model
                for (j, item) in chunk.enumerated() {
                    embedded.append(Record(
                        id: item.id,
                        hash: item.hash,
                        text: item.text,
                        company: item.company,
                        country: item.country,
                        industry: item.industry,
                        vector: result.vectors[j]
                    ))
                }
            } catch {
                let msg = error.localizedDescription
                onProgress(Progress(phase: "error", done: i, total: total, message: msg, isRunning: false, lastError: msg))
                return (false, "嵌入失败：\(msg)")
            }
            i = end
            onProgress(Progress(
                phase: "embed",
                done: i,
                total: total,
                message: "已嵌入 \(i)/\(total)",
                isRunning: true,
                lastError: nil
            ))
        }

        var merged = kept + embedded
        let live: Set<String> = Set(sourceRows.compactMap { row in
            let s = AgentCRM.strPublic(row["id"])
            return s.isEmpty ? nil : s
        })
        merged = merged.filter { live.contains($0.id) }

        do {
            try saveRecords(model: usedModel, records: merged)
        } catch {
            let msg = error.localizedDescription
            onProgress(Progress(phase: "error", done: total, total: total, message: msg, isRunning: false, lastError: msg))
            return (false, "写入索引失败：\(msg)")
        }

        let summary = "完成：共 \(merged.count) 条（更新 \(embedded.count)，保留 \(kept.count)）· 模型 \(usedModel)"
        onProgress(Progress(phase: "done", done: total, total: total, message: summary, isRunning: false, lastError: nil))
        return (true, summary)
    }

    // MARK: - Search

    static func semanticSearch(
        query: String,
        repoRoot: URL,
        baseURL: String,
        apiKey: String,
        model: String,
        topK: Int
    ) async -> (Bool, String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return (false, "query 为空") }
        let (indexModel, records) = loadRecords()
        if records.isEmpty {
            return (false, "向量索引为空。请在全局设置 → 智能体 点击「重建索引」。路径：\(vectorsDir.path)")
        }
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return (false, "缺少 API Key") }
        let pref = model.isEmpty ? (indexModel.isEmpty ? defaultModel : indexModel) : model
        do {
            let result = try await embedBatchWithFallback(
                texts: [q],
                baseURL: baseURL,
                apiKey: key,
                preferredModel: pref
            )
            guard let qv = result.vectors.first else { return (false, "query 嵌入为空") }
            let hits = AgentVectorIndex.topK(query: qv, records: records, k: topK)
            let payload: [String: Any] = [
                "query": q,
                "mode": "vector",
                "topK": topK,
                "indexSize": records.count,
                "model": result.model,
                "count": hits.count,
                "results": hits.map { h -> [String: Any] in
                    [
                        "id": h.id,
                        "score": (h.score * 1000).rounded() / 1000,
                        "company": redactCompany(h.company),
                        "country": h.country,
                        "industry": h.industry,
                        "preview": h.textPreview
                    ]
                }
            ]
            return (true, AgentCRM.jsonStringPublic(payload))
        } catch {
            return (false, "语义检索失败：\(error.localizedDescription)")
        }
    }

    /// Keyword + vector merge.
    static func hybridSearch(
        query: String,
        repoRoot: URL,
        baseURL: String,
        apiKey: String,
        model: String,
        topK: Int
    ) async -> (Bool, String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return (false, "query 为空") }
        let limit = max(1, min(topK, 50))

        let (kwOk, kwRaw) = AgentCRM.searchCustomers(
            repoRoot: repoRoot,
            query: q,
            page: 0,
            limit: limit,
            countOnly: false
        )
        var keywordHits: [[String: Any]] = []
        var matchTotal = 0
        if kwOk, let data = kwRaw.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            matchTotal = (obj["matchTotal"] as? Int) ?? (obj["matchTotal"] as? NSNumber)?.intValue ?? 0
            if let arr = obj["results"] as? [[String: Any]] {
                keywordHits = arr
            } else if let arr = obj["results"] as? [[String: String]] {
                keywordHits = arr.map { dict in
                    var out: [String: Any] = [:]
                    for (k, v) in dict { out[k] = v }
                    return out
                }
            }
        }

        var vectorHits: [Hit] = []
        var vectorNote = ""
        let (indexModel, records) = loadRecords()
        if records.isEmpty {
            vectorNote = "向量索引为空；仅返回关键词结果。请在设置中重建索引。"
        } else if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            vectorNote = "无 API Key；仅关键词。"
        } else {
            let pref = model.isEmpty ? (indexModel.isEmpty ? defaultModel : indexModel) : model
            do {
                let result = try await embedBatchWithFallback(
                    texts: [q],
                    baseURL: baseURL,
                    apiKey: apiKey,
                    preferredModel: pref
                )
                if let qv = result.vectors.first {
                    vectorHits = AgentVectorIndex.topK(query: qv, records: records, k: limit)
                }
            } catch {
                vectorNote = "向量检索失败：\(error.localizedDescription)"
            }
        }

        // Merge: dual hit boost
        var scores: [String: Double] = [:]
        var meta: [String: [String: Any]] = [:]
        for (idx, row) in keywordHits.enumerated() {
            let id = (row["id"] as? String) ?? ""
            guard !id.isEmpty else { continue }
            let kwScore = 1.0 - (Double(idx) * 0.02)
            scores[id, default: 0] += max(0.2, kwScore) + 0.35
            meta[id] = row
            meta[id]?["source"] = "keyword"
        }
        for h in vectorHits {
            scores[h.id, default: 0] += max(0, h.score) + 0.15
            if meta[h.id] == nil {
                meta[h.id] = [
                    "id": h.id,
                    "company": redactCompany(h.company),
                    "country": h.country,
                    "industry": h.industry,
                    "source": "vector",
                    "score": (h.score * 1000).rounded() / 1000
                ]
            } else {
                meta[h.id]?["source"] = "keyword+vector"
                meta[h.id]?["vectorScore"] = (h.score * 1000).rounded() / 1000
                if meta[h.id]?["industry"] == nil {
                    meta[h.id]?["industry"] = h.industry
                }
            }
        }

        let ranked = scores.sorted { $0.value > $1.value }.prefix(limit)
        var results: [[String: Any]] = []
        for (id, sc) in ranked {
            var row = meta[id] ?? ["id": id]
            row["mergedScore"] = (sc * 1000).rounded() / 1000
            results.append(row)
        }

        let payload: [String: Any] = [
            "query": q,
            "mode": "hybrid",
            "matchTotalKeyword": matchTotal,
            "vectorHits": vectorHits.count,
            "indexSize": records.count,
            "topK": limit,
            "count": results.count,
            "note": vectorNote.isEmpty
                ? "关键词 + 向量合并；优先用本结果，勿翻页扫库。"
                : vectorNote,
            "results": results
        ]
        return (true, AgentCRM.jsonStringPublic(payload))
    }

    private static func redactCompany(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= 4 { return t.isEmpty ? "—" : t }
        return String(t.prefix(2)) + "***" + String(t.suffix(1))
    }
}

// MARK: - Progress bridge for Settings UI

@MainActor
final class AgentVectorIndexController: ObservableObject {
    static let shared = AgentVectorIndexController()

    @Published var progress = AgentVectorIndex.Progress.idle

    func rebuild(repoRoot: URL, forceAll: Bool = false) async {
        guard !progress.isRunning else { return }
        let prefs = SharedWorkbenchPrefs.load()
        let providers = SharedModelStore.loadProviders(repoRoot: repoRoot)
        let doc = SharedModelStore.loadDocument(repoRoot: repoRoot)
        let active = providers.first(where: { ($0["id"] as? String) == doc.activeProviderId }) ?? providers.first
        let base = (active?["baseUrl"] as? String) ?? (active?["baseURL"] as? String) ?? ""
        let pid = (active?["id"] as? String) ?? ""
        let key = SharedModelStore.loadKey(providerId: pid)
            ?? (active?["apiKey"] as? String)
            ?? AgentKeychain.loadKey()
            ?? ""
        let model = prefs.embeddingModel.isEmpty ? AgentVectorIndex.defaultModel : prefs.embeddingModel
        progress = AgentVectorIndex.Progress(phase: "start", done: 0, total: 0, message: "开始…", isRunning: true, lastError: nil)
        let (ok, msg) = await AgentVectorIndex.rebuild(
            repoRoot: repoRoot,
            baseURL: base,
            apiKey: key,
            model: model,
            forceAll: forceAll
        ) { [weak self] p in
            Task { @MainActor in
                self?.progress = p
            }
        }
        if !ok, progress.lastError == nil {
            progress = AgentVectorIndex.Progress(
                phase: "error",
                done: progress.done,
                total: progress.total,
                message: msg,
                isRunning: false,
                lastError: msg
            )
        } else if ok {
            progress = AgentVectorIndex.Progress(
                phase: "done",
                done: progress.done,
                total: max(progress.total, progress.done),
                message: msg,
                isRunning: false,
                lastError: nil
            )
        }
    }
}
