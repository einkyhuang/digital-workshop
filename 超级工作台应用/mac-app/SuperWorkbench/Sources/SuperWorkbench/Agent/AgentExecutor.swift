import Foundation

enum AgentRisk: String {
    case L0, L1, L2, L3
    static func of(_ name: String) -> AgentRisk {
        switch name {
        case "task.delete", "crm.create_quote": return .L2
        case "crm.send_email", "external.publish": return .L3
        case "task.create", "task.update", "task.set_status", "agent.undo_last", "crm.upsert_followup": return .L1
        case "list_employees", "delegate_to_employee", "crm_stats", "system_overview",
             "crm.search_customers", "semantic_search_customers", "crm.open_customer", "context.get_snapshot",
             "nav.open_section", "nav.switch_workbench", "schedule.open_day", "daily.open_report":
            return .L0
        default: return .L0
        }
    }
}

/// P0/P1 executor. Shared names with actions.schema.json.
@MainActor
final class AgentExecutor {
    weak var store: WorkspaceStore?
    var audit: AgentAuditLog?
    /// When set, L2+ actions pause for user confirm.
    var confirmHandler: ((String, String, [String: Any]) async -> Bool)?

    func execute(name: String, params: [String: Any], skipConfirm: Bool = false) async -> AgentStepEvent {
        let risk = AgentRisk.of(name)
        if !skipConfirm, risk == .L2 || risk == .L3 {
            let summary = Self.summarize(params)
            let recap: String
            if risk == .L3 {
                recap = "【L3 外发/不可逆 — 请核对】\n" + summary + "\n确认后仍不会真发外网，仅记录拦截结果。"
            } else {
                recap = "【L2 需确认】\n" + summary
            }
            let okConfirm = await (confirmHandler?(name, recap, params) ?? false)
            if !okConfirm {
                return AgentStepEvent(name: name, argsSummary: summary, ok: false, detail: "用户取消", ms: 0)
            }
        }
        let t0 = Date()
        let summary = Self.summarize(params)
        let before = taskSnapshotJSON()
        let result = await perform(name: name, params: params)
        let ms = Int(Date().timeIntervalSince(t0) * 1000)
        let after = taskSnapshotJSON()
        let undoable = ["task.create", "task.update", "task.set_status", "task.delete", "crm.upsert_followup", "crm.create_quote"].contains(name) && result.0
        let entry = AgentAuditEntry(
            id: UUID(), at: Date(), action: name, paramsSummary: summary,
            ok: result.0, detail: String(result.1.prefix(500)), undoable: undoable,
            beforeJSON: before, afterJSON: after
        )
        audit?.record(entry)
        return AgentStepEvent(name: name, argsSummary: summary, ok: result.0, detail: result.1, ms: ms)
    }

    private func perform(name: String, params: [String: Any]) async -> (Bool, String) {
        switch name {
        case "context.get_snapshot":
            return (true, snapshot(scope: (params["scope"] as? String) ?? "brief"))
        case "nav.open_section":
            if let sid = params["sectionId"] as? String,
               let section = SidebarSection.fromModuleId(sid)
                ?? SidebarSection.allCases.first(where: { $0.navTitle == sid || $0.rawValue == sid }) {
                store?.selectedSection = section
                if section == .dailySummary { store?.refreshDailyReportDates() }
                if section == .scheduleCenter { store?.loadScheduleMonth(around: store?.calendarMonth ?? Date()) }
                return (true, "opened \(section.navTitle)")
            }
            return (false, "unknown sectionId")
        case "nav.switch_workbench":
            if let wid = params["workbenchId"] as? String {
                store?.switchWorkbench(wid)
                return (true, "workbench=\(wid)")
            }
            return (false, "missing workbenchId")
        case "schedule.open_day":
            if let date = params["date"] as? String {
                store?.openScheduleDay(date)
                return (true, "schedule \(date)")
            }
            return (false, "missing date")
        case "daily.open_report":
            if let date = params["date"] as? String {
                store?.selectedSection = .dailySummary
                store?.selectedDailyReportDate = date
                store?.loadDailyReport(date: date)
                return (true, "daily \(date)")
            }
            return (false, "missing date")
        case "task.create":
            guard let title = params["title"] as? String, !title.isEmpty else { return (false, "missing title") }
            let note = params["note"] as? String ?? ""
            let executor = params["executor"] as? String ?? (store?.data.bots.first?.name ?? "")
            let reviewer = params["reviewer"] as? String ?? "最强大脑"
            store?.addTask(title: title, note: note, executor: executor, reviewer: reviewer)
            if let st = params["status"] as? String, let id = store?.data.tasks.last?.id {
                store?.setTaskStatus(id: id, status: st)
            }
            return (true, "created \(title)")
        case "task.update":
            guard let id = params["id"] as? String, var task = store?.data.tasks.first(where: { $0.id == id }) else {
                return (false, "task not found")
            }
            if let title = params["title"] as? String { task.title = title }
            if let note = params["note"] as? String { task.note = note }
            if let executor = params["executor"] as? String { task.executor = executor }
            if let reviewer = params["reviewer"] as? String { task.reviewer = reviewer }
            store?.updateTask(task)
            return (true, "updated \(id)")
        case "task.set_status":
            guard let id = params["id"] as? String, let status = params["status"] as? String else {
                return (false, "missing id/status")
            }
            store?.setTaskStatus(id: id, status: status)
            return (true, "status \(id)=\(status)")
        case "task.delete":
            guard let id = params["id"] as? String else { return (false, "missing id") }
            store?.deleteTask(id)
            return (true, "deleted \(id)")
        case "agent.undo_last":
            return undoLast()
        case "crm_stats":
            guard let store else { return (false, "no store") }
            let topN = params["topN"] as? Int ?? 8
            return AgentCRM.crmStats(repoRoot: store.repoRoot, topN: topN)
        case "system_overview":
            guard let store else { return (false, "no store") }
            let projects = (store.data.websiteProjects ?? []).count
            return AgentCRM.systemOverview(
                repoRoot: store.repoRoot,
                storeBots: store.data.bots.count,
                storeTasks: store.data.tasks.count,
                storeProjects: projects
            )
        case "crm.search_customers":
            guard let store else { return (false, "no store") }
            let query = params["query"] as? String ?? ""
            let page = params["page"] as? Int ?? 0
            let limit = params["limit"] as? Int ?? 30
            let countOnly: Bool = {
                if let b = params["countOnly"] as? Bool { return b }
                if let n = params["countOnly"] as? NSNumber { return n.boolValue }
                return false
            }()
            return AgentCRM.searchCustomers(
                repoRoot: store.repoRoot,
                query: query,
                page: page,
                limit: limit,
                countOnly: countOnly
            )
        case "crm.open_customer":
            guard let store, let id = params["customerId"] as? String else { return (false, "missing customerId") }
            return AgentCRM.openCustomer(store: store, customerId: id)
        case "crm.upsert_followup":
            guard let store,
                  let id = params["customerId"] as? String,
                  let note = params["note"] as? String else { return (false, "missing customerId/note") }
            return AgentCRM.upsertFollowup(repoRoot: store.repoRoot, customerId: id, note: note)
        case "crm.create_quote":
            guard let store else { return (false, "no store") }
            return AgentCRM.createQuoteDraft(repoRoot: store.repoRoot, params: params)
        case "crm.send_email":
            return AgentCRM.blockedSendEmail(params: params)
        case "external.publish":
            return AgentCRM.blockedPublish(params: params)
        default:
            return (false, "未实现或未知动作: \(name)")
        }
    }

