import Foundation

/// Chinese labels + one-line summaries for Codex-style tool rows.
enum AgentToolPresentation {
    static func chineseName(_ tool: String) -> String {
        switch tool {
        case "crm.search_customers": return "搜索客户"
        case "crm.open_customer": return "打开客户"
        case "crm.add_followup": return "添加跟进"
        case "crm.draft_quote": return "报价草稿"
        case "crm.send_email": return "发送邮件"
        case "context.get_snapshot": return "读取工作台快照"
        case "nav.open_section": return "打开模块"
        case "nav.switch_workbench": return "切换工作台"
        case "task.create": return "创建任务"
        case "task.set_status": return "更新任务状态"
        case "task.delete": return "删除任务"
        case "schedule.open_day": return "打开日程"
        case "daily.open_report": return "打开日报"
        case "agent.undo_last": return "撤销上一步"
        case "external.publish": return "外发发布"
        default:
            if tool.hasPrefix("crm.") { return "客户工具" }
            if tool.hasPrefix("nav.") { return "导航" }
            if tool.hasPrefix("task.") { return "任务" }
            return tool
        }
    }

    static func iconName(_ tool: String) -> String {
        switch tool {
        case "crm.search_customers": return "magnifyingglass"
        case "crm.open_customer": return "person.crop.circle"
        case "crm.add_followup": return "text.bubble"
        case "crm.draft_quote": return "doc.text"
        case "crm.send_email": return "envelope"
        case "context.get_snapshot": return "rectangle.dashed.and.paperclip"
        case "nav.open_section", "nav.switch_workbench": return "sidebar.left"
        case "task.create", "task.set_status", "task.delete": return "checklist"
        case "agent.undo_last": return "arrow.uturn.backward"
        default: return "wrench.and.screwdriver"
        }
    }

    /// Compact Chinese summary, e.g. 「搜索客户「照明」· 0 条」.
    static func summary(tool: String, detail: String, argsSummary: String?) -> String {
        let json = parseJSON(detail)
        let name = chineseName(tool)
        switch tool {
        case "crm.search_customers":
            let q = stringValue(json["query"]) ?? extractArg(argsSummary, key: "query") ?? ""
            let count = intValue(json["count"]) ?? 0
            if q.isEmpty { return "\(name) · \(count) 条" }
            return "\(name)「\(q)」· \(count) 条"
        case "context.get_snapshot":
            return "\(name) · 已获取"
        case "nav.open_section":
            let s = stringValue(json["sectionId"]) ?? extractArg(argsSummary, key: "sectionId") ?? argsSummary ?? ""
            return s.isEmpty ? name : "\(name) · \(s)"
        case "nav.switch_workbench":
            let s = stringValue(json["workbenchId"]) ?? extractArg(argsSummary, key: "workbenchId") ?? ""
            return s.isEmpty ? name : "\(name) · \(s)"
        case "task.create":
            let t = stringValue(json["title"]) ?? extractArg(argsSummary, key: "title") ?? ""
            return t.isEmpty ? name : "\(name)「\(t)」"
        default:
            if let note = stringValue(json["note"]), !note.isEmpty {
                let c = intValue(json["count"])
                if let c { return "\(name) · \(c) 条" }
                return "\(name) · \(note.prefix(24))"
            }
            if let argsSummary, !argsSummary.isEmpty {
                let short = argsSummary.count > 40 ? String(argsSummary.prefix(38)) + "…" : argsSummary
                return "\(name) · \(short)"
            }
            let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return name }
            if trimmed.count > 48 { return "\(name) · \(trimmed.prefix(46))…" }
            return "\(name) · \(trimmed)"
        }
    }

    static func prettyJSON(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(obj),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let s = String(data: pretty, encoding: .utf8) else {
            return raw
        }
        return s
    }

    /// True when a CRM-style search returned zero hits (used to stop empty retry loops).
    static func isEmptySearchResult(tool: String, detail: String) -> Bool {
        guard tool == "crm.search_customers" else { return false }
        let json = parseJSON(detail)
        if let c = intValue(json["count"]) { return c == 0 }
        if let arr = json["results"] as? [Any] { return arr.isEmpty }
        return detail.contains("\"count\": 0") || detail.contains("\"count\":0")
    }

    static func fallbackAnswer(fromToolMessages tools: [AgentChatMessage], userText: String) -> String {
        guard !tools.isEmpty else {
            return "本轮未得到可用结果。请换个说法再试，或检查模型与 API Key。"
        }
        var lines: [String] = ["根据本轮工具调用："]
        for t in tools.suffix(8) {
            let name = t.toolName ?? "tool"
            lines.append("• " + summary(tool: name, detail: t.content, argsSummary: t.toolArgsSummary))
        }
        let emptySearches = tools.filter { AgentToolPresentation.isEmptySearchResult(tool: $0.toolName ?? "", detail: $0.content) }
        if !emptySearches.isEmpty {
            lines.append("客户搜索未命中。可换更短的关键词（品牌/国家/人名），或到「客户管理」里核对本地 CRM 数据。")
        } else {
            lines.append("如需我继续处理，请补充具体目标。")
        }
        if !userText.isEmpty {
            lines.insert("针对「\(userText.prefix(40))」：", at: 0)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - JSON helpers (no Equatable on [String: Any])

    private static func parseJSON(_ raw: String) -> [String: Any] {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return obj
    }

    private static func stringValue(_ any: Any?) -> String? {
        if let s = any as? String { return s }
        if let n = any as? NSNumber { return n.stringValue }
        return nil
    }

    private static func intValue(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let n = any as? NSNumber { return n.intValue }
        if let s = any as? String, let i = Int(s) { return i }
        return nil
    }

    private static func extractArg(_ summary: String?, key: String) -> String? {
        guard let summary, !summary.isEmpty else { return nil }
        // argsSummary often like "query=照明, limit=20"
        for part in summary.split(separator: ",") {
            let p = part.trimmingCharacters(in: .whitespaces)
            if p.hasPrefix(key + "=") {
                return String(p.dropFirst(key.count + 1))
            }
        }
        return nil
    }
}
