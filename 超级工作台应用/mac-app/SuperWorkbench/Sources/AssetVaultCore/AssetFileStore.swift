import Foundation
#if os(macOS)
import Security
#endif

public protocol AssetSecretStoring: AnyObject {
    func load(id: String) throws -> AssetSecrets?
    func upsert(id: String, secrets: AssetSecrets) throws
    func delete(id: String) throws
    func contains(id: String) -> Bool
    /// Which secret fields are non-empty. Implementations must not hand the secret strings to the caller.
    func flags(id: String) -> AssetSecretFlags
}

public final class MemoryAssetSecretStore: AssetSecretStoring {
    public private(set) var items: [String: AssetSecrets] = [:]
    public init() {}

    public func load(id: String) throws -> AssetSecrets? { items[id] }

    public func upsert(id: String, secrets: AssetSecrets) throws {
        if secrets.isEmpty { items.removeValue(forKey: id) }
        else { items[id] = secrets }
    }

    public func delete(id: String) throws { items.removeValue(forKey: id) }

    public func contains(id: String) -> Bool {
        items[id]?.isEmpty == false
    }

    public func flags(id: String) -> AssetSecretFlags {
        items[id]?.flags ?? .none
    }
}

#if os(macOS)
public final class KeychainAssetSecretStore: AssetSecretStoring {
    public let service: String

    public init(service: String = "com.ky.superworkbench.assets") {
        self.service = service
    }

    public func upsert(id: String, secrets: AssetSecrets) throws {
        let query = baseQuery(id)
        SecItemDelete(query as CFDictionary)
        if secrets.isEmpty { return }
        let data = try JSONEncoder().encode(secrets)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else { throw AssetVaultError.keychain(status) }
    }

    public func load(id: String) throws -> AssetSecrets? {
        var query = baseQuery(id)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = out as? Data else { throw AssetVaultError.keychain(status) }
        return try JSONDecoder().decode(AssetSecrets.self, from: data)
    }

    public func delete(id: String) throws {
        SecItemDelete(baseQuery(id) as CFDictionary)
    }

    /// Existence only. The password bytes are not copied out.
    public func contains(id: String) -> Bool {
        var query = baseQuery(id)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    /// Field presence only. The decoded secret is dropped before return.
    public func flags(id: String) -> AssetSecretFlags {
        if let loaded = try? load(id: id) {
            return loaded.flags
        }
        return AssetSecretFlags(hasPassword: false, hasApiKey: false, hasAny: contains(id: id))
    }

    private func baseQuery(_ id: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "asset:" + id,
        ]
    }
}
#endif

public struct AssetImportResult: Equatable {
    public var imported: Int
    public var skipped: Int
    public var secretsStored: Int
    public var errors: [String]
}

public final class AssetFileStore {
    public let root: URL
    private let queue = DispatchQueue(label: "com.ky.superworkbench.asset-vault")
    private let fm = FileManager.default

    public init(root: URL) {
        self.root = root
    }

    public func list(secrets: AssetSecretStoring) throws -> [AssetAccount] {
        try queue.sync { try listUnlocked(secrets: secrets) }
    }

    public func save(raw: [String: Any], secrets: AssetSecretStoring, now: Date = Date()) throws -> AssetAccount {
        try queue.sync { try saveUnlocked(raw: raw, secrets: secrets, now: now) }
    }

    public func delete(id: String, secrets: AssetSecretStoring) throws -> Bool {
        try queue.sync { try deleteUnlocked(id: id, secrets: secrets) }
    }

    public func importCSV(_ csv: String, secrets: AssetSecretStoring, now: Date = Date()) -> AssetImportResult {
        queue.sync {
            let parsed = AssetVault.parseCSV(csv)
            var imported = 0
            var secretsStored = 0
            var errors = parsed.errors
            for row in parsed.rows {
                do {
                    var raw = row.account.fileJSON()
                    for (key, value) in row.patch.values { raw[key] = value }
                    let saved = try saveUnlocked(raw: raw, secrets: secrets, now: now)
                    imported += 1
                    if saved.hasSecret { secretsStored += 1 }
                } catch {
                    errors.append("有一行没有写入")
                }
            }
            return AssetImportResult(imported: imported, skipped: errors.count, secretsStored: secretsStored, errors: errors)
        }
    }

