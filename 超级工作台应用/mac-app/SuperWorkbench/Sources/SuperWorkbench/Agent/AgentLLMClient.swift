import Foundation

struct AgentLLMError: LocalizedError, Sendable {
    var status: Int
    var message: String
    var provider: String
    var model: String

    var errorDescription: String? {
        let prov = provider.isEmpty ? "—" : provider
        let mod = model.isEmpty ? "—" : model
        if status > 0 {
            return "【模型调用失败】provider=\(prov) · model=\(mod) · HTTP \(status)\n\(message)"
        }
        return "【模型调用失败】provider=\(prov) · model=\(mod)\n\(message)"
    }
}

enum AgentLLMDefaults {
    static let preferredDefaultModel = "qwen3.8-max"
    static let preferredDefaultProviderId = "qwen"
    static let preferredDefaultBaseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
}

/// OpenAI-compatible chat/completions with optional SSE stream + tools.
actor AgentLLMClient {
    struct Config: Equatable {
        var baseURL: String
        var model: String
        var apiKey: String
        /// Display-only provider id/name for error rows (never a secret).
        var providerId: String = ""
        var providerName: String = ""
    }

    func streamChat(
        config: Config,
        messages: [[String: Any]],
        tools: [[String: Any]],
        onDelta: @escaping @Sendable (String) -> Void
    ) async throws -> (content: String, toolCalls: [[String: Any]]) {
        var base = config.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if base.isEmpty {
            throw makeError(config, status: 0, message: "Base URL 为空")
        }
        // Keep .../compatible-mode/v1 and .../v1 as-is; otherwise append /v1.
        let lower = base.lowercased()
        if !lower.hasSuffix("/v1") && !lower.contains("/compatible-mode/v1") {
            base += "/v1"
        }
        guard let url = URL(string: base + "/chat/completions") else {
            throw makeError(config, status: 0, message: "无效 Base URL：\(base)")
        }
        var body: [String: Any] = [
            "model": config.model,
            "messages": messages,
            "stream": true,
            "temperature": 0.2
        ]
        if !tools.isEmpty {
            body["tools"] = tools
            body["tool_choice"] = "auto"
        }
        var req = URLRequest(url: url, timeoutInterval: 90)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (bytes, resp) = try await URLSession.shared.bytes(for: req)
        let http = resp as? HTTPURLResponse
        let status = http?.statusCode ?? 0

        if status >= 400 {
            var errBody = ""
            for try await line in bytes.lines {
                errBody += line
                if errBody.count > 2000 { break }
            }
            throw makeError(config, status: status, message: extractErrorMessage(errBody, fallback: "HTTP \(status)"))
        }

        var content = ""
        var toolAcc: [Int: (id: String, name: String, args: String)] = [:]
        var rawBuffer = ""
        var sawSSE = false

        for try await line in bytes.lines {
            if line.hasPrefix("data:") {
                sawSSE = true
                let payload = line.dropFirst(5).trimmingCharacters(in: .whitespaces)
                if payload == "[DONE]" { break }
                guard let data = payload.data(using: .utf8),
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                if let err = obj["error"] as? [String: Any] {
                    let msg = (err["message"] as? String) ?? String(describing: err)
                    throw makeError(config, status: status == 0 ? 200 : status, message: redactSecrets(msg))
                }
                guard let choices = obj["choices"] as? [[String: Any]],
                      let delta = choices.first?["delta"] as? [String: Any] else { continue }
                if let c = delta["content"] as? String, !c.isEmpty {
                    content += c
                    onDelta(c)
                }
                // Some gateways put full message in stream final chunk
                if let msg = choices.first?["message"] as? [String: Any],
                   let c = msg["content"] as? String, !c.isEmpty, content.isEmpty {
                    content = c
                    onDelta(c)
                }
                if let tcs = delta["tool_calls"] as? [[String: Any]] {
                    accumulateTools(tcs, into: &toolAcc)
                }
            } else if !line.isEmpty {
                rawBuffer += line
                if rawBuffer.count > 500_000 { break }
            }
        }

        // Non-SSE JSON body (gateway ignored stream:true)
        if !sawSSE, !rawBuffer.isEmpty {
            if let data = rawBuffer.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let err = obj["error"] as? [String: Any] {
                    let msg = (err["message"] as? String) ?? String(describing: err)
                    throw makeError(config, status: status == 0 ? 200 : status, message: redactSecrets(msg))
                }
                if let choices = obj["choices"] as? [[String: Any]], let first = choices.first {
                    if let msg = first["message"] as? [String: Any] {
                        if let c = msg["content"] as? String { content = c }
                        if let tcs = msg["tool_calls"] as? [[String: Any]] {
                            accumulateTools(tcs, into: &toolAcc)
                        }
                    }
                    if let c = first["text"] as? String, content.isEmpty { content = c }
                }
            } else {
                throw makeError(
                    config,
                    status: status,
                    message: "响应不是 SSE/JSON：\(redactSecrets(String(rawBuffer.prefix(280))))"
                )
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

        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && toolCalls.isEmpty {
            throw makeError(
                config,
                status: status == 0 ? 200 : status,
                message: sawSSE
                    ? "流式响应结束但未返回文本或工具调用（模型可能不支持 tools，或网关未正确流式输出）。"
                    : "空响应。请检查模型 id 是否有效、是否支持 chat/completions。"
            )
        }
        return (content, toolCalls)
    }

    private func accumulateTools(_ tcs: [[String: Any]], into toolAcc: inout [Int: (id: String, name: String, args: String)]) {
        for tc in tcs {
            let idx = tc["index"] as? Int ?? (tc["index"] as? NSNumber)?.intValue ?? 0
            var cur = toolAcc[idx] ?? (id: "", name: "", args: "")
            if let id = tc["id"] as? String { cur.id = id }
            if let fn = tc["function"] as? [String: Any] {
                if let n = fn["name"] as? String { cur.name += n }
                if let a = fn["arguments"] as? String { cur.args += a }
            }
            toolAcc[idx] = cur
        }
    }

    private func makeError(_ config: Config, status: Int, message: String) -> AgentLLMError {
        AgentLLMError(
            status: status,
            message: redactSecrets(message),
            provider: config.providerName.isEmpty ? config.providerId : config.providerName,
            model: config.model
        )
    }

    private func extractErrorMessage(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        if let data = trimmed.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let err = obj["error"] as? [String: Any] {
                if let m = err["message"] as? String { return redactSecrets(m) }
                if let m = err["code"] as? String { return redactSecrets(m) }
            }
            if let m = obj["message"] as? String { return redactSecrets(m) }
        }
        return redactSecrets(String(trimmed.prefix(400)))
    }

    private func redactSecrets(_ s: String) -> String {
        var out = s
        // Never echo bearer tokens / long key-looking strings
        if let regex = try? NSRegularExpression(pattern: #"(sk-[A-Za-z0-9_\-]{8,}|Bearer\s+[A-Za-z0-9_\-\.]{8,})"#, options: [.caseInsensitive]) {
            let range = NSRange(out.startIndex..<out.endIndex, in: out)
            out = regex.stringByReplacingMatches(in: out, options: [], range: range, withTemplate: "[REDACTED]")
        }
        return out
    }

    static let preferredDefaultModel = AgentLLMDefaults.preferredDefaultModel
    static let preferredDefaultProviderId = AgentLLMDefaults.preferredDefaultProviderId
    static let preferredDefaultBaseURL = AgentLLMDefaults.preferredDefaultBaseURL

    static func openAIToolsFromSchema(includeDelegation: Bool = true) -> [[String: Any]] {
        let all: [[String: Any]] = [
            tool("list_employees", "列出工作台全部数字员工（id/姓名/简介），供总调度选型", [String: Any](), []),
            tool("delegate_to_employee", "把任务委派给指定员工；员工用其人设与模型作答并写入私有会话与工作摘要", ["botId": ["type": "string"], "task": ["type": "string"]], ["botId", "task"]),
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
            tool("crm_stats", "客户库统计：总数/国家/阶段/星级/来源分布与近期样本（同源 leads-index）", ["topN": ["type": "integer"]], []),
            tool("system_overview", "工作台总览：客户/员工/任务/项目/deliverables 计数", [String: Any](), []),
            tool("crm.search_customers", "模糊搜索客户（company/country/product/notes）；返回 matchTotal；countOnly=true 只计数不翻页", ["query": ["type": "string"], "page": ["type": "integer"], "limit": ["type": "integer"], "countOnly": ["type": "boolean"]], []),
            tool("semantic_search_customers", "语义+关键词混合搜客户（向量索引）；自然语言如「德国做LED筒灯的」；优先于翻页", ["query": ["type": "string"], "topK": ["type": "integer"]], ["query"]),
            tool("crm.open_customer", "打开客户", ["customerId": ["type": "string"]], ["customerId"]),
            tool("crm.upsert_followup", "追加跟进", ["customerId": ["type": "string"], "note": ["type": "string"]], ["customerId", "note"]),
            tool("crm.create_quote", "报价草稿(L2)", ["customerId": ["type": "string"], "title": ["type": "string"], "amount": ["type": "string"], "currency": ["type": "string"], "note": ["type": "string"]], ["customerId"]),
            tool("crm.send_email", "发信(L3拦截)", ["to": ["type": "string"], "subject": ["type": "string"], "body": ["type": "string"]], ["to", "subject"]),
            tool("external.publish", "发布(L3拦截)", ["channel": ["type": "string"], "summary": ["type": "string"]], ["channel", "summary"])
        ]
        if includeDelegation { return all }
        return all.filter { row in
            guard let fn = row["function"] as? [String: Any], let name = fn["name"] as? String else { return true }
            return name != "list_employees" && name != "delegate_to_employee"
        }
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
