import Foundation

/// Private, non-git storage for per-employee chats and work summaries.
/// Root: ~/Library/Application Support/超级工作台/conversations/<botId>/
///
/// Mapping: workspace.json `bots[].id` → directory name `<botId>/`.
/// Persona / SKILL files still live under repo `bots/<Bot.folderName>/` (read-only for chat).
enum EmployeeChatStore {
    static let rootFolderName = "conversations"
    static let summaryFileName = "工作摘要.md"
    static let prefsFileName = "prefs.json"
    static let sessionsFolderName = "sessions"

    struct Prefs: Codable, Equatable {
        var providerId: String = ""
        var model: String = ""
        var defaultSkillIds: [String] = []
        var updatedAt: String = ""
    }

    struct SessionLine: Codable {
        var ts: String
        var role: String
        var content: String
        var toolName: String?
        var toolArgsSummary: String?
        var ok: Bool?
        var ms: Int?
        var event: String?
    }

    static var conversationsRoot: URL {
        SharedModelStore.supportDir.appendingPathComponent(rootFolderName, isDirectory: true)
    }

    static func botDir(botId: String) -> URL {
        conversationsRoot.appendingPathComponent(sanitize(botId), isDirectory: true)
    }

    static func sessionsDir(botId: String) -> URL {
        botDir(botId: botId).appendingPathComponent(sessionsFolderName, isDirectory: true)
    }

    static func summaryURL(botId: String) -> URL {
        botDir(botId: botId).appendingPathComponent(summaryFileName)
    }

    static func prefsURL(botId: String) -> URL {
        botDir(botId: botId).appendingPathComponent(prefsFileName)
    }

