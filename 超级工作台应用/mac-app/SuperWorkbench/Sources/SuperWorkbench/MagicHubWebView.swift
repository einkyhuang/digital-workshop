import SwiftUI
import WebKit

struct MagicHubWebView: NSViewRepresentable {
    @EnvironmentObject var store: WorkspaceStore

    func makeCoordinator() -> Coordinator {
        Coordinator(repoRoot: store.repoRoot)
    }

    func makeNSView(context: Context) -> WKWebView {
        let coord = context.coordinator
        coord.store = store
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        let uc = config.userContentController
        uc.removeScriptMessageHandler(forName: "swMagicHub")
        uc.add(coord.bridge, name: "swMagicHub")
        if let jsURL = Bundle.main.url(forResource: "magichub-bridge", withExtension: "js"),
           let js = try? String(contentsOf: jsURL, encoding: .utf8) {
            uc.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        } else {
            let fallback = store.repoRoot
                .appendingPathComponent("超级工作台应用/mac-app/SuperWorkbench/Sources/SuperWorkbench/magichub-bridge.js")
            if let js = try? String(contentsOf: fallback, encoding: .utf8) {
                uc.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))
            }
        }
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        coord.bridge.webView = wv
        coord.webView = wv
        coord.loadMagicHub(tab: store.magicHubTab)
        coord.startObserving()
        return wv
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.store = store
        context.coordinator.ensureLoaded()
        context.coordinator.pushTabIfNeeded(store.magicHubTab)
    }

    final class Coordinator: NSObject {
        let bridge: MagicHubBridge
        let repoRoot: URL
        weak var webView: WKWebView?
        weak var store: WorkspaceStore?
        private var didLoad = false
        private var lastPushedTab: String?
        private var observers: [NSObjectProtocol] = []

        init(repoRoot: URL) {
            self.repoRoot = repoRoot
            self.bridge = MagicHubBridge(repoRoot: repoRoot)
        }

        deinit {
            observers.forEach { NotificationCenter.default.removeObserver($0) }
        }

        func startObserving() {
            guard observers.isEmpty else { return }
            let push = NotificationCenter.default.addObserver(
                forName: .swMagicHubPushTab,
                object: nil,
                queue: .main
            ) { [weak self] note in
                let tab = (note.userInfo?["tab"] as? String) ?? ""
                self?.pushTabIfNeeded(tab, force: true)
            }
            let changed = NotificationCenter.default.addObserver(
                forName: .swMagicHubTabChanged,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let tab = note.userInfo?["tab"] as? String, !tab.isEmpty else { return }
                UserDefaults.standard.set(tab, forKey: "sw.mhTab")
                self?.lastPushedTab = tab
                Task { @MainActor in
                    self?.store?.magicHubTab = tab
                }
            }
            observers = [push, changed]
        }

        func loadMagicHub(tab: String) {
            ensureLoaded(force: true, tab: tab)
        }

        func ensureLoaded(force: Bool = false, tab: String? = nil) {
            guard force || !didLoad, let webView else { return }
            let dist = repoRoot.appendingPathComponent("超级工作台应用/app/magichub/index.html")
            let alt = repoRoot.appendingPathComponent("超级工作台应用/crm-magichub/dist/index.html")
            let index = FileManager.default.fileExists(atPath: dist.path) ? dist : alt
            guard FileManager.default.fileExists(atPath: index.path) else {
                let html = """
                <html><body style='font-family:-apple-system;padding:40px;background:#f5f5f7;color:#333'>
                <h2>MagicHub 尚未构建</h2>
                <p>请在 <code>超级工作台应用/crm-magichub</code> 执行 <code>./build-for-workbench.sh</code>，
                并将 dist 同步到 <code>超级工作台应用/app/magichub</code>。</p>
                </body></html>
                """
                webView.loadHTMLString(html, baseURL: nil)
                return
            }
            let access = repoRoot.appendingPathComponent("超级工作台应用")
            var url = index
            let tabId: String = {
                if let tab, !tab.isEmpty { return tab }
                if let s = UserDefaults.standard.string(forKey: "sw.mhTab"), !s.isEmpty { return s }
                return "dashboard"
            }()
            if var comps = URLComponents(url: index, resolvingAgainstBaseURL: false) {
                comps.queryItems = [
                    URLQueryItem(name: "embed", value: "1"),
                    URLQueryItem(name: "tab", value: tabId)
                ]
                if let u = comps.url { url = u }
            }
            webView.loadFileURL(url, allowingReadAccessTo: access)
            didLoad = true
            lastPushedTab = tabId
        }

        func pushTabIfNeeded(_ tab: String, force: Bool = false) {
            guard !tab.isEmpty, let webView else { return }
            if !force, lastPushedTab == tab { return }
            lastPushedTab = tab
            let escaped = tab
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let js = "window.__swSetTab && window.__swSetTab('\(escaped)');"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

/// Chrome for 外贸工作台: MagicHub fills main pane; nav lives in outer SidebarView.
struct TradeMagicHubHost: View {
    @EnvironmentObject var store: WorkspaceStore

    var body: some View {
        MagicHubWebView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SWTheme.pageBg)
    }
}
