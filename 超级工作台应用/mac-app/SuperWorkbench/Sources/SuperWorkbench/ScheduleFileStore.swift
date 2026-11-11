import Foundation

/// 读写 `超级工作台应用/data/schedule/YYYY-MM-DD.json`。
/// 规则与 `app/assets/schedule-board.mjs` 一致：只改命中任务的 status 和顶层 updatedAt。
enum ScheduleFileStore {
    static let pastDays = 14
    static let futureDays = 120

    struct BoardEntry: Equatable {
        var date: String
        var id: String
        var title: String
        var status: String
        var owner: String
    }

    enum FileError: LocalizedError {
        case badDate
        case badTaskId
        case missingFile
        case badJSON
        case missingTask
        case writeFailed(String)

        var errorDescription: String? {
            switch self {
            case .badDate: return "日期不合法"
            case .badTaskId: return "任务 id 不合法"
            case .missingFile: return "找不到当日日程文件"
            case .badJSON: return "日程文件不是合法 JSON"
            case .missingTask: return "文件里没有这条任务"
            case .writeFailed(let msg): return msg
            }
        }
    }

    static func isDayKey(_ value: String) -> Bool {
        value.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
    }

    static func dayKeyFromName(_ name: String) -> String? {
        guard let match = name.range(of: #"^(\d{4}-\d{2}-\d{2})\.json$"#, options: .regularExpression) else { return nil }
        let base = String(name[match])
        return String(base.dropLast(5))
    }

    static func shanghaiYMD(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Shanghai")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static func shanghaiStamp(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Shanghai")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return f.string(from: date)
    }

    static func addDays(_ ymd: String, _ delta: Int) -> String? {
        guard isDayKey(ymd) else { return nil }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        let parts = ymd.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        var comp = DateComponents()
        comp.year = y
        comp.month = m
        comp.day = d
        comp.hour = 12
        guard let date = cal.date(from: comp),
              let next = cal.date(byAdding: .day, value: delta, to: date) else { return nil }
        return shanghaiYMD(next)
    }

    static func belongsOnHomeBoard(fileDate: String, status: String, today: String) -> Bool {
        guard isDayKey(fileDate), isDayKey(today) else { return false }
        if let end = addDays(today, futureDays), fileDate >= today, fileDate <= end { return true }
        if status != "完成", let start = addDays(today, -pastDays), fileDate >= start, fileDate < today { return true }
        return false
    }

    static func homeBoardEntries(docs: [String: ScheduleDayDoc], today: String) -> [BoardEntry] {
        var out: [BoardEntry] = []
        for (key, doc) in docs {
            let fileDate = isDayKey(doc.date) ? doc.date : key
            guard isDayKey(fileDate) else { continue }
            for t in doc.tasks ?? [] {
                let status = (t.status?.isEmpty == false) ? (t.status ?? "待办") : "待办"
                guard belongsOnHomeBoard(fileDate: fileDate, status: status, today: today) else { continue }
                guard !t.id.isEmpty, !t.title.isEmpty else { continue }
                out.append(BoardEntry(
                    date: fileDate,
                    id: t.id,
                    title: t.title,
                    status: status,
                    owner: t.ownerName ?? t.ownerBotId ?? ""
                ))
            }
        }
        out.sort { a, b in
            if a.date != b.date { return a.date < b.date }
            return a.title < b.title
        }
        return out
    }

