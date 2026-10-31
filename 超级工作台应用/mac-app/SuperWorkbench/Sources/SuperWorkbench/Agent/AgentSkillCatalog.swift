import Foundation

/// Discover skills from repo skill folders + workbench prefs, and load SKILL.md for prompt context.
enum AgentSkillCatalog {
    struct Option: Identifiable, Hashable {
        var id: String { value }
        var value: String
        var label: String
        var desc: String
        var source: String
        /// Absolute path to SKILL.md when found on disk.
        var skillMdPath: String?
    }

    static let maxBytesPerSkill = 8_000
    static let maxBytesTotal = 24_000

    /// Merge catalog prefs, imported IDE skills, and on-disk SKILL.md folders under repoRoot.
    static func allOptions(repoRoot: URL?) -> [Option] {
        var byId: [String: Option] = [:]

        for sk in SharedWorkbenchPrefs.catalog {
            byId[sk.value] = Option(
                value: sk.value,
                label: sk.label,
                desc: sk.desc,
                source: sk.source,
                skillMdPath: nil
            )
        }

        let prefs = SharedWorkbenchPrefs.load()
        for sk in prefs.importedSkills {
            var opt = byId[sk.value] ?? Option(
                value: sk.value,
                label: sk.label,
                desc: sk.desc,
                source: sk.source,
                skillMdPath: nil
            )
            if !sk.label.isEmpty { opt.label = sk.label }
            if !sk.desc.isEmpty { opt.desc = sk.desc }
            opt.source = sk.source.isEmpty ? "imported" : sk.source
            byId[sk.value] = opt
        }

        guard let repoRoot else {
            return byId.values.sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
        }

        for hit in scanSkillFiles(repoRoot: repoRoot) {
            let value = hit.folderName
            var opt = byId[value] ?? Option(
                value: value,
                label: humanize(value),
                desc: "来自 \(hit.relativeDir)",
                source: "repo",
                skillMdPath: hit.url.path
            )
            opt.skillMdPath = hit.url.path
            if opt.source == "catalog" { opt.source = "repo+catalog" }
            byId[value] = opt
        }

        return byId.values.sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
    }

    /// Build system-context block from selected skill ids. Truncates to maxBytesTotal.
    static func systemContext(selectedIds: [String], repoRoot: URL?) -> String {
        guard !selectedIds.isEmpty else { return "" }
        let opts = allOptions(repoRoot: repoRoot)
        let map = Dictionary(uniqueKeysWithValues: opts.map { ($0.value, $0) })
        var parts: [String] = []
        var used = 0
        for id in selectedIds {
            guard let opt = map[id] else { continue }
            var body = loadSkillMarkdown(opt: opt, repoRoot: repoRoot)
            if body.isEmpty {
                body = "（无 SKILL.md 正文；仅有元数据）\n名称：\(opt.label)\n说明：\(opt.desc)"
            }
            if body.utf8.count > maxBytesPerSkill {
                let data = Data(body.utf8.prefix(maxBytesPerSkill))
                let cut = String(data: data, encoding: .utf8) ?? String(body.prefix(2000))
                body = cut + "\n…(截断)"
            }
            let chunk = "### Skill: \(opt.label) (`\(opt.value)`)\n\(body)"
            let next = used + chunk.utf8.count
            if next > maxBytesTotal {
                parts.append("### Skill: \(opt.label) (`\(opt.value)`)\n…(跳过：技能上下文已达上限)")
                break
            }
            parts.append(chunk)
            used = next
        }
        guard !parts.isEmpty else { return "" }
        return """
        —— 用户启用的 Skills（请优先遵循）——
        \(parts.joined(separator: "\n\n"))
        —— Skills 结束 ——
        """
    }

    // MARK: - Disk scan

    private struct SkillHit {
        var folderName: String
        var relativeDir: String
        var url: URL
    }

    private static func scanSkillFiles(repoRoot: URL) -> [SkillHit] {
        let fm = FileManager.default
        var hits: [SkillHit] = []
        let candidates: [URL] = [
            repoRoot.appendingPathComponent("书库/样例skill", isDirectory: true),
            repoRoot.appendingPathComponent("skills", isDirectory: true),
            repoRoot.appendingPathComponent("超级工作台应用/skills", isDirectory: true),
            repoRoot.appendingPathComponent("bots", isDirectory: true)
        ]
        for root in candidates {
            guard fm.fileExists(atPath: root.path) else { continue }
            guard let en = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            var depthGuard = 0
            while let item = en.nextObject() as? URL {
                depthGuard += 1
                if depthGuard > 8_000 { break }
                if item.lastPathComponent != "SKILL.md" { continue }
                // Prefer …/<skillName>/SKILL.md
                let folder = item.deletingLastPathComponent()
                let name = folder.lastPathComponent
                if name.isEmpty || name == "deliverables" || name == "files" { continue }
                let rel = item.path.replacingOccurrences(of: repoRoot.path + "/", with: "")
                hits.append(SkillHit(folderName: name, relativeDir: rel, url: item))
            }
        }
        // Dedupe by folder name — prefer shorter relative path (closer to curated samples)
        var best: [String: SkillHit] = [:]
        for h in hits {
            if let cur = best[h.folderName] {
                if h.relativeDir.count < cur.relativeDir.count { best[h.folderName] = h }
            } else {
                best[h.folderName] = h
            }
        }
        return Array(best.values)
    }

    private static func loadSkillMarkdown(opt: Option, repoRoot: URL?) -> String {
        if let path = opt.skillMdPath, let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let s = String(data: data, encoding: .utf8) {
            return s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let repoRoot else { return "" }
        // Fallback: try common layouts
        let guesses = [
            repoRoot.appendingPathComponent("书库/样例skill/\(opt.value)/SKILL.md"),
            repoRoot.appendingPathComponent("skills/\(opt.value)/SKILL.md"),
            repoRoot.appendingPathComponent("超级工作台应用/skills/\(opt.value)/SKILL.md")
        ]
        for u in guesses {
            if let data = try? Data(contentsOf: u), let s = String(data: data, encoding: .utf8) {
                return s.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }

    private static func humanize(_ id: String) -> String {
        id.replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }
}
