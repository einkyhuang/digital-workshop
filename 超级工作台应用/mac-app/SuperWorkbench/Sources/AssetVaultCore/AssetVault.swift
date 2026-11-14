import Foundation

/// Pure asset-vault rules shared by the Mac app. Secrets are a patch, never a file field.
/// Keep in step with `超级工作台应用/app/assets/asset-vault.mjs`.
public enum AssetVaultCatalog {
    public static let categories = ["电商", "社交", "广告", "主机", "域名", "邮箱", "支付", "其他"]
    public static let twoFactorOptions: [(id: String, label: String)] = [
        ("none", "无"),
        ("totp", "验证器 App"),
        ("sms", "短信"),
        ("email", "邮箱"),
        ("hardware", "硬件密钥"),
        ("other", "其他"),
    ]
    public static let publicFields = [
        "id", "platform", "category", "loginURL", "username", "email", "notes",
        "twoFactor", "tags", "company", "brand", "updatedAt",
    ]
    public static let secretFields = ["password", "apiKey", "recoveryCodes", "totpSecret", "extra"]
    public static let clipboardClearSeconds: TimeInterval = 45
    public static let csvMaxChars = 512_000
    public static let csvMaxRows = 1000
}

public struct AssetAccount: Equatable, Identifiable {
    public var id: String
    public var platform: String
    public var category: String
    public var loginURL: String
    public var username: String
    /// Optional. Missing on older files; an email-shaped username is shown as 邮箱 too.
    public var email: String
    public var notes: String
    public var twoFactor: String
    public var tags: [String]
    public var company: String
    public var brand: String
    public var updatedAt: String
    public var hasSecret: Bool
    /// Presence only. The password itself never lives on this value.
    public var hasPassword: Bool
    /// Presence only. The API key itself never lives on this value.
    public var hasApiKey: Bool

    public init(
        id: String = "",
        platform: String = "",
        category: String = "其他",
        loginURL: String = "",
        username: String = "",
        email: String = "",
        notes: String = "",
        twoFactor: String = "none",
        tags: [String] = [],
        company: String = "",
        brand: String = "",
        updatedAt: String = "",
        hasSecret: Bool = false,
        hasPassword: Bool = false,
        hasApiKey: Bool = false
    ) {
        self.id = id
        self.platform = platform
        self.category = category
        self.loginURL = loginURL
        self.username = username
        self.email = email
        self.notes = notes
        self.twoFactor = twoFactor
        self.tags = tags
        self.company = company
        self.brand = brand
        self.updatedAt = updatedAt
        self.hasSecret = hasSecret
        self.hasPassword = hasPassword
        self.hasApiKey = hasApiKey
    }

    public static var empty: AssetAccount { AssetAccount() }

    public func fileJSON() -> [String: Any] {
        [
            "id": id,
            "platform": platform,
            "category": category,
            "loginURL": loginURL,
            "username": username,
            "email": email,
            "notes": notes,
            "twoFactor": twoFactor,
            "tags": tags,
            "company": company,
            "brand": brand,
            "updatedAt": updatedAt,
        ]
    }

    public func apiJSON() -> [String: Any] {
        var json = fileJSON()
        json["hasSecret"] = hasSecret
        json["hasPassword"] = hasPassword
        json["hasApiKey"] = hasApiKey
        return json
    }
}

/// Booleans only. Callers must not keep the secret strings used to compute these.
public struct AssetSecretFlags: Equatable {
    public var hasPassword: Bool
    public var hasApiKey: Bool
    public var hasAny: Bool

    public init(hasPassword: Bool, hasApiKey: Bool, hasAny: Bool) {
        self.hasPassword = hasPassword
        self.hasApiKey = hasApiKey
        self.hasAny = hasAny
    }

    public static let none = AssetSecretFlags(hasPassword: false, hasApiKey: false, hasAny: false)
}