    private func listUnlocked(secrets: AssetSecretStoring) throws -> [AssetAccount] {
        var accounts: [AssetAccount] = []
        for file in jsonFiles() {
            guard let data = try? Data(contentsOf: file),
                  let obj = try? JSONSerialization.jsonObject(with: data),
                  var dict = AssetVault.dictionary(obj) else { continue }
            let filenameId = file.deletingPathExtension().lastPathComponent
            guard AssetVault.isValidId(filenameId) else { continue }
            let parentName = file.deletingLastPathComponent().lastPathComponent
            let categoryText = (dict["category"] as? String) ?? ""
            if categoryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parentName != root.lastPathComponent {
                dict["category"] = parentName
            }
            if AssetVault.containsSecretKey(dict) {
                if let draft = try? AssetVault.splitRecord(dict) {
                    let id = draft.account.id.isEmpty ? filenameId : draft.account.id
                    guard id == filenameId, AssetVault.isValidId(id) else {
                        try? scrub(dict, at: file)
                        continue
                    }
                    let existing = try secrets.load(id: id) ?? .empty
                    let merged = draft.patch.apply(to: existing)
                    try secrets.upsert(id: id, secrets: merged)
                    var account = draft.account
                    account.id = id
                    applyFlags(merged.flags, to: &account)
                    try writeUnlocked(account)
                    accounts.append(account)
                    continue
                }
                try? scrub(dict, at: file)
                continue
            }
            guard let draft = try? AssetVault.splitRecord(dict) else { continue }
            let id = draft.account.id.isEmpty ? filenameId : draft.account.id
            guard id == filenameId else { continue }
            var account = draft.account
            account.id = id
            applyFlags(secrets.flags(id: id), to: &account)
            accounts.append(account)
        }
        accounts.sort { $0.updatedAt > $1.updatedAt }
        return accounts
    }

    private func saveUnlocked(raw: [String: Any], secrets: AssetSecretStoring, now: Date) throws -> AssetAccount {
        var draft = try AssetVault.splitRecord(raw, now: now)
        if draft.account.id.isEmpty { draft.account.id = UUID().uuidString.lowercased() }
        let existing = try secrets.load(id: draft.account.id) ?? .empty
        let merged = draft.patch.apply(to: existing)
        try secrets.upsert(id: draft.account.id, secrets: merged)
        draft.account.updatedAt = AssetVault.isoNow(now)
        applyFlags(merged.flags, to: &draft.account)
        try writeUnlocked(draft.account)
        return draft.account
    }

    private func deleteUnlocked(id: String, secrets: AssetSecretStoring) throws -> Bool {
        guard AssetVault.isValidId(id) else { throw AssetVaultError.invalidId }
        var removed = false
        for file in jsonFiles() where file.deletingPathExtension().lastPathComponent == id {
            try fm.removeItem(at: file)
            removed = true
        }
        try secrets.delete(id: id)
        return removed
    }

    private func applyFlags(_ flags: AssetSecretFlags, to account: inout AssetAccount) {
        account.hasPassword = flags.hasPassword
        account.hasApiKey = flags.hasApiKey
        account.hasSecret = flags.hasAny
    }

    private func writeUnlocked(_ account: AssetAccount) throws {
        guard AssetVault.isValidId(account.id) else { throw AssetVaultError.invalidId }
        let json = account.fileJSON()
        if AssetVault.containsSecretKey(json) { throw AssetVaultError.io("拒绝把密钥写入文件") }
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let dir = root.appendingPathComponent(AssetVault.safeCategory(account.category), isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let rootReal = root.resolvingSymlinksInPath().standardizedFileURL
        let dirReal = dir.resolvingSymlinksInPath().standardizedFileURL
        guard isInside(dirReal, root: rootReal) else { throw AssetVaultError.pathEscape }
        let dest = dirReal.appendingPathComponent("\(account.id).json")
        guard dest.path.hasPrefix(dirReal.path + "/") else { throw AssetVaultError.pathEscape }
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        let tmp = dest.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        if fm.fileExists(atPath: dest.path) { try? fm.removeItem(at: dest) }
        try fm.moveItem(at: tmp, to: dest)
        for file in jsonFiles() where file.deletingPathExtension().lastPathComponent == account.id && file.path != dest.path {
            try? fm.removeItem(at: file)
        }
    }

    private func scrub(_ dict: [String: Any], at file: URL) throws {
        let stripped = AssetVault.stripSecretKeys(dict)
        guard JSONSerialization.isValidJSONObject(stripped) else { return }
        let data = try JSONSerialization.data(withJSONObject: stripped, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: file, options: .atomic)
    }

    private func jsonFiles() -> [URL] {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: root.path, isDirectory: &isDir), isDir.boolValue else { return [] }
        let rootReal = root.resolvingSymlinksInPath().standardizedFileURL
        guard let enumerator = fm.enumerator(at: rootReal, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return []
        }
        var files: [URL] = []
        for case let url as URL in enumerator {
            let real = url.resolvingSymlinksInPath().standardizedFileURL
            guard isInside(real, root: rootReal) else { continue }
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: real.path, isDirectory: &isDirectory), !isDirectory.boolValue else { continue }
            if real.pathExtension.lowercased() == "json" { files.append(real) }
        }
        return files
    }

    private func isInside(_ url: URL, root: URL) -> Bool {
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        return url.path == root.path || url.path.hasPrefix(rootPath)
    }
}
