import Foundation
import SwiftUI
import AppKit

@MainActor
final class WorkspaceStore: ObservableObject {
    @Published var data: WorkspaceData = WorkspaceData(
        version: 2, updatedAt: nil, timezone: "Asia/Shanghai",
        bots: [], tasks: [], vacancies: [], groups: [], routines: [], rules: [], groupsOrder: nil
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

    /// Repo root: iCloud/超级工作台 (git clone)
    var repoRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/超级工作台")
    }

    var dataFileURL: URL {
        repoRoot
            .appendingPathComponent("超级工作台应用/data/workspace.json")
    }

    var botsRootURL: URL {
        repoRoot.appendingPathComponent("bots")
    }

    func load() {
        do {
            let url = dataFileURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                loadError = "找不到数据文件：\(url.path)"
                return
            }
            let raw = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(WorkspaceData.self, from: raw)
            data = decoded
            if selectedBotId == nil { selectedBotId = decoded.bots.first?.id }
            if selectedTaskId == nil { selectedTaskId = decoded.tasks.first?.id }
            loadError = nil
        } catch {
            loadError = "读取失败：\(error.localizedDescription)"
        }
    }

    func save() {
        do {
            data.updatedAt = ISO8601DateFormatter().string(from: Date())
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let raw = try enc.encode(data)
            try raw.write(to: dataFileURL, options: .atomic)
            // Keep app/data copy in sync for the static web app
            let webCopy = repoRoot.appendingPathComponent("超级工作台应用/app/data/workspace.json")
            try? FileManager.default.createDirectory(at: webCopy.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? raw.write(to: webCopy, options: .atomic)
            loadError = nil
        } catch {
            loadError = "保存失败：\(error.localizedDescription)"
        }
    }

    func bot(id: String?) -> Bot? {
        data.bots.first { $0.id == id }
    }

    func updateBot(_ bot: Bot) {
        guard let i = data.bots.firstIndex(where: { $0.id == bot.id }) else { return }
        data.bots[i] = bot
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
            # sync data copies
            mkdir -p "超级工作台应用/app/data"
            cp -f "超级工作台应用/data/workspace.json" "超级工作台应用/app/data/workspace.json" 2>/dev/null || true
            git pull --rebase --autostash 2>&1
            git add -A
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