public struct AssetCategoryTab: Equatable, Identifiable {
    public var name: String
    public var count: Int
    public var id: String { name }

    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

/// One card row. Secret rows keep `value` empty so a render pass cannot leak the keychain.
public struct AssetCopyField: Equatable, Identifiable {
    public var id: String
    public var label: String
    public var icon: String
    public var value: String
    public var secret: Bool
    public var hint: String

    public init(id: String, label: String, icon: String, value: String, secret: Bool, hint: String = "") {
        self.id = id
        self.label = label
        self.icon = icon
        self.value = value
        self.secret = secret
        self.hint = hint
    }
}

public struct AssetSecrets: Equatable, Codable {
    public var password: String
    public var apiKey: String
    public var recoveryCodes: String
    public var totpSecret: String
    public var extra: String

    public init(password: String = "", apiKey: String = "", recoveryCodes: String = "", totpSecret: String = "", extra: String = "") {
        self.password = password
        self.apiKey = apiKey
        self.recoveryCodes = recoveryCodes
        self.totpSecret = totpSecret
        self.extra = extra
    }

    public static let empty = AssetSecrets()

    public var isEmpty: Bool {
        password.isEmpty && apiKey.isEmpty && recoveryCodes.isEmpty && totpSecret.isEmpty && extra.isEmpty
    }

    public var flags: AssetSecretFlags {
        AssetSecretFlags(hasPassword: !password.isEmpty, hasApiKey: !apiKey.isEmpty, hasAny: !isEmpty)
    }
}

public struct AssetSecretPatch: Equatable {
    public var values: [String: String]

    public init(values: [String: String] = [:]) {
        self.values = values
    }

    public var hasValue: Bool {
        values.values.contains { !$0.isEmpty }
    }

    public func apply(to existing: AssetSecrets) -> AssetSecrets {
        var next = existing
        if let value = values["password"] { next.password = value }
        if let value = values["apiKey"] { next.apiKey = value }
        if let value = values["recoveryCodes"] { next.recoveryCodes = value }
        if let value = values["totpSecret"] { next.totpSecret = value }
        if let value = values["extra"] { next.extra = value }
        return next
    }
}

public struct AssetDraft: Equatable {
    public var account: AssetAccount
    public var patch: AssetSecretPatch
}

public enum AssetVaultError: Error, Equatable {
    case invalidPlatform
    case invalidId
    case pathEscape
    case csv(String)
    case io(String)
    case keychain(Int32)
}

public enum AssetVault {
    public static func compactKey(_ key: String) -> String {
        var out = ""
        for scalar in key.lowercased().unicodeScalars {
            if scalar == " " || scalar == "_" || scalar == "-" { continue }
            out.unicodeScalars.append(scalar)
        }
        return out
    }

    public static func canonicalSecret(_ key: String) -> String? {
        switch compactKey(key) {
        case "password", "passwd", "pwd", "密码": return "password"
        case "apikey", "密钥", "api密钥": return "apiKey"
        case "recoverycodes", "recovery", "恢复码": return "recoveryCodes"
        case "totpsecret", "totp", "otpsecret", "验证器密钥": return "totpSecret"
        case "token", "accesstoken", "secret": return "extra"
        default: return nil
        }
    }

    public static func containsSecretKey(_ value: Any) -> Bool {
        if let array = value as? [Any] {
            return array.contains { containsSecretKey($0) }
        }
        if let array = value as? NSArray {
            for item in array where containsSecretKey(item) { return true }
            return false
        }
        guard let dict = dictionary(value) else { return false }
        for (key, child) in dict {
            if key == "secrets" || canonicalSecret(key) != nil { return true }
            if containsSecretKey(child) { return true }
        }
        return false
    }

    public static func dictionary(_ value: Any) -> [String: Any]? {
        if let dict = value as? [String: Any] { return dict }
        guard let dict = value as? NSDictionary else { return nil }
        var out: [String: Any] = [:]
        for (key, item) in dict {
            guard let key = key as? String else { continue }
            out[key] = item
        }
        return out
    }

