import Foundation
import AppKit
import WebKit

/// Replaces Electron IPC for MagicHub running inside WKWebView.
/// Settings and mutable CRM data live under data/private/crm/ (gitignored).
final class MagicHubBridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    let repoRoot: URL
    private var secureMode: Bool = false

    init(repoRoot: URL) {
        self.repoRoot = repoRoot
        super.init()
    }

    private var settingsDir: URL {
        repoRoot.appendingPathComponent("超级工作台应用/data/private/crm/settings")
    }

    private var privateCrmRoot: URL {
        repoRoot.appendingPathComponent("超级工作台应用/data/private/crm")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "swMagicHub",
              let body = message.body as? [String: Any],
              let id = body["id"] as? String,
              let method = body["method"] as? String else { return }
        let args = body["args"] as? [Any] ?? []
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.dispatch(method: method, args: args)
            DispatchQueue.main.async {
                self.reply(id: id, result: result)
            }
        }
    }

    private func reply(id: String, result: (ok: Bool, payload: Any?, error: String?)) {
        guard let webView else { return }
        let err = (result.error ?? "")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        let okLit = result.ok ? "true" : "false"

        if let payload = result.payload,
           JSONSerialization.isValidJSONObject(payload),
           let data = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            // Large CRM payloads (leads ~13MB) cannot go through evaluateJavaScript; fetch via file URL.
            if data.count > 80_000 {
                let out = settingsDir.appendingPathComponent("_bridge_reply_\(id).json")
                try? FileManager.default.createDirectory(at: settingsDir, withIntermediateDirectories: true)
                try? data.write(to: out, options: .atomic)
                let fileURL = out.absoluteString
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "'", with: "\\'")
                let js = """
                fetch('\(fileURL)').then(function(r){return r.json()}).then(function(d){
                  window.__swBridgeResolve && window.__swBridgeResolve('\(id)', \(okLit), d, '');
                }).catch(function(e){
                  window.__swBridgeResolve && window.__swBridgeResolve('\(id)', false, null, String(e));
                });
                """
                webView.evaluateJavaScript(js, completionHandler: nil)
                return
            }
            if let s = String(data: data, encoding: .utf8) {
                let js = "window.__swBridgeResolve && window.__swBridgeResolve('\(id)', \(okLit), \(s), '\(err)');"
                webView.evaluateJavaScript(js, completionHandler: nil)
                return
            }
        }
        let js = "window.__swBridgeResolve && window.__swBridgeResolve('\(id)', \(okLit), null, '\(err)');"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func dispatch(method: String, args: [Any]) -> (Bool, Any?, String?) {
        switch method {
        case "get-secure-mode":
            return (true, ["secure": secureMode], nil)
        case "open-path":
            guard let path = args.first as? String else { return (false, nil, "missing path") }
            return openPath(path)
        case "scan-directory":
            guard let path = args.first as? String else { return (false, nil, "missing path") }
            return scanDirectory(path)
        case "save-settings":
            guard args.count >= 2, let key = args[0] as? String else { return (false, nil, "bad args") }
            return saveSettings(key: key, data: args[1])
        case "load-settings":
            guard let key = args.first as? String else { return (false, nil, "missing key") }
            return loadSettings(key: key)
        case "read-file":
            guard let path = args.first as? String else { return (false, nil, "missing path") }
            return readFile(path)
        case "write-file":
            guard args.count >= 2, let path = args[0] as? String, let content = args[1] as? String else {
                return (false, nil, "bad args")
            }
            return writeFile(path: path, content: content)
        case "select-local-zip-and-update":
            // Hot-update of Electron .app is not applicable inside Super Workbench.
            // Surface a clear result so MagicHub UI can show a message.
            return (true, [
                "success": false,
                "error": "工作台内嵌模式下请用 git pull + 重建 Mac 应用更新；不支持 ZIP 热更新。"
            ], nil)
        default:
            return (false, nil, "unknown method \(method)")
        }
    }

    private func ensureSettingsDir() throws {
        try FileManager.default.createDirectory(at: settingsDir, withIntermediateDirectories: true)
    }

    /// NSJSONSerialization throws ObjC exceptions (not Swift Error) on invalid graphs —
    /// that SIGABRTs the whole app (prod crash 2026-10-30 02:26). Always validate/sanitize first.
    private func saveSettings(key: String, data: Any) -> (Bool, Any?, String?) {
        let safe = Self.jsonSafe(data)
        guard JSONSerialization.isValidJSONObject(safe) else {
            return (false, ["success": false, "error": "settings payload is not JSON-serializable"], "invalid JSON object for key \(key)")
        }
        do {
            try ensureSettingsDir()
            let file = settingsDir.appendingPathComponent("\(key).json")
            let tmp = settingsDir.appendingPathComponent("\(key).json.tmp")
            let json = try JSONSerialization.data(withJSONObject: safe, options: [.prettyPrinted, .sortedKeys])
            try json.write(to: tmp, options: .atomic)
            if FileManager.default.fileExists(atPath: file.path) {
                _ = try? FileManager.default.removeItem(at: file)
            }
            try FileManager.default.moveItem(at: tmp, to: file)
            let bak = settingsDir.appendingPathComponent("\(key).json.bak")
            try? FileManager.default.removeItem(at: bak)
            try? FileManager.default.copyItem(at: file, to: bak)
            return (true, ["success": true], nil)
        } catch {
            return (false, ["success": false, "error": error.localizedDescription], error.localizedDescription)
        }
    }

    /// Convert WKScriptMessage / JS values into JSONSerialization-safe trees.
    private static func jsonSafe(_ value: Any) -> Any {
        switch value {
        case is NSNull:
            return NSNull()
        case let n as NSNumber:
            return n
        case let s as String:
            return s
        case let d as [String: Any]:
            return d.mapValues { jsonSafe($0) }
        case let d as NSDictionary:
            var out: [String: Any] = [:]
            for (k, v) in d {
                guard let ks = k as? String else { continue }
                out[ks] = jsonSafe(v)
            }
            return out
        case let a as [Any]:
            return a.map { jsonSafe($0) }
        case let a as NSArray:
            return a.map { jsonSafe($0) }
        case let b as Bool:
            return b
        case let i as Int:
            return i
        case let d as Double:
            return d
        default:
            return String(describing: value)
        }
    }

    private func loadSettings(key: String) -> (Bool, Any?, String?) {
        // First-run seed for leads from private CRM
        let file = settingsDir.appendingPathComponent("\(key).json")
        let fm = FileManager.default
        if !fm.fileExists(atPath: file.path) {
            if key == "magichub_leads" {
                let seed = privateCrmRoot.appendingPathComponent("leads/leads_seed.json")
                if let data = try? Data(contentsOf: seed),
                   let obj = try? JSONSerialization.jsonObject(with: data) {
                    _ = saveSettings(key: key, data: obj)
                }
            } else if key == "magichub_products" {
                let seed = privateCrmRoot.appendingPathComponent("products/products_imported.json")
                if let data = try? Data(contentsOf: seed),
                   let obj = try? JSONSerialization.jsonObject(with: data) {
                    _ = saveSettings(key: key, data: obj)
                }
            }
        }
        if !fm.fileExists(atPath: file.path) {
            return (true, ["success": true, "data": NSNull()], nil)
        }
        do {
            let data = try Data(contentsOf: file)
            let obj = try JSONSerialization.jsonObject(with: data)
            return (true, ["success": true, "data": obj], nil)
        } catch {
            let bak = settingsDir.appendingPathComponent("\(key).json.bak")
            if let data = try? Data(contentsOf: bak),
               let obj = try? JSONSerialization.jsonObject(with: data) {
                return (true, ["success": true, "data": obj], nil)
            }
            return (false, ["success": false, "error": error.localizedDescription], error.localizedDescription)
        }
    }

    private func openPath(_ path: String) -> (Bool, Any?, String?) {
        var url = URL(fileURLWithPath: path)
        if path.hasPrefix("./") || !path.hasPrefix("/") {
            url = privateCrmRoot.appendingPathComponent(path.replacingOccurrences(of: "./", with: ""))
        }
        // Also try public magichub dist / crm-magichub/public
        if !FileManager.default.fileExists(atPath: url.path) {
            let alt = repoRoot.appendingPathComponent("超级工作台应用/crm-magichub/public").appendingPathComponent((path as NSString).lastPathComponent)
            if FileManager.default.fileExists(atPath: alt.path) { url = alt }
            let pdf = privateCrmRoot.appendingPathComponent("pdfs/originals").appendingPathComponent((path as NSString).lastPathComponent)
            if FileManager.default.fileExists(atPath: pdf.path) { url = pdf }
        }
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
            NSWorkspace.shared.open(url)
            return (true, ["success": true], nil)
        } catch {
            return (false, ["success": false, "error": error.localizedDescription], error.localizedDescription)
        }
    }

    private func scanDirectory(_ path: String) -> (Bool, Any?, String?) {
        var dir = URL(fileURLWithPath: path)
        if !FileManager.default.fileExists(atPath: dir.path) {
            // Map MagicHub external_reports to private or crm-magichub/public/external_reports
            let alt = repoRoot.appendingPathComponent("超级工作台应用/crm-magichub/public/external_reports")
            if FileManager.default.fileExists(atPath: alt.path) { dir = alt }
            else {
                let priv = privateCrmRoot.appendingPathComponent("derived/external_reports")
                try? FileManager.default.createDirectory(at: priv, withIntermediateDirectories: true)
                dir = priv
            }
        }
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else {
            return (true, ["success": true, "files": []], nil)
        }
        let allowed = Set(["pdf", "docx", "xlsx", "md", "html", "json"])
        var out: [[String: Any]] = []
        for f in files {
            let ext = (f as NSString).pathExtension.lowercased()
            guard allowed.contains(ext) else { continue }
            let full = dir.appendingPathComponent(f)
            let vals = try? full.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            out.append([
                "name": f,
                "sizeBytes": vals?.fileSize ?? 0,
                "modifiedTime": ISO8601DateFormatter().string(from: vals?.contentModificationDate ?? Date()),
                "filePath": full.path
            ])
        }
        return (true, ["success": true, "files": out], nil)
    }

    private func readFile(_ path: String) -> (Bool, Any?, String?) {
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return (false, ["success": false, "error": "文件不存在"], "文件不存在")
        }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return (true, ["success": true, "content": content], nil)
        } catch {
            return (false, ["success": false, "error": error.localizedDescription], error.localizedDescription)
        }
    }

    private func writeFile(path: String, content: String) -> (Bool, Any?, String?) {
        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
            return (true, ["success": true], nil)
        } catch {
            return (false, ["success": false, "error": error.localizedDescription], error.localizedDescription)
        }
    }

    func setSecureMode(_ on: Bool) {
        secureMode = on
    }
}
