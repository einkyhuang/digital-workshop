import Foundation
import Security

/// Global AI provider store shared by 超级工作台 (Swift Agent) and 外贸工作台 (MagicHub WKWebView).
/// Metadata + keys live under Application Support (outside the git repo). Keys are also mirrored
/// into the macOS Keychain per provider id for the native Agent panel.
enum SharedModelStore {
    static let fileName = "models.json"
    static let settingsKey = "magichub_ai_providers" // Magichub wire key (array of providers)
    static let globalDocKey = "sw_global_models"     // full document
    static let keychainService = "com.ky.superworkbench.models"

    struct Document {
        var version: Int
        var activeProviderId: String
        var providers: [[String: Any]]
        var updatedAt: String

        func asDictionary() -> [String: Any] {
            [
                "version": version,
                "activeProviderId": activeProviderId,
                "providers": providers,
                "updatedAt": updatedAt
            ]
        }

        static func from(_ any: Any?) -> Document? {
            guard let d = any as? [String: Any] else { return nil }
            let providers = (d["providers"] as? [[String: Any]]) ?? []
            guard !providers.isEmpty || d["version"] != nil else { return nil }
            return Document(
                version: (d["version"] as? Int) ?? 1,
                activeProviderId: (d["activeProviderId"] as? String) ?? "",
                providers: providers,
                updatedAt: (d["updatedAt"] as? String) ?? ""
            )
        }
    }

