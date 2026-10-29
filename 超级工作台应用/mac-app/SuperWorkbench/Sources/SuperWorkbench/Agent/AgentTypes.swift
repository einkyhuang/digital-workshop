import Foundation
import Security

struct AgentChatMessage: Identifiable, Equatable {
    enum Role: String { case system, user, assistant, tool }
    let id: UUID
    var role: Role
    var content: String
    var toolName: String?
    var toolArgsSummary: String?
    var ok: Bool?
    var ms: Int?
    var createdAt: Date

    init(id: UUID = UUID(), role: Role, content: String, toolName: String? = nil,
         toolArgsSummary: String? = nil, ok: Bool? = nil, ms: Int? = nil, createdAt: Date = Date()) {
        self.id = id; self.role = role; self.content = content
        self.toolName = toolName; self.toolArgsSummary = toolArgsSummary
        self.ok = ok; self.ms = ms; self.createdAt = createdAt
    }
}

struct AgentStepEvent: Identifiable, Equatable {
    let id: UUID
    var name: String
    var argsSummary: String
    var ok: Bool
    var detail: String
    var ms: Int
    init(id: UUID = UUID(), name: String, argsSummary: String, ok: Bool, detail: String, ms: Int) {
        self.id = id; self.name = name; self.argsSummary = argsSummary
        self.ok = ok; self.detail = detail; self.ms = ms
    }
}

struct AgentProviderConfig: Equatable {
    var baseURL: String
    var model: String
    /// Key lives in Keychain; this flag only mirrors presence.
    var hasKey: Bool
}

enum AgentKeychain {
    static let service = "com.ky.superworkbench.dev.global-agent"
    static let account = "openai-compatible-api-key"

    static func saveKey(_ key: String) {
        let data = Data(key.utf8)
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(q as CFDictionary)
        var add = q
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func loadKey() -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let st = SecItemCopyMatching(q as CFDictionary, &out)
        guard st == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteKey() {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(q as CFDictionary)
    }
}
