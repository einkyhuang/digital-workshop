import Foundation

/// P0 executor: L0 nav/snapshot only. Shared names with actions.schema.json.
@MainActor
final class AgentExecutor {
    weak var store: WorkspaceStore?

    func execute(name: String, params: [String: Any]) -> AgentStepEvent {
        let t0 = Date()
        let summary = Self.summarize(params)
        let result: (Bool, String)
        switch name {
        case "context.get_snapshot":
            let scope = (params["scope"] as? String) ?? "brief"
            result = (true, snapshot(scope: scope))
        case "nav.open_section":
            if let sid = params["sectionId"] as? String,
               let section = SidebarSection.fromModuleId(sid)
                ?? SidebarSection.allCases.first(where: { $0.navTitle == sid || $0.rawValue == sid }) {
                store?.selectedSection = section
                if section == .dailySummary { store?.refreshDailyReportDates() }
                if section == .scheduleCenter { store?.loadScheduleMonth(around: store?.calendarMonth ?? Date()) }
                result = (true, "opened \(section.navTitle)")
            } else {
                result = (false, "unknown sectionId")
            }
        case "nav.switch_workbench":
            if let wid = params["workbenchId"] as? String {
                store?.switchWorkbench(wid)
                result = (true, "workbench=\(wid)")
            } else {
                result = (false, "missing workbenchId")
            }
        case "schedule.open_day":
            if let date = params["date"] as? String {
                store?.openScheduleDay(date)
                result = (true, "schedule \(date)")
            } else {
                result = (false, "missing date")
            }
        case "daily.open_report":
            if let date = params["date"] as? String {
                store?.selectedSection = .dailySummary
                store?.selectedDailyReportDate = date
                store?.loadDailyReport(date: date)
                result = (true, "daily \(date)")
            } else {
                result = (false, "missing date")
            }
        default:
            result = (false, "P0 未实现或未知动作: \(name)")
        }
        let ms = Int(Date().timeIntervalSince(t0) * 1000)
        return AgentStepEvent(name: name, argsSummary: summary, ok: result.0, detail: result.1, ms: ms)
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
