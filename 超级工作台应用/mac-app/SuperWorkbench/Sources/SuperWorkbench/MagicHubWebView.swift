import SwiftUI
import WebKit

struct MagicHubWebView: NSViewRepresentable {
    @EnvironmentObject var store: WorkspaceStore

    func makeCoordinator() -> Coordinator {
        Coordinator(repoRoot: store.repoRoot)
    }

    func makeNSView(context: Context) -> WKWebView {
        let coord = context.coordinator
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
            // Fallback: load from Sources path next to repo (dev / unpackaged)
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
        coord.loadMagicHub()
        return wv
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Keep instance; reload only if dist path changed
        context.coordinator.ensureLoaded()
    }

    final class Coordinator: NSObject {
        let bridge: MagicHubBridge
        let repoRoot: URL
        weak var webView: WKWebView?
        private var didLoad = false

        init(repoRoot: URL) {
            self.repoRoot = repoRoot
            self.bridge = MagicHubBridge(repoRoot: repoRoot)
        }

        func loadMagicHub() {
            ensureLoaded(force: true)
        }

        func ensureLoaded(force: Bool = false) {
            guard force || !didLoad, let webView else { return }
            let dist = repoRoot.appendingPathComponent("超级工作台应用/app/magichub/index.html")
            let alt = repoRoot.appendingPathComponent("超级工作台应用/crm-magichub/dist/index.html")
            let index = FileManager.default.fileExists(atPath: dist.path) ? dist : alt
            guard FileManager.default.fileExists(atPath: index.path) else {
                let html = """
                <html><body style='font-family:-apple-system;padding:40px;background:#f5f5f7;color:#333'>
                <h2>MagicHub 尚未构建</h2>
                <p>请在 <code>超级工作台应用/crm-magichub</code> 执行 <code>npm run build</code>，
                并将 dist 同步到 <code>超级工作台应用/app/magichub</code>。</p>
                </body></html>
                """
                webView.loadHTMLString(html, baseURL: nil)
                return
            }
            // Allow read access to 超级工作台应用 so private/crm + public assets resolve
            let access = repoRoot.appendingPathComponent("超级工作台应用")
            var url = index
            if let tab = UserDefaults.standard.string(forKey: "sw.mhTab"), !tab.isEmpty,
               var comps = URLComponents(url: index, resolvingAgainstBaseURL: false) {
                comps.queryItems = [URLQueryItem(name: "tab", value: tab)]
                if let u = comps.url { url = u }
            }
            webView.loadFileURL(url, allowingReadAccessTo: access)
            didLoad = true
        }
    }
}

/// Chrome for 外贸工作台: keep segmented switcher, embed full MagicHub below.
struct TradeMagicHubHost: View {
    @EnvironmentObject var store: WorkspaceStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Text("外贸工作台")
                    .font(.system(size: 22, weight: .bold))
                workbenchSegment
                Spacer()
                Text("MagicHub 完整内嵌 · 数据仅本地 private/crm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.92))
            .overlay(alignment: .bottom) { Divider() }

            MagicHubWebView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(SWTheme.pageBg)
    }

    @ViewBuilder
    private var workbenchSegment: some View {
        let items = store.workbenches
        if items.count > 1 {
            HStack(spacing: 0) {
                ForEach(items) { wb in
                    Button {
                        store.switchWorkbench(wb.id)
                    } label: {
                        Text(wb.name)
                            .font(.system(size: 13, weight: store.activeWorkbenchId == wb.id ? .semibold : .regular))
                            .foregroundStyle(store.activeWorkbenchId == wb.id ? Color.white : Color.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(store.activeWorkbenchId == wb.id ? Color.accentColor : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
