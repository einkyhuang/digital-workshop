import Foundation

/// Scans gitignored local Markdown archives and strips them back out of settings saves.
/// Mirrors `crm-magichub/src/lib/localArchives.js`. Report bodies stay in the Markdown files.
enum LocalArchiveIndex {
    static let customerMarkdown: [String: String] = [
        "档案.md": "profile",
        "深度分析.md": "analysis",
        "30天营销规划.md": "plan",
        "跟进记录.md": "followup",
    ]

    static let customerFolders: [String: (id: String, label: String)] = [
        "照明": ("lights", "照明"),
        "服装": ("apparel", "服装"),
        "布料": ("fabric", "布料"),
        "汽配": ("parts", "汽配"),
        "lights": ("lights", "照明"),
        "apparel": ("apparel", "服装"),
        "fabric": ("fabric", "布料"),
        "parts": ("parts", "汽配"),
    ]

    static let knowledgeFolders: [String: String] = [
        "产品": "products",
        "产品参数": "products",
        "products": "products",
        "行业": "industry",
        "行业动态": "industry",
        "industry": "industry",
        "开发": "sourcing",
        "开发采购": "sourcing",
        "采购": "sourcing",
        "sourcing": "sourcing",
        "营销": "marketing",
        "营销话术": "marketing",
        "marketing": "marketing",
        "技能": "skills",
        "业务技能": "skills",
        "skills": "skills",
    ]

    static let knowledgeLabels: [String: String] = [
        "products": "产品参数",
        "industry": "行业动态",
        "sourcing": "开发采购",
        "marketing": "营销话术",
        "skills": "业务技能",
    ]

    private static let ephemeralLeadKeys: [String] = [
        "archiveBacked", "archiveOnly", "archiveKey", "archiveFolder", "archiveFiles",
        "archiveUpdatedAt", "archiveCategory", "archiveCategoryLabel", "libraryIndex",
    ]

    static func customerRoot(repoRoot: URL) -> URL {
        repoRoot.appendingPathComponent("超级工作台应用/data/private/客户档案", isDirectory: true)
    }

    static func knowledgeRoot(repoRoot: URL) -> URL {
        repoRoot.appendingPathComponent("超级工作台应用/data/private/知识库", isDirectory: true)
    }

