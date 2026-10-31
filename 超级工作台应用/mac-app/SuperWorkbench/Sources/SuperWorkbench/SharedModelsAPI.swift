import Foundation

/// OpenAI-compatible / Gemini native model list + connection probe.
enum SharedModelsAPI {
    struct ProbeResult: Equatable {
        var ok: Bool
        var message: String
        var modelIds: [String]
        var url: String
        var latencyMs: Int
    }

    static func normalizeBase(_ base: String) -> String {
        base.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    static func modelsURL(providerId: String, baseURL: String, apiKey: String) -> (url: URL?, headers: [String: String], style: String) {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = normalizeBase(baseURL)
        let isGeminiNative = providerId == "gemini"
            && base.localizedCaseInsensitiveContains("googleapis.com")
            && !base.localizedCaseInsensitiveContains("/openai")
        if isGeminiNative || (providerId == "gemini" && base.localizedCaseInsensitiveContains("api.gemini.net")) {
            var comp = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models")
            comp?.queryItems = [URLQueryItem(name: "key", value: key)]
            return (comp?.url, [:], "gemini")
        }
        let path = base.lowercased().hasSuffix("/models") ? base : (base + "/models")
        guard let url = URL(string: path) else { return (nil, [:], "openai") }
        return (url, ["Authorization": "Bearer \(key)"], "openai")
    }

    static func parseModelIds(json: Any, style: String) -> [String] {
        if let dict = json as? [String: Any] {
            if let data = dict["data"] as? [[String: Any]] {
                return data.compactMap { ($0["id"] as? String) ?? ($0["name"] as? String) }.filter { !$0.isEmpty }
            }
            if let models = dict["models"] as? [[String: Any]] {
                return models.compactMap { row -> String? in
                    let n = (row["name"] as? String) ?? (row["id"] as? String) ?? ""
                    if n.hasPrefix("models/") { return String(n.dropFirst("models/".count)) }
                    return n.isEmpty ? nil : n
                }
            }
            if let data = dict["data"] as? [String] { return data.filter { !$0.isEmpty } }
        }
        if let arr = json as? [[String: Any]] {
            return arr.compactMap { ($0["id"] as? String) ?? ($0["name"] as? String) }.filter { !$0.isEmpty }
        }
        if let arr = json as? [String] { return arr.filter { !$0.isEmpty } }
        _ = style
        return []
    }

    static func fetchModels(providerId: String, baseURL: String, apiKey: String) async -> ProbeResult {
        let started = Date()
        let built = modelsURL(providerId: providerId, baseURL: baseURL, apiKey: apiKey)
        guard let url = built.url else {
            return ProbeResult(ok: false, message: "无效的 Base URL", modelIds: [], url: baseURL, latencyMs: 0)
        }
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ProbeResult(ok: false, message: "请先填写 API Key", modelIds: [], url: url.absoluteString, latencyMs: 0)
        }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "GET"
        for (k, v) in built.headers { req.setValue(v, forHTTPHeaderField: k) }
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            let http = resp as? HTTPURLResponse
            let code = http?.statusCode ?? 0
            if code >= 400 {
                let body = String(data: data, encoding: .utf8) ?? ""
                var msg = "HTTP \(code)"
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let err = obj["error"] as? [String: Any], let m = err["message"] as? String { msg = m }
                    else if let m = obj["message"] as? String { msg = m }
                } else if !body.isEmpty {
                    msg = String(body.prefix(400))
                }
                return ProbeResult(ok: false, message: msg + "\n探测地址：\(url.absoluteString)", modelIds: [], url: url.absoluteString, latencyMs: ms)
            }
            let obj = try JSONSerialization.jsonObject(with: data)
            let ids = parseModelIds(json: obj, style: built.style)
            if ids.isEmpty {
                return ProbeResult(ok: false, message: "接口成功但未解析到模型（期望 data[].id 或 models[].name）\n探测地址：\(url.absoluteString)", modelIds: [], url: url.absoluteString, latencyMs: ms)
            }
            return ProbeResult(ok: true, message: "已拉取 \(ids.count) 个模型", modelIds: ids, url: url.absoluteString, latencyMs: ms)
        } catch {
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            var msg = error.localizedDescription
            if (error as NSError).code == NSURLErrorTimedOut {
                msg = "请求超时（请检查 Base URL / 代理）"
            }
            return ProbeResult(ok: false, message: msg + "\n探测地址：\(url.absoluteString)", modelIds: [], url: url.absoluteString, latencyMs: ms)
        }
    }
}
