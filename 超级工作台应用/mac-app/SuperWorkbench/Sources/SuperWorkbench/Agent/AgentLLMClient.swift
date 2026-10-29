import Foundation

/// OpenAI-compatible chat/completions with optional SSE stream + tools.
actor AgentLLMClient {
    struct Config: Equatable {
        var baseURL: String
        var model: String
        var apiKey: String
    }

    func streamChat(
        config: Config,
        messages: [[String: Any]],
        tools: [[String: Any]],
        onDelta: @escaping @Sendable (String) -> Void
    ) async throws -> (content: String, toolCalls: [[String: Any]]) {
        var base = config.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if base.hasSuffix("/v1") == false { base += "/v1" }
        guard let url = URL(string: base + "/chat/completions") else {
            throw NSError(domain: "AgentLLM", code: 1, userInfo: [NSLocalizedDescriptionKey: "bad baseURL"])
        }
        var body: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "stream": true,
            "temperature": 0.2
        ]
        if !tools.isEmpty { body["tools"] = tools; body["tool_choice"] = "auto" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw NSError(domain: "AgentLLM", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }

        var content = ""
        var toolAcc: [Int: (id: String, name: String, args: String)] = [:]
        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" { break }
            guard let data = payload.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = obj["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any] else { continue }
            if let c = delta["content"] as? String, !c.isEmpty {
                content += c
                onDelta(c)
            }
            if let tcs = delta["tool_calls"] as? [[String: Any]] {
                for tc in tcs {
                    let idx = tc["index"] as? Int ?? 0
                    var cur = toolAcc[idx] ?? (id: "", name: "", args: "")
                    if let id = tc["id"] as? String { cur.id = id }
                    if let fn = tc["function"] as? [String: Any] {
                        if let n = fn["name"] as? String { cur.name += n }
                        if let a = fn["arguments"] as? String { cur.args += a }
                    }
                    toolAcc[idx] = cur
                }
            }
        }
        let toolCalls: [[String: Any]] = toolAcc.keys.sorted().compactMap { idx in
            guard let t = toolAcc[idx], !t.name.isEmpty else { return nil }
            return [
                "id": t.id.isEmpty ? "call_\(idx)" : t.id,
                "type": "function",
                "function": ["name": t.name, "arguments": t.args]
            ]
        }
        return (content, toolCalls)
    }

    static func openAIToolsFromSchema() -> [[String: Any]] {
        [
            tool("context.get_snapshot", "只读快照", ["scope": ["type": "string", "enum": ["brief", "full"]]], []),
            tool("nav.open_section", "打开模块", ["sectionId": ["type": "string"]], ["sectionId"]),
            tool("nav.switch_workbench", "切换工作台", ["workbenchId": ["type": "string"]], ["workbenchId"]),
            tool("schedule.open_day", "打开日程日", ["date": ["type": "string"]], ["date"]),
            tool("daily.open_report", "打开日报", ["date": ["type": "string"]], ["date"]),
            tool("task.create", "创建任务", ["title": ["type": "string"], "note": ["type": "string"], "executor": ["type": "string"], "reviewer": ["type": "string"], "status": ["type": "string"]], ["title"]),
            tool("task.update", "更新任务", ["id": ["type": "string"], "title": ["type": "string"], "note": ["type": "string"]], ["id"]),
            tool("task.set_status", "改任务状态", ["id": ["type": "string"], "status": ["type": "string"]], ["id", "status"]),
            tool("task.delete", "删除任务(需确认)", ["id": ["type": "string"]], ["id"]),
            tool("agent.undo_last", "撤销上次可逆写", [String: Any](), []),
            tool("crm.search_customers", "本地搜索客户", ["query": ["type": "string"], "page": ["type": "integer"], "limit": ["type": "integer"]], []),
            tool("crm.open_customer", "打开客户", ["customerId": ["type": "string"]], ["customerId"]),
            tool("crm.upsert_followup", "追加跟进", ["customerId": ["type": "string"], "note": ["type": "string"]], ["customerId", "note"]),
            tool("crm.create_quote", "报价草稿(L2)", ["customerId": ["type": "string"], "title": ["type": "string"], "amount": ["type": "string"], "currency": ["type": "string"], "note": ["type": "string"]], ["customerId"]),
            tool("crm.send_email", "发信(L3拦截)", ["to": ["type": "string"], "subject": ["type": "string"], "body": ["type": "string"]], ["to", "subject"]),
            tool("external.publish", "发布(L3拦截)", ["channel": ["type": "string"], "summary": ["type": "string"]], ["channel", "summary"])
        ]
    }

    private static func tool(_ name: String, _ desc: String, _ props: [String: Any], _ required: [String]) -> [String: Any] {
        [
            "type": "function",
            "function": [
                "name": name,
                "description": desc,
                "parameters": [
                    "type": "object",
                    "properties": props,
                    "required": required
                ]
            ]
        ]
    }
}
