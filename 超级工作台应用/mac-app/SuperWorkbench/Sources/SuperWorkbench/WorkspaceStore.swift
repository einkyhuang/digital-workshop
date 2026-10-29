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
        do {
            data.updatedAt = ISO8601DateFormatter().string(from: Date())
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            // 1) Write full websiteProjects to private local file
            try savePrivateWebsiteProjects(data.websiteProjects ?? [])
            // 2) Write redacted copy to tracked workspace.json (+ app copy)
            var publicData = data
            publicData.websiteProjects = redactWebsiteProjects(data.websiteProjects ?? [])
            let raw = try enc.encode(publicData)
            try raw.write(to: dataFileURL, options: .atomic)
            let webCopy = repoRoot.appendingPathComponent("超级工作台应用/app/data/workspace.json")
            try? FileManager.default.createDirectory(at: webCopy.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? raw.write(to: webCopy, options: .atomic)
            loadError = nil
        } catch {
            loadError = "保存失败：\(error.localizedDescription)"
        }
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
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return data.tasks }
        return data.tasks.filter {
            $0.title.lowercased().contains(q) || $0.executor.lowercased().contains(q) || $0.note.lowercased().contains(q)
        }
    }
}