    public static func isValidId(_ id: String) -> Bool {
        guard (1...81).contains(id.count) else { return false }
        let scalars = Array(id.unicodeScalars)
        guard let first = scalars.first, isASCIIAlnum(first) else { return false }
        return scalars.dropFirst().allSatisfy { isASCIIAlnum($0) || $0 == "_" || $0 == "-" }
    }

    public static func safeCategory(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned.removeAll { $0 == "/" || $0 == "\\" || $0 == "\0" }
        while cleaned.hasPrefix(".") { cleaned.removeFirst() }
        if cleaned.count > 32 { cleaned = String(cleaned.prefix(32)) }
        if cleaned.isEmpty || cleaned == "." || cleaned == ".." { return "其他" }
        return cleaned
    }

    public static func safeLoginURL(_ raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let url = URL(string: text), let scheme = url.scheme?.lowercased() else { return "" }
        if scheme != "http" && scheme != "https" { return "" }
        if let user = url.user, !user.isEmpty { return "" }
        if let password = url.password, !password.isEmpty { return "" }
        return url.absoluteString
    }

    public static func normalizeTwoFactor(_ raw: String) -> String {
        switch compactKey(raw) {
        case "", "none", "无", "没有": return "none"
        case "totp", "app", "authenticator", "验证器", "验证器app": return "totp"
        case "sms", "短信": return "sms"
        case "email", "邮箱": return "email"
        case "hardware", "硬件", "硬件密钥": return "hardware"
        case "other", "其他": return "other"
        default: return "none"
        }
    }

    public static func normalizeTags(_ raw: Any?) -> [String] {
        let parts: [String]
        if let array = raw as? [Any] {
            parts = array.map { stringValue($0) }
        } else {
            parts = stringValue(raw).split { ",，;；|".contains($0) }.map(String.init)
        }
        var out: [String] = []
        for part in parts {
            let tag = clip(part.trimmingCharacters(in: .whitespacesAndNewlines), 32)
            if tag.isEmpty || out.contains(tag) { continue }
            out.append(tag)
            if out.count >= 20 { break }
        }
        return out
    }

    public static func isoNow(_ date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    public static func splitRecord(_ input: [String: Any], now: Date = Date()) throws -> AssetDraft {
        var patch: [String: String] = [:]
        var meta: [String: Any] = [:]
        for (key, value) in input {
            if key == "secrets", let nested = value as? [String: Any] {
                absorbSecrets(nested, into: &patch)
                continue
            }
            if let canon = canonicalSecret(key) {
                absorb(stringValue(value), as: canon, into: &patch)
                continue
            }
            if key == "hasSecret" { continue }
            meta[key] = value
        }
        let account = try normalizeAccount(meta, now: now)
        return AssetDraft(account: account, patch: AssetSecretPatch(values: patch))
    }

    public static func looksLikeEmail(_ raw: String) -> Bool {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let local = parts[0]
        let domain = parts[1]
        guard !local.isEmpty, domain.contains("."), !domain.hasPrefix("."), !domain.hasSuffix(".") else { return false }
        let blocked = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "/\\"))
        return text.unicodeScalars.allSatisfy { !blocked.contains($0) }
    }

    /// 「全部」 plus categories that currently have accounts. Built-ins stay in catalog order; custom folders follow.
    public static func categoryTabs(_ accounts: [AssetAccount]) -> [AssetCategoryTab] {
        var counts: [String: Int] = [:]
        for account in accounts {
            let name = account.category.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty { continue }
            counts[name, default: 0] += 1
        }
        let present = Set(counts.keys)
        let builtin = AssetVaultCatalog.categories.filter { present.contains($0) }
        let custom = present.subtracting(AssetVaultCatalog.categories).sorted()
        var tabs = [AssetCategoryTab(name: "全部", count: accounts.count)]
        for name in builtin + custom {
            tabs.append(AssetCategoryTab(name: name, count: counts[name] ?? 0))
        }
        return tabs
    }

