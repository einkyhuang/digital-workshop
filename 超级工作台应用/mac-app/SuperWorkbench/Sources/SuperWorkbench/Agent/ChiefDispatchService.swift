import Foundation

/// Chief (大可可) dispatcher: list employees + delegate sub-conversations.
enum ChiefDispatchService {
    static let chiefBotId = "chief"
    static let maxParallelDelegations = 3

    struct PreparedEmployee: Sendable {
        let botId: String
        let botName: String
        let systemPrompt: String
        let baseURL: String
        let model: String
        let apiKey: String
    }

    struct DelegationResult: Sendable {
        let botId: String
        let botName: String
        let task: String
        let ok: Bool
        let output: String
        let summary: String
        let ms: Int
        let sessionFileName: String
    }

    /// Snapshot for list_employees tool (JSON string). Call on MainActor.
    @MainActor
    static func listEmployeesJSON(store: WorkspaceStore) -> String {
        let bots = store.data.bots
        var rows: [[String: String]] = []
        for b in bots {
            let desc: String
            if !b.duty.isEmpty {
                desc = b.duty
            } else if !b.role.isEmpty {
                desc = b.role
            } else {
                desc = b.skills
            }
            rows.append([
                "id": b.id,
                "name": b.name,
                "description": String(desc.prefix(160))
            ])
        }
        let payload: [String: Any] = [
            "count": rows.count,
            "employees": rows
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let s = String(data: data, encoding: .utf8) else {
            return "{\"count\":0,\"employees\":[]}"
        }
        return s
    }

    @MainActor
    static func chiefSystemPrompt(store: WorkspaceStore, skillBlock: String, snapshot: String) -> String {
        let chief = store.bot(id: chiefBotId)
        let persona: String
        if let chief {
            persona = EmployeeChatStore.buildSystemPrompt(bot: chief, repoRoot: store.repoRoot, skillBlock: "")
        } else {
            persona = "你是超级工作台的总调度「大可可-最强大脑」。"
        }
        return """
        \(persona)

        你是工作台的总调度（chief）。用户只需要和你对话；你负责理解需求、挑选合适的数字员工、委派任务并汇总结果。
        工作台快照：
        \(snapshot)

        \(skillBlock.isEmpty ? "" : skillBlock + "\n")
        可用调度工具：
        - list_employees：查看全部员工 id / 姓名 / 简介
        - delegate_to_employee：把任务交给某位员工（其自有模型与人设）；可在一轮中并行派给最多 3 人
        - crm_stats：客户库统计（总数/国家/阶段/星级/来源；与「客户管理」同源 leads-index.total）
        - system_overview：客户/员工/任务/项目/deliverables 总览
        - crm.search_customers：模糊搜索（company/country/product/notes）；看 matchTotal；计数用 countOnly=true，禁止翻页扫全库
        - semantic_search_customers：语义+关键词混合搜客户（自然语言优先）

        数据原则（必须遵守）：
        1. 问「有多少客户/员工/任务」等：先看上方实时快照数字；不够再调 crm_stats / system_overview。绝不调用 search 翻页凑数。
        2. 找客户优先 semantic_search_customers；筛选/分布优先 crm_stats；关键词 search 看 matchTotal，禁止翻页扫库。
        3. 委派前先想清楚该谁做；不确定就 list_employees 或向用户确认。
        4. 委派时写清可执行的 task；收回结果后用中文汇总给用户。
        5. 浏览器操作、发邮件、对外发帖等必须交给 Grok Bot App 里的「大可可」处理，本工作台员工只做内容/分析/草稿，不要假装已经上网或发信。
        6. 每条用户消息最多 6 轮工具往返；完成后必须给出最终文字回答，不要只调工具不说话。
        """
    }

    @MainActor
    static func globalSystemPrompt(store: WorkspaceStore, skillBlock: String, snapshot: String) -> String {
        return """
        你是超级工作台的全局助手（非调度模式）。直接用工作台工具回答用户，不要委派员工。

        工作台快照：
        \(snapshot)

        \(skillBlock.isEmpty ? "" : skillBlock + "\n")
        数据工具：
        - crm_stats / system_overview：先看统计与总数（与「客户管理」同源 leads-index.total）
        - semantic_search_customers：自然语言语义+关键词搜客户（优先）
        - crm.search_customers：模糊关键词；看 matchTotal；countOnly 只计数
        - context.get_snapshot / nav.* / task.* 等系统工具

        原则：
        1. 问数量先用快照或 crm_stats / system_overview，禁止翻页扫库。
        2. 找客户优先 semantic_search_customers，其次 crm_stats / search。
        3. 不要调用 list_employees / delegate_to_employee（本模式不可用）。
        4. 浏览器/发信/发帖提醒用户去 Grok Bot App；本助手只做本地分析与草稿。
        5. 每条消息最多 6 轮工具；最终必须用中文文字回答。
        """
    }

    @MainActor
    static func prepareEmployee(botId: String, store: WorkspaceStore) -> PreparedEmployee? {
        guard let bot = store.bot(id: botId) else { return nil }
        let prefsSkills = EmployeeChatStore.loadPrefs(botId: botId).defaultSkillIds
        let skillIds: [String]
        if prefsSkills.isEmpty {
            let blob = (bot.skills + " " + bot.tools).lowercased()
            skillIds = AgentSkillCatalog.allOptions(repoRoot: store.repoRoot)
                .map(\.value)
                .filter { blob.contains($0.lowercased()) }
        } else {
            skillIds = prefsSkills
        }
        let skillBlock = AgentSkillCatalog.systemContext(selectedIds: skillIds, repoRoot: store.repoRoot)
        let system = EmployeeChatStore.buildSystemPrompt(bot: bot, repoRoot: store.repoRoot, skillBlock: skillBlock)
        let resolved = EmployeeChatStore.resolveModel(botId: botId, repoRoot: store.repoRoot)
        let key = SharedModelStore.loadKey(providerId: resolved.providerId)
            ?? AgentKeychain.loadKey()
            ?? ""
        guard !key.isEmpty else { return nil }
        guard !resolved.baseURL.isEmpty, !resolved.model.isEmpty else { return nil }
        return PreparedEmployee(
            botId: bot.id,
            botName: bot.name,
            systemPrompt: system,
            baseURL: resolved.baseURL,
            model: resolved.model,
            apiKey: key
        )
    }

    /// Run employee LLM off the hot path (Sendable inputs). Does not touch WorkspaceStore.
    static func runEmployeeLLM(
        prepared: PreparedEmployee,
        task: String,
        llm: AgentLLMClient
    ) async -> (ok: Bool, output: String, ms: Int) {
        let t0 = Date()
        let cfg = AgentLLMClient.Config(baseURL: prepared.baseURL, model: prepared.model, apiKey: prepared.apiKey)
        let apiMessages: [[String: Any]] = [
            ["role": "system", "content": prepared.systemPrompt],
            ["role": "user", "content": task]
        ]
        do {
            let result = try await llm.streamChat(config: cfg, messages: apiMessages, tools: []) { _ in }
            let text = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            if text.isEmpty {
                return (false, "（员工未返回文本）", ms)
            }
            return (true, text, ms)
        } catch {
            let ms = Int(Date().timeIntervalSince(t0) * 1000)
            return (false, "调用失败：\(error.localizedDescription)", ms)
        }
    }

    @MainActor
    static func persistDelegation(
        botId: String,
        botName: String,
        task: String,
        output: String,
        ok: Bool,
        ms: Int
    ) -> DelegationResult {
        let sessionURL = EmployeeChatStore.createSessionFile(botId: botId)
        let userMsg = AgentChatMessage(role: .user, content: "[总调度委派] \(task)")
        let assistantMsg = AgentChatMessage(role: .assistant, content: output)
        EmployeeChatStore.appendMessage(userMsg, to: sessionURL)
        EmployeeChatStore.appendMessage(assistantMsg, to: sessionURL)
        let summary = makeShortSummary(botName: botName, task: task, output: output, ok: ok)
        EmployeeChatStore.appendSummary(
            botId: botId,
            sessionFileName: sessionURL.lastPathComponent,
            summary: summary
        )
        EmployeeChatStore.append(
            line: .init(
                ts: EmployeeChatStore.isoNow(),
                role: "meta",
                content: summary,
                toolName: nil,
                toolArgsSummary: nil,
                ok: ok,
                ms: ms,
                event: "session_end:chief_delegate"
            ),
            to: sessionURL
        )
        return DelegationResult(
            botId: botId,
            botName: botName,
            task: task,
            ok: ok,
            output: output,
            summary: summary,
            ms: ms,
            sessionFileName: sessionURL.lastPathComponent
        )
    }

    static func delegationToolContent(_ r: DelegationResult) -> String {
        let payload: [String: Any] = [
            "botId": r.botId,
            "botName": r.botName,
            "task": r.task,
            "status": r.ok ? "完成" : "失败",
            "ok": r.ok,
            "output": r.output,
            "summary": r.summary,
            "session": r.sessionFileName,
            "ms": r.ms
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let s = String(data: data, encoding: .utf8) else {
            return r.output
        }
        return s
    }

    static func makeShortSummary(botName: String, task: String, output: String, ok: Bool) -> String {
        let status = ok ? "完成" : "失败"
        let clipped = output.count > 120 ? String(output.prefix(120)) + "…" : output
        return "【总调度委派】\(botName) · \(status)\n任务：\(task)\n结果：\(clipped)"
    }
}