    private func undoLast() -> (Bool, String) {
        guard let store, let entry = audit?.popUndo(), let before = entry.beforeJSON,
              let data = before.data(using: .utf8),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return (false, "无可撤销项")
        }
        // Restore task fields from before snapshot for matching ids when possible
        for item in arr {
            guard let id = item["id"], var task = store.data.tasks.first(where: { $0.id == id }) else { continue }
            if let title = item["title"] { task.title = title }
            if let note = item["note"] { task.note = note }
            if let status = item["status"] { task.status = status }
            if let executor = item["executor"] { task.executor = executor }
            if let reviewer = item["reviewer"] { task.reviewer = reviewer }
            store.updateTask(task)
        }
        // If create-undo: delete task that appears only in after
        if entry.action == "task.create", let after = entry.afterJSON,
           let adata = after.data(using: .utf8),
           let aarr = try? JSONSerialization.jsonObject(with: adata) as? [[String: String]] {
            let beforeIds = Set(arr.compactMap { $0["id"] })
            for item in aarr {
                if let id = item["id"], !beforeIds.contains(id) {
                    store.deleteTask(id)
                }
            }
        }
        if entry.action == "task.delete", let beforeItem = arr.first, let id = beforeItem["id"] {
            // re-add best-effort
            store.addTask(
                title: beforeItem["title"] ?? "恢复任务",
                note: beforeItem["note"] ?? "",
                executor: beforeItem["executor"] ?? "",
                reviewer: beforeItem["reviewer"] ?? "最强大脑"
            )
            if let st = beforeItem["status"], let newId = store.data.tasks.last?.id {
                store.setTaskStatus(id: newId, status: st)
            }
            _ = id
        }
        return (true, "undid \(entry.action)")
    }

    private func taskSnapshotJSON() -> String {
        guard let store else { return "[]" }
        let arr: [[String: String]] = store.data.tasks.map {
            ["id": $0.id, "title": $0.title, "note": $0.note, "status": $0.status,
             "executor": $0.executor, "reviewer": $0.reviewer]
        }
        if let data = try? JSONSerialization.data(withJSONObject: arr), let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "[]"
    }

    private func snapshot(scope: String) -> String {
        guard let store else { return "{}" }
        let wb = store.activeWorkbench
        let limit = scope == "full" ? 40 : 12
        let tasks: [[String: String]] = store.scopedTasks.prefix(limit).map { t in
            ["id": t.id, "title": t.title, "status": t.status]
        }
        let payload: [String: Any] = [
            "activeWorkbenchId": store.activeWorkbenchId,
            "workbenchName": wb?.name ?? "",
            "section": store.selectedSection.moduleId,
            "sectionTitle": store.selectedSection.navTitle,
            "bots": store.scopedBots.count,
            "tasksOpen": store.scopedTasks.filter { ["待办", "进行中", "验收"].contains($0.status) }.count,
            "tasks": tasks,
            "workbenches": store.workbenches.map { ["id": $0.id, "name": $0.name] as [String: String] }
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "{}"
    }

    private static func summarize(_ params: [String: Any]) -> String {
        let s = params.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return s.count > 120 ? String(s.prefix(117)) + "…" : s
    }
}
