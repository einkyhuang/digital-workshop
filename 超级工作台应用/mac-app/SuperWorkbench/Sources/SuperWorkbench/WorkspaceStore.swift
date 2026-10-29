import Foundation
import SwiftUI
import AppKit

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published var data: WorkspaceData = WorkspaceData(
        version: 2, updatedAt: nil, timezone: "Asia/Shanghai",
        bots: [], tasks: [], vacancies: [], groups: [], routines: [], rules: [], groupsOrder: nil, projects: nil, websiteProjects: nil, smartplanSync: nil
    )
    @Published var selectedSection: SidebarSection = .overview
    @Published var selectedBotId: String?
    @Published var selectedTaskId: String?
    @Published var searchText: String = ""
    @Published var syncMessage: String = ""
    @Published var isSyncing: Bool = false
    @Published var loadError: String?
    @Published var commandText: String = ""
    @Published var showingBotDetail: Bool = false
    @Published var emailDaily: [OverviewMetrics.EmailDaily] = []
    @Published var targetsFile: OverviewMetrics.TargetsFile? = nil
    @Published var smartPlanTasks: [OverviewMetrics.SmartPlanTask] = []
    @Published var expandedEmailDate: String? = nil
    /// First paint ready (workspace.json applied). Auxiliaries may still be loading.
    @Published var isCoreLoaded: Bool = false
    /// Calendar / daily-summary navigation
    @Published var calendarMonth: Date = Date()
    @Published var selectedCalendarDate: String? = nil  // YYYY-MM-DD
    @Published var scheduleByDate: [String: ScheduleDayDoc] = [:]
    @Published var isScheduleLoading: Bool = false
    @Published var dailyReportDates: [String] = []
    @Published var selectedDailyReportDate: String? = nil
    @Published var dailyReportMarkdown: String? = nil
    @Published var isDailyReportLoading: Bool = false
    /// Multi-workbench
    @Published var workbenches: [WorkbenchConfig] = []
    @Published var activeWorkbenchId: String = "general"
    @Published var tradeLeadsIndex: TradeLeadsIndex? = nil
    @Published var crmLeadsTotal: Int? = nil


    @Published private(set) var botById: [String: Bot] = [:]
    @Published private(set) var botsByGroup: [String: [Bot]] = [:]
    private var cachedWebsiteKPI: OverviewMetrics.KPI?
    private var cachedKPIProjectsToken: Int = 0


    /// Repo root: iCloud/超级工作台 (git clone)
    var repoRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/超级工作台")
    }

    var dataFileURL: URL {
        repoRoot
            .appendingPathComponent("超级工作台应用/data/workspace.json")
    }

    /// Full websiteProjects (client/amounts/localPath). Gitignored — local only.
    var privateWebsiteProjectsURL: URL {
        repoRoot
            .appendingPathComponent("超级工作台应用/data/private/websiteProjects.local.json")
    }

    var botsRootURL: URL {
        repoRoot.appendingPathComponent("bots")
    }

    /// Synchronous reload (menu / after sync). Prefer `loadAsync()` at launch.
    func load() {
        loadAsync(showBlockingError: true)
    }

    /// Non-blocking launch path: core JSON first (first screen), then auxiliaries + optional stress fixture.
    func loadAsync(showBlockingError: Bool = false) {
        let url = resolveDataURL()
        let privateURL = privateWebsiteProjectsURL
        let targetsURL = repoRoot.appendingPathComponent("超级工作台应用/data/private/targets.local.json")
        let emailDir = repoRoot.appendingPathComponent("bots/外贸营销/超级邮件助手/deliverables/email-daily")
        let emailAgg = repoRoot.appendingPathComponent("超级工作台应用/data/email-daily.json")
        let dbURL = repoRoot.appendingPathComponent("智能日程管理/server/smart_plan.db")
        let stressURL = Self.stressFixtureURL()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                guard FileManager.default.fileExists(atPath: url.path) else {
                    throw NSError(domain: "SW", code: 1, userInfo: [NSLocalizedDescriptionKey: "找不到数据文件：\(url.path)"])
                }
                let raw = try Data(contentsOf: url)
                var decoded = try JSONDecoder().decode(WorkspaceData.self, from: raw)
                if let full = Self.readPrivateWebsiteProjects(at: privateURL) {
                    decoded.websiteProjects = full
                }
                if let stressURL, let overlay = Self.readStressOverlay(at: stressURL) {
                    decoded = Self.mergeStress(decoded, overlay: overlay)
                }
                DispatchQueue.main.async {
                    self.applyCore(decoded)
                }
                let targets = Self.readTargets(at: targetsURL)
                let emails = Self.readEmailDaily(dir: emailDir, agg: emailAgg)
                let smart = Self.readSmartPlanTasks(db: dbURL)
                DispatchQueue.main.async {
                    self.targetsFile = targets
                    self.emailDaily = emails
                    if self.expandedEmailDate == nil { self.expandedEmailDate = emails.first?.date }
                    self.smartPlanTasks = smart
                    self.cachedWebsiteKPI = nil
                }
            } catch {
                DispatchQueue.main.async {
                    if showBlockingError || self.data.bots.isEmpty {
                        self.loadError = "读取失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }

    /// Prefer UserDefaults SWStressFixture / env SW_STRESS_FIXTURE (local /tmp only — never committed).
    private func resolveDataURL() -> URL {
        if let stress = Self.stressFixtureURL(), FileManager.default.fileExists(atPath: stress.path) {
            // Stress fixture is an overlay merged onto workspace; still load real workspace as base.
        }
        return dataFileURL
    }

    private static func stressFixtureURL() -> URL? {
        if let s = UserDefaults.standard.string(forKey: "SWStressFixture"), !s.isEmpty {
            return URL(fileURLWithPath: s)
        }
        if let s = ProcessInfo.processInfo.environment["SW_STRESS_FIXTURE"], !s.isEmpty {
            return URL(fileURLWithPath: s)
        }
        // Local opt-in: touch /tmp/sw-enable-stress (fixture lives only under /tmp)
        let enable = "/tmp/sw-enable-stress"
        let fixture = "/tmp/sw-stress-workspace.json"
        if FileManager.default.fileExists(atPath: enable),
           FileManager.default.fileExists(atPath: fixture) {
            return URL(fileURLWithPath: fixture)
        }
        return nil
    }

    private nonisolated static func readStressOverlay(at url: URL) -> WorkspaceData? {
        guard let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WorkspaceData.self, from: raw)
    }

    private nonisolated static func mergeStress(_ base: WorkspaceData, overlay: WorkspaceData) -> WorkspaceData {
        var out = base
        if !overlay.bots.isEmpty { out.bots = overlay.bots }
        if let wp = overlay.websiteProjects, !wp.isEmpty { out.websiteProjects = wp }
        if let go = overlay.groupsOrder, !go.isEmpty { out.groupsOrder = go }
        return out
    }

    private func applyCore(_ decoded: WorkspaceData) {
        data = decoded
        if selectedBotId == nil { selectedBotId = decoded.bots.first?.id }
        if selectedTaskId == nil { selectedTaskId = decoded.tasks.first?.id }
        rebuildIndexes()
        isCoreLoaded = true
        loadWorkbenches()
        loadError = nil
        cachedWebsiteKPI = nil
        if decoded.bots.contains(where: { $0.id.hasPrefix("stress-bot") }) {
            syncMessage = "压测夹具：\(decoded.bots.count) 员工 · \((decoded.websiteProjects ?? []).count) 网站项目（本地 /tmp，未入库）"
        }
    }

    func rebuildIndexes() {
        var byId: [String: Bot] = [:]
        byId.reserveCapacity(data.bots.count)
        var byGroup: [String: [Bot]] = [:]
        for b in data.bots {
            byId[b.id] = b
            for g in b.displayGroups {
                byGroup[g, default: []].append(b)
            }
        }
        botById = byId
        botsByGroup = byGroup
    }

    func bots(inGroup name: String) -> [Bot] {
        if let hit = botsByGroup[name] { return hit }
        return data.bots.filter { $0.belongs(to: name) }
    }

    func groupedBots(order: [String], from bots: [Bot]? = nil) -> [(title: String, bots: [Bot])] {
        let source = bots ?? filteredBots
        if bots == nil, searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return order.compactMap { g in
                let items = botsByGroup[g] ?? []
                return items.isEmpty ? nil : (title: g, bots: items)
            }
        }
        return order.compactMap { g in
            let items = source.filter { $0.belongs(to: g) }
            return items.isEmpty ? nil : (title: g, bots: items)
        }
    }

    private nonisolated static func readPrivateWebsiteProjects(at url: URL) -> [WebsiteProject]? {
        guard FileManager.default.fileExists(atPath: url.path),
              let raw = try? Data(contentsOf: url) else { return nil }
        struct Doc: Codable {
            var projects: [WebsiteProject]
        }
        if let doc = try? JSONDecoder().decode(Doc.self, from: raw) { return doc.projects }
        return try? JSONDecoder().decode([WebsiteProject].self, from: raw)
    }

    private nonisolated static func readTargets(at url: URL) -> OverviewMetrics.TargetsFile? {
        guard let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(OverviewMetrics.TargetsFile.self, from: raw)
    }

    private nonisolated static func readEmailDaily(dir: URL, agg: URL) -> [OverviewMetrics.EmailDaily] {
        let fm = FileManager.default
        var items: [OverviewMetrics.EmailDaily] = []
        if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for u in files where u.pathExtension == "json" {
                if let raw = try? Data(contentsOf: u),
                   let doc = try? JSONDecoder().decode(OverviewMetrics.EmailDaily.self, from: raw) {
                    items.append(doc)
                }
            }
        }
        if items.isEmpty {
            if let raw = try? Data(contentsOf: agg),
               let obj = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
               let arr = obj["items"] as? [[String: Any]],
               let data = try? JSONSerialization.data(withJSONObject: arr),
               let decoded = try? JSONDecoder().decode([OverviewMetrics.EmailDaily].self, from: data) {
                items = decoded
            }
        }
        return items.sorted { $0.date > $1.date }
    }

    private nonisolated static func readSmartPlanTasks(db: URL) -> [OverviewMetrics.SmartPlanTask] {
        var remote: [OverviewMetrics.SmartPlanTask] = []
        guard FileManager.default.fileExists(atPath: db.path) else { return remote }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        proc.arguments = ["-json", db.path, "SELECT id,title,status,priority,due_date FROM tasks WHERE status != 'archived' ORDER BY updated_at DESC LIMIT 200;"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do {
            try proc.run()
            // Cap wait so a wedged iCloud/sqlite cannot hang forever
            let deadline = Date().addingTimeInterval(4)
            while proc.isRunning, Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }
            if proc.isRunning { proc.terminate() }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for row in arr {
                    let id = row["id"] as? String ?? UUID().uuidString
                    let title = row["title"] as? String ?? ""
                    let st = OverviewMetrics.mapSmartStatus(row["status"] as? String ?? "todo")
                    remote.append(.init(
                        id: "sp-" + id,
                        title: title,
                        status: st,
                        priority: row["priority"] as? String,
                        dueDate: row["due_date"] as? String,
                        source: "smartplan"
                    ))
                }
            }
        } catch { /* ignore */ }
        return remote
    }

    func save() {
        data.updatedAt = ISO8601DateFormatter().string(from: Date())
        // Snapshot on main; encode + disk write off main thread (no UI block)
        let snapshot = data
        let privateProjects = data.websiteProjects ?? []
        let dataURL = dataFileURL
        let webCopy = repoRoot.appendingPathComponent("超级工作台应用/app/data/workspace.json")
        let privateURL = repoRoot.appendingPathComponent("超级工作台应用/data/private/websiteProjects.local.json")
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                let enc = JSONEncoder()
                enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                // private full projects
                if let priv = try? enc.encode(privateProjects) {
                    try? FileManager.default.createDirectory(at: privateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try? priv.write(to: privateURL, options: .atomic)
                }
                var publicData = snapshot
                publicData.websiteProjects = self?.redactWebsiteProjects(privateProjects) ?? []
                let raw = try enc.encode(publicData)
                try raw.write(to: dataURL, options: .atomic)
                try? FileManager.default.createDirectory(at: webCopy.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? raw.write(to: webCopy, options: .atomic)
                DispatchQueue.main.async { self?.loadError = nil }
            } catch {
                DispatchQueue.main.async {
                    self?.loadError = "保存失败：\(error.localizedDescription)"
                }
            }
        }
    }

    /// Drag-and-drop: set status directly (any column ↔ any column)
    func setTaskStatus(id: String, status: String) {
        guard let i = data.tasks.firstIndex(where: { $0.id == id }) else { return }
        guard TaskColumn(rawValue: status) != nil else { return }
        if data.tasks[i].status == status { return }
        data.tasks[i].status = status
        save()
    }


    // MARK: - Overview auxiliaries (targets / email / SmartPlan tasks)

    func loadTargets() {
        // 金算盘：私有 targets.local.json（gitignore）
        let url = repoRoot.appendingPathComponent("超级工作台应用/data/private/targets.local.json")
        guard let raw = try? Data(contentsOf: url),
              let doc = try? JSONDecoder().decode(OverviewMetrics.TargetsFile.self, from: raw) else {
            targetsFile = nil
            return
        }
        targetsFile = doc
    }

    func loadEmailDaily() {
        let dir = repoRoot.appendingPathComponent("bots/外贸营销/超级邮件助手/deliverables/email-daily")
        let fm = FileManager.default
        var items: [OverviewMetrics.EmailDaily] = []
        if let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for u in files where u.pathExtension == "json" {
                if let raw = try? Data(contentsOf: u),
                   let doc = try? JSONDecoder().decode(OverviewMetrics.EmailDaily.self, from: raw) {
                    items.append(doc)
                }
            }
        }
        // fallback aggregated file
        if items.isEmpty {
            let agg = repoRoot.appendingPathComponent("超级工作台应用/data/email-daily.json")
            if let raw = try? Data(contentsOf: agg),
               let obj = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
               let arr = obj["items"] as? [[String: Any]] {
                let data = try? JSONSerialization.data(withJSONObject: arr)
                if let data, let decoded = try? JSONDecoder().decode([OverviewMetrics.EmailDaily].self, from: data) {
                    items = decoded
                }
            }
        }
        emailDaily = items.sorted { $0.date > $1.date }
        if expandedEmailDate == nil { expandedEmailDate = emailDaily.first?.date }
    }

    func loadSmartPlanTasks() {
        let db = repoRoot.appendingPathComponent("智能日程管理/server/smart_plan.db")
        var remote: [OverviewMetrics.SmartPlanTask] = []
        if FileManager.default.fileExists(atPath: db.path) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
            proc.arguments = ["-json", db.path, "SELECT id,title,status,priority,due_date FROM tasks WHERE status != 'archived' ORDER BY updated_at DESC LIMIT 200;"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = Pipe()
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    for row in arr {
                        let id = row["id"] as? String ?? UUID().uuidString
                        let title = row["title"] as? String ?? ""
                        let st = OverviewMetrics.mapSmartStatus(row["status"] as? String ?? "todo")
                        remote.append(.init(
                            id: "sp-" + id,
                            title: title,
                            status: st,
                            priority: row["priority"] as? String,
                            dueDate: row["due_date"] as? String,
                            source: "smartplan"
                        ))
                    }
                }
            } catch { /* ignore */ }
        }
        smartPlanTasks = remote
    }

    /// Merged read-only board: workspace tasks + SmartPlan (dedupe by title+status soft)
    func overviewBoardTasks() -> [OverviewMetrics.SmartPlanTask] {
        var out: [OverviewMetrics.SmartPlanTask] = []
        var seen = Set<String>()
        for t in data.tasks {
            let key = t.id
            seen.insert(key)
            out.append(.init(id: t.id, title: t.title, status: t.status, priority: nil, dueDate: nil, source: "workspace"))
        }
        for t in smartPlanTasks {
            let soft = t.title + "|" + t.status
            if seen.contains(t.id) { continue }
            // skip near-dup titles already in workspace
            if out.contains(where: { $0.title == t.title }) { continue }
            seen.insert(t.id)
            _ = soft
            out.append(t)
        }
        return out
    }

    func websiteKPI() -> OverviewMetrics.KPI {
        let token = (data.websiteProjects?.count ?? 0) &+ (targetsFile?.websiteProjects?.yearly?.year ?? 0)
        if let cached = cachedWebsiteKPI, cachedKPIProjectsToken == token { return cached }
        let kpi = OverviewMetrics.compute(projects: data.websiteProjects ?? [], targets: targetsFile)
        cachedWebsiteKPI = kpi
        cachedKPIProjectsToken = token
        return kpi
    }

    // MARK: - Website project privacy (local full / public redacted)

    private struct PrivateWebsiteDoc: Codable {
        var version: Int?
        var updatedAt: String?
        var aliases: [String: String]?
        var projects: [WebsiteProject]
    }

    private func loadPrivateWebsiteProjects() -> [WebsiteProject]? {
        let url = privateWebsiteProjectsURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let raw = try? Data(contentsOf: url) else { return nil }
        if let doc = try? JSONDecoder().decode(PrivateWebsiteDoc.self, from: raw) {
            return doc.projects
        }
        // fallback: bare array
        return try? JSONDecoder().decode([WebsiteProject].self, from: raw)
    }

    private func loadAliases() -> [String: String] {
        let url = privateWebsiteProjectsURL
        guard FileManager.default.fileExists(atPath: url.path),
              let raw = try? Data(contentsOf: url),
              let doc = try? JSONDecoder().decode(PrivateWebsiteDoc.self, from: raw) else { return [:] }
        return doc.aliases ?? [:]
    }

    private func savePrivateWebsiteProjects(_ projects: [WebsiteProject]) throws {
        var aliases = loadAliases()
        var maxN = 0
        for a in aliases.values {
            if a.hasPrefix("客户A"), let n = Int(a.dropFirst(3)) { maxN = max(maxN, n) }
        }
        for p in projects where aliases[p.id] == nil {
            let hasClient = !(p.clientName ?? "").isEmpty || !(p.clientCompany ?? "").isEmpty || !(p.localPath ?? "").isEmpty || (p.totalAmount ?? 0) > 0
            if hasClient {
                maxN += 1
                aliases[p.id] = String(format: "客户A%02d", maxN)
            }
        }
        let doc = PrivateWebsiteDoc(
            version: 1,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            aliases: aliases,
            projects: projects
        )
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let raw = try enc.encode(doc)
        let url = privateWebsiteProjectsURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try raw.write(to: url, options: .atomic)
        // local web overlay
        let appPriv = repoRoot.appendingPathComponent("超级工作台应用/app/data/private/websiteProjects.local.json")
        try? FileManager.default.createDirectory(at: appPriv.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? raw.write(to: appPriv, options: .atomic)
    }

    private func redactWebsiteProjects(_ projects: [WebsiteProject]) -> [WebsiteProject] {
        let aliases = loadAliases()
        return projects.map { p in
            var r = p
            let hasClient = !(p.clientName ?? "").isEmpty || !(p.clientCompany ?? "").isEmpty || aliases[p.id] != nil
            if hasClient {
                r.clientName = aliases[p.id] ?? "已隐藏"
            } else {
                r.clientName = ""
            }
            if let cc = p.clientCompany, !cc.isEmpty { r.clientCompany = "已隐藏" } else { r.clientCompany = "" }
            r.localPath = ""
            r.totalAmount = nil
            r.depositAmount = nil
            r.paidAmount = nil
            r.unpaidAmount = nil
            return r
        }
    }

    func bot(id: String?) -> Bot? {
        guard let id else { return nil }
        if let hit = botById[id] { return hit }
        return data.bots.first { $0.id == id }
    }

    func updateBot(_ bot: Bot) {
        guard let i = data.bots.firstIndex(where: { $0.id == bot.id }) else { return }
        data.bots[i] = bot
        rebuildIndexes()
        save()
    }

    func updateTask(_ task: WorkbenchTask) {
        guard let i = data.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        if task.executor == task.reviewer {
            syncMessage = "执行人与验收人不能相同"
            return
        }
        data.tasks[i] = task
        save()
    }

    func moveTask(_ id: String, direction: Int) {
        guard let i = data.tasks.firstIndex(where: { $0.id == id }) else { return }
        let cols = TaskColumn.allCases.map(\.rawValue)
        guard let ci = cols.firstIndex(of: data.tasks[i].status) else { return }
        let ni = ci + direction
        guard cols.indices.contains(ni) else { return }
        data.tasks[i].status = cols[ni]
        save()
    }

    func addTask(title: String, note: String, executor: String, reviewer: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard executor != reviewer else {
            syncMessage = "执行人与验收人必须不同"
            return
        }
        let t = WorkbenchTask(
            id: "t-\(Int(Date().timeIntervalSince1970))",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            status: TaskColumn.todo.rawValue,
            note: note.isEmpty ? "—" : note,
            executor: executor,
            reviewer: reviewer
        )
        data.tasks.append(t)
        selectedTaskId = t.id
        save()
    }

    func deleteTask(_ id: String) {
        data.tasks.removeAll { $0.id == id }
        if selectedTaskId == id { selectedTaskId = data.tasks.first?.id }
        save()
    }

    func confirmHire(_ id: String) {
        guard let i = data.vacancies.firstIndex(where: { $0.id == id }) else { return }
        data.vacancies[i].confirmed = true
        save()
        syncMessage = "已标记确认招聘（未真正创建 Bot）"
    }

    func listBotFiles(_ bot: Bot) -> [URL] {
        let root = botsRootURL.appendingPathComponent(bot.folderName)
        var urls: [URL] = []
        let subs = ["deliverables", "files", "notes", "memory"]
        let fm = FileManager.default
        for sub in subs {
            let dir = root.appendingPathComponent(sub)
            guard let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { continue }
            for u in items {
                let name = u.lastPathComponent
                if name == ".gitkeep" { continue }
                urls.append(u)
            }
        }
        return urls.sorted { $0.path < $1.path }
    }

    func projectAbsoluteURL(_ project: WorkbenchProject) -> URL {
        repoRoot.appendingPathComponent(project.localPath)
    }

    func revealProject(_ project: WorkbenchProject) {
        NSWorkspace.shared.activateFileViewerSelecting([projectAbsoluteURL(project)])
    }

    func openProjectURL(_ project: WorkbenchProject) {
        if let s = project.run?.url, let u = URL(string: s) {
            NSWorkspace.shared.open(u)
        }
    }

    func revealBotFolder(_ bot: Bot) {
        let url = botsRootURL.appendingPathComponent(bot.folderName)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func syncGit() {
        isSyncing = true
        syncMessage = "同步中…"
        let root = repoRoot.path
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let script = """
            cd "$1" || exit 1
            # 1) SmartPlan 网站项目导入（再可选写回）
            if [ -f "超级工作台应用/scripts/sync-smartplan.mjs" ]; then
              node "超级工作台应用/scripts/sync-smartplan.mjs" --push 2>&1 || node "超级工作台应用/scripts/sync-smartplan.mjs" 2>&1 || echo "smartplan sync skipped"
            fi
            if [ -f "超级工作台应用/scripts/sync-email-daily.mjs" ]; then
              node "超级工作台应用/scripts/sync-email-daily.mjs" 2>&1 || true
            fi
            # sync data copies
            mkdir -p "超级工作台应用/app/data"
            cp -f "超级工作台应用/data/workspace.json" "超级工作台应用/app/data/workspace.json" 2>/dev/null || true
            git pull --rebase --autostash 2>&1
            git add -A
            # never stage private PII
            git reset -q -- "超级工作台应用/data/private" "超级工作台应用/app/data/private" 2>/dev/null || true
            node "超级工作台应用/scripts/check-website-privacy.mjs" --staged || exit 1
            if ! git diff --cached --quiet; then
              git commit -m "sync: $(date '+%Y-%m-%d %H:%M')" 2>&1
            else
              echo "无本地改动需要提交"
            fi
            git push 2>&1
            echo "SYNC_OK"
            """
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/bash")
            proc.arguments = ["-c", script, "--", root]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe
            do {
                try proc.run()
                proc.waitUntilExit()
                let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let ok = proc.terminationStatus == 0
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    self?.syncMessage = ok ? "同步成功\n" + out.suffix(400) : "同步失败（\(proc.terminationStatus)）\n" + out.suffix(400)
                    self?.load()
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    self?.syncMessage = "同步异常：\(error.localizedDescription)"
                }
            }
        }
    }


    func saveWebsiteProjects(_ items: [WebsiteProject]) {
        data.websiteProjects = items
        cachedWebsiteKPI = nil
        save()
    }

    func upsertWebsiteProject(_ item: WebsiteProject) {
        var list = data.websiteProjects ?? []
        if let i = list.firstIndex(where: { $0.id == item.id }) {
            list[i] = item
        } else {
            list.insert(item, at: 0)
        }
        data.websiteProjects = list
        cachedWebsiteKPI = nil
        save()
    }

    func markWebsiteDirty(_ id: String, mutate: (inout WebsiteProject) -> Void) {
        var list = data.websiteProjects ?? []
        guard let i = list.firstIndex(where: { $0.id == id }) else { return }
        mutate(&list[i])
        list[i].dirty = true
        data.websiteProjects = list
        save()
    }

    var filteredBots: [Bot] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return data.bots }
        return data.bots.filter {
            $0.name.lowercased().contains(q) || $0.role.lowercased().contains(q) || $0.layer.lowercased().contains(q)
        }
    }

    var filteredTasks: [WorkbenchTask] {
        let base = scopedTasks
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || $0.note.localizedCaseInsensitiveContains(q)
                || $0.executor.localizedCaseInsensitiveContains(q)
                || $0.reviewer.localizedCaseInsensitiveContains(q)
        }
    }


    // MARK: - Multi-workbench

    var activeWorkbench: WorkbenchConfig? {
        workbenches.first { $0.id == activeWorkbenchId } ?? workbenches.first
    }

    var activeModules: [SidebarSection] {
        let ids = activeWorkbench?.modules ?? SidebarSection.allCases.map(\.moduleId)
        return ids.compactMap { SidebarSection.fromModuleId($0) }
    }

    var activeModuleGroups: [(String, [SidebarSection])] {
        var order: [String] = []
        var map: [String: [SidebarSection]] = [:]
        for s in activeModules {
            if map[s.group] == nil { order.append(s.group) }
            map[s.group, default: []].append(s)
        }
        return order.map { ($0, map[$0]!) }
    }

    /// Bots visible in current workbench (by group / groups[])
    var scopedBots: [Bot] {
        guard let wb = activeWorkbench, let groups = wb.botGroupIds, !groups.isEmpty else {
            return data.bots
        }
        let set = Set(groups)
        return data.bots.filter { b in
            if let g = b.group, set.contains(g) { return true }
            if let gs = b.groups, gs.contains(where: { set.contains($0) }) { return true }
            return false
        }
    }

    var scopedBotsByGroup: [String: [Bot]] {
        let bots = scopedBots
        var map: [String: [Bot]] = [:]
        for b in bots {
            let g = b.group ?? "未分组"
            map[g, default: []].append(b)
        }
        return map
    }

    var scopedBotNames: Set<String> {
        Set(scopedBots.map(\.name))
    }

    /// Tasks whose executor/reviewer intersects scoped bots; general = all
    var scopedTasks: [WorkbenchTask] {
        guard let wb = activeWorkbench, let groups = wb.botGroupIds, !groups.isEmpty else {
            return data.tasks
        }
        let names = scopedBotNames
        let ids = Set(scopedBots.map(\.id))
        return data.tasks.filter { t in
            if names.contains(t.executor) || names.contains(t.reviewer) { return true }
            // soft match folder nicknames in executor string
            return scopedBots.contains { t.executor.contains($0.name) || t.reviewer.contains($0.name) }
                || ids.contains(where: { t.executor.contains($0) })
        }
    }

    func loadWorkbenches() {
        let url = repoRoot.appendingPathComponent("超级工作台应用/data/workbenches.json")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var list: [WorkbenchConfig] = []
            var defaultId = "general"
            if let raw = try? Data(contentsOf: url),
               let doc = try? JSONDecoder().decode(WorkbenchesFile.self, from: raw) {
                list = doc.workbenches
                if let d = doc.defaultId { defaultId = d }
            }
            if list.isEmpty {
                list = [
                    WorkbenchConfig(id: "general", name: "超级工作台（综合）", shortName: "综合", icon: "square.grid.2x2", description: nil, botGroupIds: nil, modules: SidebarSection.allCases.map(\.moduleId), data: nil, summaryHints: nil)
                ]
            }
            let saved = UserDefaults.standard.string(forKey: "sw.activeWorkbenchId")
            let active = list.contains(where: { $0.id == saved }) ? (saved ?? defaultId) : defaultId
            // trade index (public counts)
            var idx: TradeLeadsIndex? = nil
            let idxURL = self.repoRoot.appendingPathComponent("超级工作台应用/data/trade-leads-index.json")
            if let raw = try? Data(contentsOf: idxURL) {
                idx = try? JSONDecoder().decode(TradeLeadsIndex.self, from: raw)
            }
            DispatchQueue.main.async {
                self.workbenches = list
                self.activeWorkbenchId = active
                self.loadCrmPublicIndex()
                if UserDefaults.standard.string(forKey: "sw.forceSection") == "crmCustomers" {
                    self.selectedSection = .crmCustomers
                }
                self.tradeLeadsIndex = idx
                // keep selection valid for modules
                if !self.activeModules.contains(self.selectedSection) {
                    self.selectedSection = self.activeModules.first ?? .overview
                }
            }
        }
    }


    func loadCrmPublicIndex() {
        let priv = repoRoot.appendingPathComponent("超级工作台应用/data/private/crm/leads/leads-index.json")
        let pub = repoRoot.appendingPathComponent("超级工作台应用/data/crm/leads-index.json")
        let url = FileManager.default.fileExists(atPath: priv.path) ? priv : pub
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let total = obj["total"] as? Int else { return }
        DispatchQueue.main.async { self.crmLeadsTotal = total }
    }

    func switchWorkbench(_ id: String) {
        guard workbenches.contains(where: { $0.id == id }) else { return }
        activeWorkbenchId = id
        UserDefaults.standard.set(id, forKey: "sw.activeWorkbenchId")
        if !activeModules.contains(selectedSection) {
            selectedSection = activeModules.first ?? .overview
        }
        showingBotDetail = false
    }

    func workbenchSummary(for wb: WorkbenchConfig) -> (bots: Int, tasksOpen: Int, activity: String) {
        let bots: [Bot]
        if let g = wb.botGroupIds, !g.isEmpty {
            let set = Set(g)
            bots = data.bots.filter { b in
                if let gg = b.group, set.contains(gg) { return true }
                return b.groups?.contains(where: { set.contains($0) }) ?? false
            }
        } else {
            bots = data.bots
        }
        let names = Set(bots.map(\.name))
        let scoped: [WorkbenchTask]
        if wb.botGroupIds == nil || wb.botGroupIds?.isEmpty == true {
            scoped = data.tasks
        } else {
            scoped = data.tasks.filter { t in
                names.contains(t.executor) || names.contains(t.reviewer)
                    || bots.contains { t.executor.contains($0.name) || t.reviewer.contains($0.name) }
            }
        }
        let openStatuses: Set<String> = ["待办", "进行中", "验收"]
        let open = scoped.filter { openStatuses.contains($0.status) }.count
        var activity = "—"
        if wb.id == "trade", let a = tradeLeadsIndex?.latestActivity, !a.isEmpty {
            activity = a
        } else if let t = scoped.first {
            activity = t.title
        }
        return (bots.count, open, activity)
    }

    // MARK: - Schedule month + daily reports (lazy)

    var scheduleDirURL: URL {
        repoRoot.appendingPathComponent("超级工作台应用/data/schedule")
    }

    var dailyReportDirURL: URL {
        repoRoot.appendingPathComponent("bots/管理中枢/总结助手/deliverables")
    }

    var emailDailyDirURL: URL {
        repoRoot.appendingPathComponent("bots/外贸营销/超级邮件助手/deliverables/email-daily")
    }

    static func ymd(_ date: Date, tz: String = "Asia/Shanghai") -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: tz) ?? .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func monthPrefix(_ date: Date, tz: String = "Asia/Shanghai") -> String {
        String(ymd(date, tz: tz).prefix(7)) // YYYY-MM
    }

    func loadScheduleMonth(around date: Date = Date()) {
        calendarMonth = date
        let prefix = Self.monthPrefix(date)
        let dir = scheduleDirURL
        isScheduleLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var map: [String: ScheduleDayDoc] = [:]
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for u in files where u.pathExtension == "json" {
                    let name = u.deletingPathExtension().lastPathComponent
                    guard name.hasPrefix(prefix), name.count == 10 else { continue }
                    if let raw = try? Data(contentsOf: u),
                       let doc = try? JSONDecoder().decode(ScheduleDayDoc.self, from: raw) {
                        map[doc.date] = doc
                    }
                }
            }
            // Also fold workspace tasks without due into "today" markers lightly — skip
            // Enrich meta flags from email-daily filenames + daily report filenames
            let emailDir = self.emailDailyDirURL
            let reportDir = self.dailyReportDirURL
            if let emails = try? FileManager.default.contentsOfDirectory(at: emailDir, includingPropertiesForKeys: nil) {
                for u in emails where u.pathExtension == "json" {
                    let d = u.deletingPathExtension().lastPathComponent
                    guard d.hasPrefix(prefix) else { continue }
                    var doc = map[d] ?? ScheduleDayDoc(version: 1, date: d, timezone: "Asia/Shanghai", updatedAt: nil, tasks: [], schedule: [], meta: .init(hasEmailSummary: true, hasDailyReport: false, emailSource: nil, dailyReportSource: nil))
                    var meta = doc.meta ?? ScheduleDayMeta(hasEmailSummary: true, hasDailyReport: false, emailSource: nil, dailyReportSource: nil)
                    meta.hasEmailSummary = true
                    doc.meta = meta
                    map[d] = doc
                }
            }
            if let reps = try? FileManager.default.contentsOfDirectory(at: reportDir, includingPropertiesForKeys: nil) {
                for u in reps where u.lastPathComponent.hasPrefix("日报-") && u.pathExtension == "md" {
                    let d = u.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "日报-", with: "")
                    guard d.hasPrefix(prefix) else { continue }
                    var doc = map[d] ?? ScheduleDayDoc(version: 1, date: d, timezone: "Asia/Shanghai", updatedAt: nil, tasks: [], schedule: [], meta: .init(hasEmailSummary: false, hasDailyReport: true, emailSource: nil, dailyReportSource: nil))
                    var meta = doc.meta ?? ScheduleDayMeta(hasEmailSummary: false, hasDailyReport: true, emailSource: nil, dailyReportSource: nil)
                    meta.hasDailyReport = true
                    doc.meta = meta
                    map[d] = doc
                }
            }
            DispatchQueue.main.async {
                self.scheduleByDate = map
                self.isScheduleLoading = false
            }
        }
    }

    func scheduleDay(for ymd: String) -> ScheduleDayDoc? { scheduleByDate[ymd] }

    func emailSummary(for ymd: String) -> OverviewMetrics.EmailDaily? {
        if let hit = emailDaily.first(where: { $0.date == ymd }) { return hit }
        // On-demand read from bot deliverable (private content — local only)
        let url = emailDailyDirURL.appendingPathComponent("\(ymd).json")
        guard let raw = try? Data(contentsOf: url),
              let doc = try? JSONDecoder().decode(OverviewMetrics.EmailDaily.self, from: raw) else { return nil }
        return doc
    }

    func refreshDailyReportDates() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var dates: [String] = []
            if let files = try? FileManager.default.contentsOfDirectory(at: self.dailyReportDirURL, includingPropertiesForKeys: nil) {
                for u in files where u.pathExtension == "md" && u.lastPathComponent.hasPrefix("日报-") {
                    let d = u.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "日报-", with: "")
                    if d.count == 10 { dates.append(d) }
                }
            }
            dates.sort(by: >)
            DispatchQueue.main.async {
                self.dailyReportDates = dates
                if self.selectedDailyReportDate == nil { self.selectedDailyReportDate = dates.first }
            }
        }
    }

    func loadDailyReport(date ymd: String) {
        selectedDailyReportDate = ymd
        isDailyReportLoading = true
        dailyReportMarkdown = nil
        let url = dailyReportDirURL.appendingPathComponent("日报-\(ymd).md")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let text = try? String(contentsOf: url, encoding: .utf8)
            DispatchQueue.main.async {
                self?.dailyReportMarkdown = text
                self?.isDailyReportLoading = false
            }
        }
    }

    func openDailySummary(date ymd: String) {
        selectedSection = .dailySummary
        selectedDailyReportDate = ymd
        loadDailyReport(date: ymd)
    }

    func openScheduleDay(_ ymd: String) {
        selectedSection = .scheduleCenter
        selectedCalendarDate = ymd
    }

}