    @discardableResult
    static func ensureDirs(botId: String) -> URL {
        let sessions = sessionsDir(botId: botId)
        try? FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)
        return sessions
    }

    static func loadPrefs(botId: String) -> Prefs {
        let url = prefsURL(botId: botId)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let prefs = try? JSONDecoder().decode(Prefs.self, from: data) else {
            return Prefs()
        }
        return prefs
    }

    @discardableResult
    static func savePrefs(_ prefs: Prefs, botId: String) -> Bool {
        ensureDirs(botId: botId)
        var p = prefs
        p.updatedAt = isoNow()
        guard let data = try? JSONEncoder().encode(p) else { return false }
        do {
            try data.write(to: prefsURL(botId: botId), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Create a new session file `YYYY-MM-DD-HHMM.jsonl` and return its URL.
    static func createSessionFile(botId: String, at date: Date = Date()) -> URL {
        ensureDirs(botId: botId)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd-HHmm"
        var name = df.string(from: date) + ".jsonl"
        var url = sessionsDir(botId: botId).appendingPathComponent(name)
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            name = df.string(from: date) + "-\(n).jsonl"
            url = sessionsDir(botId: botId).appendingPathComponent(name)
            n += 1
            if n > 50 { break }
        }
        FileManager.default.createFile(atPath: url.path, contents: Data(), attributes: nil)
        return url
    }

    static func append(line: SessionLine, to sessionURL: URL) {
        guard let data = try? JSONEncoder().encode(line),
              var str = String(data: data, encoding: .utf8) else { return }
        str += "\n"
        guard let bytes = str.data(using: .utf8) else { return }
        if !FileManager.default.fileExists(atPath: sessionURL.path) {
            FileManager.default.createFile(atPath: sessionURL.path, contents: bytes, attributes: nil)
            return
        }
        guard let handle = try? FileHandle(forWritingTo: sessionURL) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: bytes)
    }

    static func appendMessage(_ msg: AgentChatMessage, to sessionURL: URL) {
        let line = SessionLine(
            ts: isoNow(),
            role: msg.role.rawValue,
            content: msg.content,
            toolName: msg.toolName,
            toolArgsSummary: msg.toolArgsSummary,
            ok: msg.ok,
            ms: msg.ms,
            event: nil
        )
        append(line: line, to: sessionURL)
    }

    static func loadSummaryMarkdown(botId: String) -> String {
        let url = summaryURL(botId: botId)
        guard FileManager.default.fileExists(atPath: url.path),
              let s = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return s
    }

    static func appendSummary(botId: String, sessionFileName: String, summary: String, at date: Date = Date()) {
        ensureDirs(botId: botId)
        let url = summaryURL(botId: botId)
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd HH:mm"
        let stamp = df.string(from: date)
        let block = """

        ## \(stamp) · \(sessionFileName)
        \(summary.trimmingCharacters(in: .whitespacesAndNewlines))

        """
        if !FileManager.default.fileExists(atPath: url.path) {
            let header = "# 工作摘要\n\n> 由超级工作台员工对话自动生成；原文在 sessions/*.jsonl（不进 git）。\n"
            try? (header + block).write(to: url, atomically: true, encoding: .utf8)
            return
        }
        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            if let data = block.data(using: .utf8) {
                try? handle.write(contentsOf: data)
            }
        }
    }

    static func listSessionFiles(botId: String) -> [URL] {
        let dir = sessionsDir(botId: botId)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return files.filter { $0.pathExtension == "jsonl" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    /// Load persona from repo bots/<folder>/persona.md (fallback profile.md).
    static func loadPersonaMarkdown(bot: Bot, repoRoot: URL) -> String {
        let folder = bot.folderName
        let candidates = [
            repoRoot.appendingPathComponent("bots").appendingPathComponent(folder).appendingPathComponent("persona.md"),
            repoRoot.appendingPathComponent("bots").appendingPathComponent(folder).appendingPathComponent("profile.md")
        ]
        for u in candidates {
            if let s = try? String(contentsOf: u, encoding: .utf8),
               !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return s.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }

    static func buildSystemPrompt(bot: Bot, repoRoot: URL, skillBlock: String) -> String {
        let persona = loadPersonaMarkdown(bot: bot, repoRoot: repoRoot)
        var parts: [String] = []
        parts.append("你是超级工作台里的数字员工「\(bot.name)」。")
        parts.append("职位：\(bot.role)。职责：\(bot.duty)")
        if !bot.skills.isEmpty {
            parts.append("技能概要：\(bot.skills)")
        }
        if !bot.memory.isEmpty {
            parts.append("既有记忆（供参考）：\(bot.memory)")
        }
        if !persona.isEmpty {
            parts.append("—— 角色设定 ——\n\(persona)")
        }
        if !skillBlock.isEmpty {
            parts.append(skillBlock)
        }
        parts.append("用中文简洁、可执行地回复。不要假装已在外部系统完成未真正执行的操作。")
        return parts.joined(separator: "\n\n")
    }

    /// Prefer prefs → global active (Qwen if active) → first enabled provider.
    static func resolveModel(botId: String, repoRoot: URL?) -> (providerId: String, baseURL: String, model: String) {
        let prefs = loadPrefs(botId: botId)
        let providers = SharedModelStore.loadProviders(repoRoot: repoRoot)
        let doc = SharedModelStore.loadDocument(repoRoot: repoRoot)
        func enabled(_ p: [String: Any]) -> Bool {
            if let b = p["status"] as? Bool { return b }
            if let n = p["status"] as? NSNumber { return n.boolValue }
            return true
        }
        func pick(_ id: String) -> (String, String, String)? {
            guard let p = providers.first(where: { ($0["id"] as? String) == id }), enabled(p) else { return nil }
            let base = (p["baseURL"] as? String) ?? (p["baseUrl"] as? String) ?? ""
            let model = prefs.model.isEmpty
                ? ((p["model"] as? String) ?? (p["defaultModel"] as? String) ?? "")
                : prefs.model
            guard !base.isEmpty else { return nil }
            return (id, base, model)
        }
        if !prefs.providerId.isEmpty, let hit = pick(prefs.providerId) {
            return sanitizeResolved(hit)
        }
        // Prefer Qwen when it is the active global default or enabled.
        let active = doc.activeProviderId
        if !active.isEmpty, let hit = pick(active) {
            return sanitizeResolved(hit)
        }
        if let qwen = pick("qwen") { return sanitizeResolved(qwen) }
        if let alicoding = pick("alicoding") { return sanitizeResolved(alicoding) }
        for p in providers where enabled(p) {
            let id = (p["id"] as? String) ?? ""
            if let hit = pick(id) { return sanitizeResolved(hit) }
        }
        let legacyModel = UserDefaults.standard.string(forKey: "sw.agent.model") ?? AgentLLMClient.preferredDefaultModel
        let legacyBase = UserDefaults.standard.string(forKey: "sw.agent.baseURL") ?? AgentLLMClient.preferredDefaultBaseURL
        return sanitizeResolved(("qwen", legacyBase, legacyModel))
    }

    private static func sanitizeResolved(_ r: (providerId: String, baseURL: String, model: String)) -> (providerId: String, baseURL: String, model: String) {
        let m = r.model.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = m.lowercased()
        if m.isEmpty || lower.contains("skyclaw") || lower == "skywork-ai/skyclaw-v1" {
            return (AgentLLMClient.preferredDefaultProviderId, AgentLLMClient.preferredDefaultBaseURL, AgentLLMClient.preferredDefaultModel)
        }
        return r
    }

    private static func sanitize(_ botId: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let mapped = botId.unicodeScalars.map { allowed.contains($0) ? Character($0) : Character("-") }
        let s = String(mapped)
        return s.isEmpty ? "unknown" : s
    }

    static func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