    static var supportDir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("超级工作台", isDirectory: true)
    }

    static var modelsFile: URL {
        supportDir.appendingPathComponent(fileName)
    }

    // MARK: - Public API

    /// Load providers array (Magichub shape), migrating legacy sources when needed.
    static func loadProviders(repoRoot: URL?) -> [[String: Any]] {
        let doc = loadDocument(repoRoot: repoRoot)
        return hydrateKeys(doc.providers)
    }

    static func loadDocument(repoRoot: URL?) -> Document {
        if let existing = readFileDocument() {
            return existing
        }
        let migrated = migrate(repoRoot: repoRoot)
        _ = writeDocument(migrated, stripKeysToKeychain: true)
        return migrated
    }

    /// Persist Magichub providers array into the global store.
    @discardableResult
    static func saveProviders(_ providers: [[String: Any]], activeProviderId: String? = nil, repoRoot: URL? = nil) -> (Bool, String?) {
        var active = activeProviderId ?? ""
        if active.isEmpty {
            active = (providers.first { ($0["status"] as? Bool) == true }?["id"] as? String)
                ?? (providers.first?["id"] as? String)
                ?? ""
        }
        let doc = Document(
            version: 1,
            activeProviderId: active,
            providers: providers,
            updatedAt: isoNow()
        )
        let result = writeDocument(doc, stripKeysToKeychain: true)
        // Legacy mirror under private CRM settings (gitignored) so old importers still see a file.
        if let repoRoot {
            mirrorLegacyMagichubFile(providers: providers, repoRoot: repoRoot)
        }
        // Keep UserDefaults active endpoint in sync for older Agent code paths.
        if let p = providers.first(where: { ($0["id"] as? String) == active }) ?? providers.first {
            let base = (p["baseUrl"] as? String) ?? (p["baseURL"] as? String) ?? ""
            let model = (p["model"] as? String) ?? (p["defaultModel"] as? String) ?? ""
            if !base.isEmpty { UserDefaults.standard.set(base, forKey: "sw.agent.baseURL") }
            if !model.isEmpty { UserDefaults.standard.set(model, forKey: "sw.agent.model") }
        }
        return result
    }

    static func saveDocument(_ doc: Document, repoRoot: URL?) -> (Bool, String?) {
        let r = writeDocument(doc, stripKeysToKeychain: true)
        if let repoRoot {
            mirrorLegacyMagichubFile(providers: doc.providers, repoRoot: repoRoot)
        }
        return r
    }

    // MARK: - Keychain (per provider)

    static func saveKey(providerId: String, key: String) {
        let account = "provider:" + providerId
        let data = Data(key.utf8)
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(q as CFDictionary)
        guard !key.isEmpty else { return }
        var add = q
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func loadKey(providerId: String) -> String? {
        let account = "provider:" + providerId
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let st = SecItemCopyMatching(q as CFDictionary, &out)
        guard st == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteKey(providerId: String) {
        let account = "provider:" + providerId
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(q as CFDictionary)
    }

    // MARK: - File IO

    private static func ensureDir() throws {
        try FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
    }

    private static func readFileDocument() -> Document? {
        let url = modelsFile
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let doc = Document.from(obj) else { return nil }
        return doc
    }

    @discardableResult
    private static func writeDocument(_ doc: Document, stripKeysToKeychain: Bool) -> (Bool, String?) {
        do {
            try ensureDir()
            var providers = doc.providers
            if stripKeysToKeychain {
                providers = providers.map { raw in
                    var p = raw
                    let id = (p["id"] as? String) ?? ""
                    if let key = p["apiKey"] as? String, !key.isEmpty, !id.isEmpty {
                        saveKey(providerId: id, key: key)
                        // Keep apiKey in the App Support file too so Electron / LAN / Magichub UI
                        // can read it without Keychain. File is outside the git repo.
                        p["hasKey"] = true
                    } else if !id.isEmpty, let k = loadKey(providerId: id), !k.isEmpty {
                        p["apiKey"] = k
                        p["hasKey"] = true
                    }
                    if p["type"] == nil { p["type"] = "openai-compatible" }
                    return p
                }
            }
            let out = Document(
                version: doc.version,
                activeProviderId: doc.activeProviderId,
                providers: providers,
                updatedAt: isoNow()
            )
            let dict = out.asDictionary()
            guard JSONSerialization.isValidJSONObject(dict) else {
                return (false, "models document not JSON-serializable")
            }
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            let tmp = modelsFile.appendingPathExtension("tmp")
            try data.write(to: tmp, options: .atomic)
            if FileManager.default.fileExists(atPath: modelsFile.path) {
                _ = try? FileManager.default.removeItem(at: modelsFile)
            }
            try FileManager.default.moveItem(at: tmp, to: modelsFile)
            let bak = modelsFile.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: bak)
            try? FileManager.default.copyItem(at: modelsFile, to: bak)
            return (true, nil)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private static func hydrateKeys(_ providers: [[String: Any]]) -> [[String: Any]] {
        providers.map { raw in
            var p = raw
            let id = (p["id"] as? String) ?? ""
            let existing = (p["apiKey"] as? String) ?? ""
            if existing.isEmpty, !id.isEmpty, let k = loadKey(providerId: id), !k.isEmpty {
                p["apiKey"] = k
                p["hasKey"] = true
            }
            if p["type"] == nil { p["type"] = "openai-compatible" }
            return p
        }
    }

    private static func mirrorLegacyMagichubFile(providers: [[String: Any]], repoRoot: URL) {
        let dir = repoRoot.appendingPathComponent("超级工作台应用/data/private/crm/settings")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("magichub_ai_providers.json")
        // Store without insisting on keys in the gitignored mirror (still may include keys —
        // private/ is gitignored). Prefer App Support as source of truth.
        if JSONSerialization.isValidJSONObject(providers),
           let data = try? JSONSerialization.data(withJSONObject: providers, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: file, options: .atomic)
        }
    }

    // MARK: - Migration

    private static func migrate(repoRoot: URL?) -> Document {
        var providers: [[String: Any]] = []

        // 1) Legacy Magichub private settings file
        if let repoRoot {
            let url = repoRoot.appendingPathComponent("超级工作台应用/data/private/crm/settings/magichub_ai_providers.json")
            if let data = try? Data(contentsOf: url),
               let obj = try? JSONSerialization.jsonObject(with: data) {
                if let arr = obj as? [[String: Any]] {
                    providers = arr
                } else if let d = obj as? [String: Any] {
                    providers = (d["providers"] as? [[String: Any]]) ?? []
                }
            }
        }

        // 2) Ensure Qwen + common presets exist / merge by id
        providers = mergePresets(into: providers)

        // 3) UserDefaults active endpoint
        let udBase = UserDefaults.standard.string(forKey: "sw.agent.baseURL") ?? ""
        let udModel = UserDefaults.standard.string(forKey: "sw.agent.model") ?? ""
        let legacyKey = AgentKeychain.loadKey() ?? ""

        var activeId = ""
        if !udBase.isEmpty {
            if let idx = providers.firstIndex(where: {
                let b = ($0["baseUrl"] as? String) ?? ($0["baseURL"] as? String) ?? ""
                return b.contains(udBase) || udBase.contains(b) || b == udBase
            }) {
                activeId = (providers[idx]["id"] as? String) ?? ""
                if !udModel.isEmpty { providers[idx]["model"] = udModel }
            } else {
                // Custom endpoint from Super Workbench agent settings
                let custom: [String: Any] = [
                    "id": "sw-agent-legacy",
                    "name": "超级工作台 Agent",
                    "type": "openai-compatible",
                    "icon": "S",
                    "iconColor": "bg-slate-700",
                    "status": true,
                    "baseUrl": udBase.hasSuffix("/v1") || udBase.contains("/v1") ? udBase : udBase,
                    "apiKey": legacyKey,
                    "modelGroup": "custom",
                    "model": udModel.isEmpty ? AgentLLMClient.preferredDefaultModel : udModel,
                    "previewUrl": (udBase.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions")
                ]
                providers.insert(custom, at: 0)
                activeId = "sw-agent-legacy"
            }
        }

        // Attach legacy single Keychain key to active / deepseek / first enabled
        if !legacyKey.isEmpty {
            let target = activeId.isEmpty ? "deepseek" : activeId
            if let idx = providers.firstIndex(where: { ($0["id"] as? String) == target }) {
                let existing = (providers[idx]["apiKey"] as? String) ?? ""
                if existing.isEmpty {
                    providers[idx]["apiKey"] = legacyKey
                }
                saveKey(providerId: target, key: (providers[idx]["apiKey"] as? String) ?? legacyKey)
            } else if let idx = providers.firstIndex(where: { ($0["status"] as? Bool) == true }) {
                let id = (providers[idx]["id"] as? String) ?? "deepseek"
                let existing = (providers[idx]["apiKey"] as? String) ?? ""
                if existing.isEmpty { providers[idx]["apiKey"] = legacyKey }
                saveKey(providerId: id, key: (providers[idx]["apiKey"] as? String) ?? legacyKey)
                if activeId.isEmpty { activeId = id }
            }
        }

        if activeId.isEmpty {
            if let qwen = providers.first(where: { ($0["id"] as? String) == "qwen" && (($0["status"] as? Bool) ?? true) }) {
                activeId = (qwen["id"] as? String) ?? "qwen"
            } else {
                activeId = (providers.first { ($0["status"] as? Bool) == true }?["id"] as? String)
                    ?? (providers.first?["id"] as? String)
                    ?? "qwen"
            }
        }

        return Document(version: 1, activeProviderId: activeId, providers: providers, updatedAt: isoNow())
    }

    /// Built-in presets — Magichub defaults + Alibaba Qwen (DashScope OpenAI-compatible).
    static func defaultPresets() -> [[String: Any]] {
        [
            preset("apifree", "APIFree", "A", "bg-purple-600", false, "https://api.apifree.ai/agent/v1", "skywork-ai", "skywork-ai/skyclaw-v1"),
            preset("cloudflare", "Cloudflare", "C", "bg-orange-500", true, "https://api.cloudflare.com/client/v4", "workers-ai", "meta-llama/llama-3-8b-instruct"),
            preset("siliconflow", "硅基流动", "硅", "bg-indigo-600", true, "https://api.siliconflow.cn/v1", "deepseek", "deepseek-ai/DeepSeek-V3"),
            preset("gemini", "Gemini", "G", "bg-blue-500", true, "https://generativelanguage.googleapis.com/v1beta/openai", "google", "gemini-1.5-pro"),
            preset("alicoding", "阿里coding", "阿", "bg-blue-800", true, "https://api.alicoding.com/v1", "qwen", "qwen-turbo"),
            preset("qwen", "通义千问", "千", "bg-violet-600", true, "https://dashscope.aliyuncs.com/compatible-mode/v1", "qwen", "qwen3.8-max"),
            preset("bailian", "阿里云百炼", "百", "bg-blue-600", false, "https://dashscope.aliyuncs.com/compatible-mode/v1", "qwen", "qwen3.8-max"),
            preset("volcengine", "火山引擎", "火", "bg-blue-400", false, "https://ark.cn-beijing.volces.com/api/v3", "doubao", "doubao-pro"),
            preset("minimax", "MiniMax", "M", "bg-red-500", false, "https://api.minimaxi.com/v1", "abab", "abab6.5-chat"),
            preset("deepseek", "深度求索", "深", "bg-blue-700", true, "https://api.deepseek.com/v1", "deepseek", "deepseek-chat"),
            preset("zhipu", "智谱开放平台", "智", "bg-blue-900", false, "https://open.bigmodel.cn/api/paas/v4", "glm", "glm-4"),
            preset("openrouter", "OpenRouter", "O", "bg-purple-800", false, "https://openrouter.ai/api/v1", "openrouter", "meta-llama/llama-3-70b-instruct"),
            preset("cerebras", "Cerebras AI", "C", "bg-orange-600", false, "https://api.cerebras.ai/v1", "cerebras", "llama3.1-8b"),
            preset("nvidia", "英伟达", "英", "bg-green-600", false, "https://integrate.api.nvidia.com/v1", "nvidia", "meta/llama3-70b-instruct"),
            preset("vpsairobot", "vpsairobot", "V", "bg-green-500", false, "https://api.vpsairobot.com/v1", "custom", "vps-smart-v1"),
            preset("vercel", "Vercel AI Gateway", "▲", "bg-black", false, "https://gateway.ai.vercel.cloud/v1", "gateway", "openai/gpt-4o"),
            preset("qiniu", "七牛云 AI 推理", "七", "bg-blue-300", false, "https://api.qiniu.com/v1", "qiniu-ai", "qiniu-llama-3")
        ]
    }

    private static func preset(_ id: String, _ name: String, _ icon: String, _ color: String, _ on: Bool, _ base: String, _ group: String, _ model: String) -> [String: Any] {
        [
            "id": id,
            "name": name,
            "type": "openai-compatible",
            "icon": icon,
            "iconColor": color,
            "status": on,
            "baseUrl": base,
            "apiKey": "",
            "modelGroup": group,
            "model": model,
            "previewUrl": base.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions",
            "availableModels": [] as [String]
        ]
    }

    private static func mergePresets(into existing: [[String: Any]]) -> [[String: Any]] {
        let defaults = defaultPresets()
        if existing.isEmpty { return defaults }
        var byId: [String: [String: Any]] = [:]
        for p in defaults { if let id = p["id"] as? String { byId[id] = p } }
        for p in existing {
            guard let id = p["id"] as? String else { continue }
            var merged = byId[id] ?? [:]
            for (k, v) in p { merged[k] = v }
            if merged["type"] == nil { merged["type"] = "openai-compatible" }
            byId[id] = merged
        }
        // Preserve default order, then append unknown custom ids
        var out: [[String: Any]] = []
        var seen = Set<String>()
        for p in defaults {
            let id = p["id"] as! String
            out.append(byId[id] ?? p)
            seen.insert(id)
        }
        for p in existing {
            guard let id = p["id"] as? String, !seen.contains(id) else { continue }
            var c = p
            if c["type"] == nil { c["type"] = "openai-compatible" }
            out.append(c)
            seen.insert(id)
        }
        return out
    }

    private static func isoNow() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}