    static func loadDayDocs(directory: URL) -> [String: ScheduleDayDoc] {
        var map: [String: ScheduleDayDoc] = [:]
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return map
        }
        let decoder = JSONDecoder()
        for url in files {
            guard let key = dayKeyFromName(url.lastPathComponent),
                  let data = try? Data(contentsOf: url),
                  let doc = try? decoder.decode(ScheduleDayDoc.self, from: data) else { continue }
            map[isDayKey(doc.date) ? doc.date : key] = doc
        }
        return map
    }

    static func listRawDocs(directory: URL) -> [[String: Any]] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        var out: [[String: Any]] = []
        for url in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard let key = dayKeyFromName(url.lastPathComponent),
                  let data = try? Data(contentsOf: url),
                  var obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            if !isDayKey(obj["date"] as? String ?? "") {
                obj["date"] = key
            }
            out.append(obj)
        }
        return out
    }

    @discardableResult
    static func setTaskDone(
        directory: URL,
        date: String,
        taskId: String,
        done: Bool,
        now: Date = Date(),
        mirrorDirectory: URL? = nil
    ) throws -> [String: Any] {
        let file = try dayFileURL(directory: directory, date: date, taskId: taskId)
        guard FileManager.default.fileExists(atPath: file.path) else { throw FileError.missingFile }
        let updated = try mutate(file: file, taskId: taskId, done: done, now: now)
        if let mirrorDirectory {
            let mirror = mirrorDirectory.appendingPathComponent("\(date).json")
            if mirror.standardizedFileURL.path != file.standardizedFileURL.path,
               FileManager.default.fileExists(atPath: mirror.path) {
                _ = try? mutate(file: mirror, taskId: taskId, done: done, now: now)
            }
        }
        return updated
    }

    private static func dayFileURL(directory: URL, date: String, taskId: String) throws -> URL {
        guard isDayKey(date) else { throw FileError.badDate }
        guard isSafeTaskId(taskId) else { throw FileError.badTaskId }
        let root = directory.standardizedFileURL.resolvingSymlinksInPath()
        let file = root.appendingPathComponent("\(date).json").standardizedFileURL
        let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        guard file.path.hasPrefix(prefix) else { throw FileError.badDate }
        return file
    }

    private static func isSafeTaskId(_ taskId: String) -> Bool {
        !taskId.isEmpty && taskId.count <= 200 && !taskId.contains("/") && !taskId.contains("\\") && !taskId.contains("..")
    }

    private static func mutate(file: URL, taskId: String, done: Bool, now: Date) throws -> [String: Any] {
        var result: [String: Any]?
        var failure: Error?
        let coord = NSFileCoordinator(filePresenter: nil)
        var coordError: NSError?
        coord.coordinate(writingItemAt: file, options: [], error: &coordError) { url in
            do {
                result = try writePatched(url: url, taskId: taskId, done: done, now: now)
            } catch {
                failure = error
            }
        }
        if let result { return result }
        if let failure { throw failure }
        if coordError != nil {
            return try writePatched(url: file, taskId: taskId, done: done, now: now)
        }
        throw FileError.writeFailed("无法锁定日程文件")
    }

    private static func writePatched(url: URL, taskId: String, done: Bool, now: Date) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        guard var root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FileError.badJSON
        }
        guard let rawTasks = root["tasks"] as? [Any] else { throw FileError.missingTask }
        var next: [Any] = []
        var hit = 0
        for item in rawTasks {
            guard var task = item as? [String: Any] else {
                next.append(item)
                continue
            }
            if (task["id"] as? String) == taskId {
                task["status"] = done ? "完成" : "待办"
                hit += 1
            }
            next.append(task)
        }
        guard hit > 0 else { throw FileError.missingTask }
        root["tasks"] = next
        root["updatedAt"] = shanghaiStamp(now)
        let out = try JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .withoutEscapingSlashes]
        )
        var text = String(data: out, encoding: .utf8) ?? ""
        if !text.hasSuffix("\n") { text.append("\n") }
        try Data(text.utf8).write(to: url, options: .atomic)
        return root
    }
}

extension MagicHubBridge {
    func scheduleListDocs() -> (Bool, Any?, String?) {
        let dir = repoRoot.appendingPathComponent("超级工作台应用/data/schedule")
        return (true, ["success": true, "docs": ScheduleFileStore.listRawDocs(directory: dir)], nil)
    }

    func scheduleSetStatus(args: [Any]) -> (Bool, Any?, String?) {
        guard args.count >= 3,
              let date = args[0] as? String,
              let taskId = args[1] as? String else {
            return (false, ["success": false, "error": "参数不完整"], "bad args")
        }
        let done: Bool = {
            if let b = args[2] as? Bool { return b }
            if let n = args[2] as? NSNumber { return n.boolValue }
            return false
        }()
        let dir = repoRoot.appendingPathComponent("超级工作台应用/data/schedule")
        let mirror = repoRoot.appendingPathComponent("超级工作台应用/app/data/schedule")
        do {
            let doc = try ScheduleFileStore.setTaskDone(
                directory: dir,
                date: date,
                taskId: taskId,
                done: done,
                mirrorDirectory: mirror
            )
            return (true, ["success": true, "doc": doc], nil)
        } catch {
            let msg = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return (false, ["success": false, "error": msg], msg)
        }
    }
}