    /// Rows to show on a card. Empty fields are omitted. Password and API values are never copied into the row.
    public static func cardFields(for account: AssetAccount) -> [AssetCopyField] {
        var rows: [AssetCopyField] = []
        let user = account.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = account.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let same = !user.isEmpty && !mail.isEmpty && user.lowercased() == mail.lowercased()
        if !user.isEmpty && looksLikeEmail(user) && (mail.isEmpty || same) {
            rows.append(AssetCopyField(
                id: "username",
                label: "账号/邮箱",
                icon: "envelope",
                value: mail.isEmpty ? user : mail,
                secret: false
            ))
        } else if !user.isEmpty {
            rows.append(AssetCopyField(id: "username", label: "账号", icon: "person", value: user, secret: false))
        }
        if !mail.isEmpty && !same {
            rows.append(AssetCopyField(id: "email", label: "邮箱", icon: "envelope", value: mail, secret: false))
        }
        if account.hasPassword {
            rows.append(AssetCopyField(id: "password", label: "密码", icon: "key", value: "", secret: true, hint: "请在 Mac 应用中复制"))
        }
        if account.hasApiKey {
            rows.append(AssetCopyField(id: "apiKey", label: "API", icon: "api", value: "", secret: true, hint: "请在 Mac 应用中复制"))
        }
        let login = account.loginURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !login.isEmpty {
            rows.append(AssetCopyField(id: "loginURL", label: "登录地址", icon: "link", value: login, secret: false))
        }
        return rows
    }

    /// Public copy payload. Secret rows always return an empty string.
    public static func copyText(for field: AssetCopyField) -> String {
        guard !field.secret else { return "" }
        return field.value
    }