    static func listCustomers(repoRoot: URL, limit: Int = 500) -> [[String: Any]] {
        let root = customerRoot(repoRoot: repoRoot)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir), isDir.boolValue else { return [] }
        guard let rootReal = realURL(root) else { return [] }
        let fm = FileManager.default
        var archives: [[String: Any]] = []
        let categories = (try? fm.contentsOfDirectory(atPath: root.path)) ?? []
        for categoryName in categories where !categoryName.hasPrefix(".") {
            if archives.count >= limit { break }
            let categoryURL = root.appendingPathComponent(categoryName, isDirectory: true)
            guard directoryInside(categoryURL, root: rootReal) != nil else { continue }
            let customersURL = categoryURL.appendingPathComponent("客户", isDirectory: true)
            guard directoryInside(customersURL, root: rootReal) != nil else { continue }
            let category = customerCategory(categoryName)
            let companies = (try? fm.contentsOfDirectory(atPath: customersURL.path)) ?? []
            for company in companies where !company.hasPrefix(".") {
                if archives.count >= limit { break }
                let folder = customersURL.appendingPathComponent(company, isDirectory: true)
                guard directoryInside(folder, root: rootReal) != nil else { continue }
                let names = (try? fm.contentsOfDirectory(atPath: folder.path)) ?? []
                var files: [String: String] = [:]
                var updated = directoryDate(folder) ?? Date.distantPast
                var profile = ""
                for name in names {
                    guard let role = customerMarkdown[name] else { continue }
                    let file = folder.appendingPathComponent(name)
                    guard let values = fileInside(file, root: rootReal), values.isRegularFile == true else { continue }
                    files[role] = file.path
                    if let modified = values.contentModificationDate, modified > updated { updated = modified }
                    if role == "profile", (values.fileSize ?? 0) <= 256 * 1024,
                       let text = try? String(contentsOf: file, encoding: .utf8) {
                        profile = text
                    }
                }
                if files.isEmpty { continue }
                let fields = parseProfileFields(profile)
                let archiveKey = "\(category.id)/\(company)"
                var record: [String: Any] = [
                    "archiveKey": archiveKey,
                    "id": "archive:\(archiveKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? archiveKey)",
                    "name": company,
                    "category": category.id,
                    "categoryLabel": category.label,
                    "folder": folder.path,
                    "updatedAt": isoString(updated),
                    "country": fields.country,
                    "contact": fields.contact,
                    "phone": fields.phone,
                    "email": fields.email,
                    "files": files,
                ]
                if let score = fields.score { record["score"] = score }
                archives.append(record)
            }
        }
        archives.sort { String(describing: $0["updatedAt"] ?? "") > String(describing: $1["updatedAt"] ?? "") }
        return archives
    }

    static func listKnowledge(repoRoot: URL, limit: Int = 500) -> [[String: Any]] {
        let root = knowledgeRoot(repoRoot: repoRoot)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir), isDir.boolValue else { return [] }
        guard let rootReal = realURL(root) else { return [] }
        var paths: [URL] = []
        collectMarkdown(root, rootReal: rootReal, into: &paths, limit: limit)
        var items: [[String: Any]] = []
        for file in paths {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let relative = file.path.replacingOccurrences(of: rootReal.path + "/", with: "")
            let parts = relative.split(separator: "/").map(String.init)
            let folderName = parts.count > 1 ? parts[0] : ""
            let mapped = knowledgeCategory(folderName)
            let split = splitFrontmatter(text)
            let override = (split.meta["category"] ?? split.meta["分类"] ?? "").trimmingCharacters(in: .whitespaces)
            let category: String
            if override.isEmpty {
                category = mapped.id
            } else {
                category = knowledgeCategory(override).id
            }
            let label = knowledgeLabels[category] ?? mapped.label
            let title = firstNonEmpty([
                split.meta["title"], split.meta["标题"], firstHeading(split.body), file.deletingPathExtension().lastPathComponent,
            ])
            let date = String((split.meta["date"] ?? split.meta["日期"] ?? "").prefix(10))
            let modified = fileDate(file) ?? Date()
            let day = date.isEmpty ? isoDay(modified) : date
            items.append([
                "id": "kbfile:\(relative.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? relative)",
                "title": title,
                "category": category,
                "categoryLabel": label,
                "date": day,
                "content": markdownPreview(text),
                "preview": markdownPreview(text),
                "filePath": file.path,
                "source": "archive-file",
                "updatedAt": isoString(modified),
            ])
        }
        items.sort { String(describing: $0["updatedAt"] ?? "") > String(describing: $1["updatedAt"] ?? "") }
        return items
    }

    /// Keep the on-disk lead library. Archive-only cards and live file pointers are not written back.
    static func persistableLeads(_ data: Any) -> Any {
        guard let arr = data as? [Any] else { return data }
        var library: [(Int, [String: Any])] = []
        var appended: [[String: Any]] = []
        for item in arr {
            guard var lead = item as? [String: Any] else { continue }
            if isArchiveOnly(lead) { continue }
            let index = intValue(lead["libraryIndex"])
            for key in ephemeralLeadKeys { lead.removeValue(forKey: key) }
            if let report = lead["deepReport"] as? [String: Any], boolValue(report["liveFromArchive"]) {
                lead.removeValue(forKey: "deepReport")
            }
            if let plan = lead["marketingPlan"] as? [String: Any], boolValue(plan["liveFromArchive"]) {
                lead.removeValue(forKey: "marketingPlan")
            }
            if let index {
                library.append((index, lead))
            } else {
                appended.append(lead)
            }
        }
        library.sort { $0.0 < $1.0 }
        return library.map { $0.1 } + appended
    }

    static func persistableKnowledge(_ data: Any) -> Any {
        guard let dict = data as? [String: Any] else { return data }
        var out: [String: Any] = [:]
        for (key, value) in dict {
            guard let list = value as? [Any] else {
                out[key] = value
                continue
            }
            var kept: [[String: Any]] = []
            for item in list {
                guard var entry = item as? [String: Any] else { continue }
                if isArchiveKnowledge(entry) { continue }
                entry.removeValue(forKey: "filePath")
                entry.removeValue(forKey: "source")
                entry.removeValue(forKey: "updatedAt")
                entry.removeValue(forKey: "preview")
                kept.append(entry)
            }
            out[key] = kept
        }
        return out
    }

    // MARK: - Profile / markdown preview

    static func parseProfileFields(_ text: String) -> (country: String, contact: String, phone: String, email: String, score: Int?) {
        var fields: [String: String] = [:]
        for raw in text.components(separatedBy: "\n") {
            if raw.contains("|") {
                let cells = raw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if cells.count >= 2, cells[0].range(of: #"^:?-+:?$"#, options: .regularExpression) == nil {
                    if fields[cells[0]] == nil { fields[cells[0]] = cells[1] }
                }
            }
            if let match = raw.range(of: #"^[-*]\s*(.+?)\s*[:：]\s*(.+)$"#, options: .regularExpression) {
                let line = String(raw[match])
                let parts = line.dropFirst(2).split(whereSeparator: { $0 == ":" || $0 == "：" })
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    if fields[key] == nil { fields[key] = value }
                }
            }
        }
        let country = fields["国家/地区"] ?? fields["国家"] ?? fields["地区"] ?? ""
        let contact = fields["关键人姓名/职位"] ?? fields["关键人"] ?? fields["联系人"] ?? ""
        let phone = fields["电话"] ?? ""
        let email = fields["邮箱"] ?? ""
        var score: Int? = nil
        if let match = text.range(of: #"星级[：:\s]*\**\s*(\d+(?:\.\d+)?)"#, options: .regularExpression) {
            let snippet = String(text[match])
            if let digits = snippet.range(of: #"\d+(?:\.\d+)?"#, options: .regularExpression) {
                let n = Double(snippet[digits]) ?? 0
                let scaled = n <= 5 ? n * 20 : n
                score = max(0, min(100, Int(scaled.rounded())))
            }
        }
        return (country, contact, phone, email, score)
    }

    static func markdownPreview(_ text: String, limit: Int = 180) -> String {
        let body = splitFrontmatter(text).body
        let noFence = body.replacingOccurrences(of: #"```[\s\S]*?```"#, with: " ", options: .regularExpression)
        let plain = noFence.replacingOccurrences(of: #"[#>*_`|\[\]()\-]"#, with: " ", options: .regularExpression)
        let collapsed = plain.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return String(collapsed.prefix(limit))
    }

    // MARK: - Private

    private static func customerCategory(_ name: String) -> (id: String, label: String) {
        customerFolders[name] ?? (name, name)
    }

    private static func knowledgeCategory(_ name: String) -> (id: String, label: String) {
        if name.isEmpty { return ("industry", knowledgeLabels["industry"] ?? "行业动态") }
        if let id = knowledgeFolders[name] { return (id, knowledgeLabels[id] ?? id) }
        return (name, name)
    }

    private static func isArchiveOnly(_ lead: [String: Any]) -> Bool {
        if boolValue(lead["archiveOnly"]) { return true }
        if let id = lead["id"] as? String, id.hasPrefix("archive:") { return true }
        return false
    }

    private static func isArchiveKnowledge(_ item: [String: Any]) -> Bool {
        if (item["source"] as? String) == "archive-file" { return true }
        if let id = item["id"] as? String, id.hasPrefix("kbfile:") { return true }
        return false
    }

    private static func splitFrontmatter(_ text: String) -> (meta: [String: String], body: String) {
        guard text.hasPrefix("---") else { return ([:], text) }
        guard let end = text.range(of: "\n---", range: text.index(text.startIndex, offsetBy: 3)..<text.endIndex) else {
            return ([:], text)
        }
        let block = text[text.index(text.startIndex, offsetBy: 3)..<end.lowerBound]
        let bodyStart = text.index(end.upperBound, offsetBy: 0)
        var body = String(text[bodyStart...])
        if body.hasPrefix("\n") { body.removeFirst() }
        var meta: [String: String] = [:]
        for line in block.components(separatedBy: "\n") {
            guard let colon = line.firstIndex(where: { $0 == ":" || $0 == "：" }) else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            if !key.isEmpty { meta[key] = String(value) }
        }
        return (meta, body)
    }

    private static func firstHeading(_ body: String) -> String {
        for line in body.components(separatedBy: "\n") {
            if let range = line.range(of: #"^#{1,3}\s+(.+)$"#, options: .regularExpression) {
                let raw = String(line[range])
                return raw.replacingOccurrences(of: #"^#{1,3}\s+"#, with: "", options: .regularExpression)
            }
        }
        return ""
    }

    private static func firstNonEmpty(_ values: [String?]) -> String {
        for value in values {
            let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return "未命名"
    }

    private static func collectMarkdown(_ dir: URL, rootReal: URL, into paths: inout [URL], limit: Int) {
        if paths.count >= limit { return }
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for name in names where !name.hasPrefix(".") {
            if paths.count >= limit { return }
            if name == "归档规则.md" || name == "README.md" || name == "readme.md" { continue }
            let url = dir.appendingPathComponent(name)
            if directoryInside(url, root: rootReal) != nil {
                collectMarkdown(url, rootReal: rootReal, into: &paths, limit: limit)
            } else if name.lowercased().hasSuffix(".md"), fileInside(url, root: rootReal)?.isRegularFile == true {
                paths.append(url)
            }
        }
    }

    private static func realURL(_ url: URL) -> URL? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url.resolvingSymlinksInPath().standardizedFileURL
    }

    private static func directoryInside(_ url: URL, root: URL) -> URL? {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else { return nil }
        guard let real = realURL(url) else { return nil }
        if real.path != root.path && !real.path.hasPrefix(root.path + "/") { return nil }
        return real
    }

    private static func fileInside(_ url: URL, root: URL) -> URLResourceValues? {
        guard let real = realURL(url) else { return nil }
        if real.path != root.path && !real.path.hasPrefix(root.path + "/") { return nil }
        return try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
    }

    private static func directoryDate(_ url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private static func fileDate(_ url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private static func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func isoDay(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private static func intValue(_ value: Any?) -> Int? {
        if value is Bool { return nil }
        if let n = value as? Int { return n }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let b = value as? Bool { return b }
        if let n = value as? NSNumber { return n.boolValue }
        return false
    }
}
