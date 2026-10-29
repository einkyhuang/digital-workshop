import SwiftUI
import AppKit

@main
struct SuperWorkbenchApp: App {
    @StateObject private var store = WorkspaceStore()

    var body: some Scene {
        WindowGroup("超级工作台") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1100, minHeight: 720)
                .onAppear {
                    store.load()
                    Self.ensureMainWindowOnScreen()
                }
        }
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("工作台") {
                Button("重新加载数据") { store.load() }
                    .keyboardShortcut("r", modifiers: [.command])
                Button("同步到 GitHub") { store.syncGit() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }

    /// Multi-monitor / saved frame can park the window off-screen (y negative)
    /// so the Dock icon "opens" but nothing visible — clamp onto the active screen.
    private static func ensureMainWindowOnScreen() {
        DispatchQueue.main.async {
            guard let win = NSApp.windows.first(where: { $0.isVisible || $0.isMainWindow }) ?? NSApp.windows.first else { return }
            let screenFrame = (win.screen ?? NSScreen.main)?.visibleFrame ?? .zero
            guard screenFrame.width > 0, screenFrame.height > 0 else { return }
            var f = win.frame
            let minVisible: CGFloat = 80
            let intersects =
                f.maxX > screenFrame.minX + minVisible &&
                f.minX < screenFrame.maxX - minVisible &&
                f.maxY > screenFrame.minY + minVisible &&
                f.minY < screenFrame.maxY - minVisible
            if !intersects || f.width < 900 || f.height < 600 {
                let w = min(max(f.width, 1280), screenFrame.width - 40)
                let h = min(max(f.height, 820), screenFrame.height - 40)
                f.size = NSSize(width: w, height: h)
                f.origin = NSPoint(
                    x: screenFrame.midX - w / 2,
                    y: screenFrame.midY - h / 2
                )
                win.setFrame(f, display: true)
            }
        }
    }
}