    public static func filter(_ accounts: [AssetAccount], query: String, category: String) -> [AssetAccount] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return accounts.filter { account in
            if !cat.isEmpty && cat != "全部" && account.category != cat { return false }
            if needle.isEmpty { return true }
            let hay = ([
                account.platform, account.category, account.loginURL, account.username, account.email,
                account.notes, account.company, account.brand,
            ] + account.tags).joined(separator: "\n").lowercased()
            return hay.contains(needle)
        }
    }

    public static func parseCSV(_ text: String) -> (rows: [AssetDraft], errors: [String]) {
        if text.count > AssetVaultCatalog.csvMaxChars { return ([], ["csv 过大"]) }
        let records = parseRecords(text)
        guard let headerRow = records.first else { return ([], ["csv 是空的"]) }
        let header = headerRow.map(headerName)
        guard header.contains("platform") else { return ([], ["csv 需要平台列"]) }
        var rows: [AssetDraft] = []
        var errors: [String] = []
        for (offset, cells) in records.dropFirst().enumerated() {
            if rows.count >= AssetVaultCatalog.csvMaxRows {
                errors.append("超过 1000 行，其余已忽略")
                break
            }
            if cells.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { continue }
            var obj: [String: Any] = [:]
            for (index, key) in header.enumerated() where !key.isEmpty {
                obj[key] = index < cells.count ? cells[index] : ""
            }
            do {
                rows.append(try splitRecord(obj))
            } catch AssetVaultError.invalidId {
                errors.append("第 \(offset + 2) 行：无效的条目 id")
            } catch {
                errors.append("第 \(offset + 2) 行：缺少平台名称")
            }
        }
        return (rows, errors)
    }

    public static func generatePassword(
        length: Int = 20,
        lower: Bool = true,
        upper: Bool = true,
        digits: Bool = true,
        symbols: Bool = true,
        avoidAmbiguous: Bool = true,
        randomByte: (() -> UInt8)? = nil
    ) throws -> String {
        let randomByte = randomByte ?? AssetVault.defaultRandomByte
        let count = min(128, max(8, length))
        var classes: [String] = []
        if lower { classes.append(avoidAmbiguous ? "abcdefghijkmnpqrstuvwxyz" : "abcdefghijklmnopqrstuvwxyz") }
        if upper { classes.append(avoidAmbiguous ? "ABCDEFGHJKLMNPQRSTUVWXYZ" : "ABCDEFGHIJKLMNOPQRSTUVWXYZ") }
        if digits { classes.append(avoidAmbiguous ? "23456789" : "0123456789") }
        if symbols { classes.append("!@#$%^&*-_=+?") }
        if classes.isEmpty { throw AssetVaultError.csv("至少选择一类字符") }
        let pool = classes.joined()
        let poolChars = Array(pool)
        var chars: [Character] = []
        for _ in 0..<count {
            chars.append(poolChars[randomIndex(poolChars.count, randomByte)])
        }
        for (index, set) in classes.enumerated() {
            let setChars = Array(set)
            if !chars.contains(where: { setChars.contains($0) }) {
                chars[index % chars.count] = setChars[randomIndex(setChars.count, randomByte)]
            }
        }
        if chars.count > 1 {
            for index in stride(from: chars.count - 1, through: 1, by: -1) {
                let swap = randomIndex(index + 1, randomByte)
                chars.swapAt(index, swap)
            }
        }
        return String(chars)
    }

    public static func shouldClearClipboard(copied: String, current: String?, elapsed: TimeInterval, limit: TimeInterval = AssetVaultCatalog.clipboardClearSeconds) -> Bool {
        guard !copied.isEmpty, let current, current == copied else { return false }
        return elapsed >= limit
    }

    public static func redactJSONText(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) else { return "" }
        let stripped = stripSecretKeys(obj)
        guard JSONSerialization.isValidJSONObject(stripped),
              let out = try? JSONSerialization.data(withJSONObject: stripped, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: out, encoding: .utf8) else { return "" }
        return text
    }

    public static func isAssetVaultPath(_ path: String) -> Bool {
        path.split(whereSeparator: { $0 == "/" || $0 == "\\" }).contains("资产管理")
    }

    static func stripSecretKeys(_ value: Any) -> Any {
        if let array = value as? [Any] { return array.map { stripSecretKeys($0) } }
        if let array = value as? NSArray { return array.map { stripSecretKeys($0) } }
        guard let dict = dictionary(value) else { return value }
        var out: [String: Any] = [:]
        for (key, child) in dict {
            if key == "secrets" || canonicalSecret(key) != nil { continue }
            if dictionary(child) != nil || child is [Any] || child is NSArray {
                out[key] = stripSecretKeys(child)
            } else {
                out[key] = child
            }
        }
        return out
    }

    private static func normalizeAccount(_ meta: [String: Any], now: Date) throws -> AssetAccount {
        let platform = clip(stringValue(meta["platform"]).trimmingCharacters(in: .whitespacesAndNewlines), 120)
        if platform.isEmpty { throw AssetVaultError.invalidPlatform }
        let id = stringValue(meta["id"]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !id.isEmpty && !isValidId(id) { throw AssetVaultError.invalidId }
        return AssetAccount(
            id: id,
            platform: platform,
            category: safeCategory(stringValue(meta["category"])),
            loginURL: safeLoginURL(stringValue(meta["loginURL"])),
            username: clip(stringValue(meta["username"]).trimmingCharacters(in: .whitespacesAndNewlines), 200),
            email: clip(stringValue(meta["email"]).trimmingCharacters(in: .whitespacesAndNewlines), 200),
            notes: clip(stringValue(meta["notes"]), 8000),
            twoFactor: normalizeTwoFactor(stringValue(meta["twoFactor"])),
            tags: normalizeTags(meta["tags"]),
            company: clip(stringValue(meta["company"]).trimmingCharacters(in: .whitespacesAndNewlines), 120),
            brand: clip(stringValue(meta["brand"]).trimmingCharacters(in: .whitespacesAndNewlines), 120),
            updatedAt: isoNow(now),
            hasSecret: false
        )
    }

    private static func absorbSecrets(_ dict: [String: Any], into patch: inout [String: String]) {
        for (key, value) in dict {
            guard let canon = canonicalSecret(key) else { continue }
            absorb(stringValue(value), as: canon, into: &patch)
        }
    }

    private static func absorb(_ text: String, as canon: String, into patch: inout [String: String]) {
        if patch[canon] == nil || patch[canon]?.isEmpty == true {
            patch[canon] = text
        } else if !text.isEmpty {
            patch[canon] = (patch[canon] ?? "") + "\n" + text
        }
    }

    private static func headerName(_ cell: String) -> String {
        switch compactKey(cell.trimmingCharacters(in: .whitespacesAndNewlines)) {
        case "platform", "name", "平台", "平台名称": return "platform"
        case "category", "分类": return "category"
        case "loginurl", "url", "登录地址", "登录网址", "网址": return "loginURL"
        case "username", "user", "用户名", "账号": return "username"
        case "email", "邮箱": return "email"
        case "password", "passwd", "pwd", "密码": return "password"
        case "notes", "note", "备注": return "notes"
        case "twofactor", "2fa", "二次验证", "双重验证": return "twoFactor"
        case "tags", "标签": return "tags"
        case "company", "公司", "关联公司": return "company"
        case "brand", "品牌": return "brand"
        case "apikey", "密钥", "api密钥": return "apiKey"
        case "recoverycodes", "recovery", "恢复码": return "recoveryCodes"
        case "totpsecret", "totp", "otpsecret", "验证器密钥": return "totpSecret"
        case "token", "accesstoken", "secret": return "extra"
        case "id": return "id"
        default: return ""
        }
    }

    private static func parseRecords(_ text: String) -> [[String]] {
        var records: [[String]] = []
        var row: [String] = []
        var cell = ""
        var quoted = false
        let src = text.hasPrefix("\u{feff}") ? String(text.dropFirst()) : text
        let chars = Array(src)
        var index = 0
        while index < chars.count {
            let ch = chars[index]
            if quoted {
                if ch == "\"" {
                    if index + 1 < chars.count && chars[index + 1] == "\"" {
                        cell.append("\"")
                        index += 2
                        continue
                    }
                    quoted = false
                } else {
                    cell.append(ch)
                }
                index += 1
                continue
            }
            if ch == "\"" {
                quoted = true
                index += 1
                continue
            }
            if ch == "," {
                row.append(cell)
                cell = ""
                index += 1
                continue
            }
            if ch == "\n" || ch == "\r" {
                if ch == "\r" && index + 1 < chars.count && chars[index + 1] == "\n" { index += 1 }
                row.append(cell)
                records.append(row)
                row = []
                cell = ""
                index += 1
                continue
            }
            cell.append(ch)
            index += 1
        }
        if !cell.isEmpty || !row.isEmpty {
            row.append(cell)
            records.append(row)
        }
        return records.enumerated().compactMap { offset, record in
            if offset == 0 || record.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                return record
            }
            return nil
        }
    }

    private static func randomIndex(_ modulo: Int, _ randomByte: () -> UInt8) -> Int {
        if modulo <= 1 { return 0 }
        let max = (256 / modulo) * modulo
        var guardCount = 0
        var value = Int(randomByte())
        while value >= max && guardCount < 32 {
            value = Int(randomByte())
            guardCount += 1
        }
        return value % modulo
    }

    private static func defaultRandomByte() -> UInt8 {
        var byte: UInt8 = 0
        for _ in 0..<8 {
            byte = byte &+ UInt8.random(in: 0...255)
        }
        return byte
    }

    private static func isASCIIAlnum(_ scalar: Unicode.Scalar) -> Bool {
        (scalar >= "A" && scalar <= "Z") || (scalar >= "a" && scalar <= "z") || (scalar >= "0" && scalar <= "9")
    }

    private static func clip(_ text: String, _ max: Int) -> String {
        String(text.prefix(max))
    }

    private static func stringValue(_ value: Any?) -> String {
        switch value {
        case let text as String: return text
        case let number as NSNumber: return number.stringValue
        case nil: return ""
        default: return String(describing: value ?? "")
        }
    }
}

public enum ClipboardClearPolicy {
    public static func shouldClear(copied: String, current: String?, elapsed: TimeInterval) -> Bool {
        AssetVault.shouldClearClipboard(copied: copied, current: current, elapsed: elapsed)
    }
}
