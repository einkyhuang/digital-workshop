import SwiftUI
import AppKit

@main
struct SuperWorkbenchApp: App {
    @StateObject private var store = WorkspaceStore()

    init() {
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        if let bundle = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removeObject(forKey: "NSWindow Frame \(bundle)")
        }
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.contains("NSWindow Frame") || key.contains("SuperWorkbench") || key.contains("超级工作台") {
            defaults.removeObject(forKey: key)
        }
    }

    var body: some Scene {
        WindowGroup("超级工作台") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1100, minHeight: 720)
                .background(WindowAccessor())
                .onAppear {
                    Self.forceMainWindowOnScreen()
                    for delay in [0.05, 0.2, 0.5, 1.0, 2.0] as [Double] {
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            Self.forceMainWindowOnScreen()
                        }
                    }
                    store.loadAsync()
                }
        }
        .defaultSize(width: 1280, height: 820)
        .defaultPosition(.center)
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

    static func targetScreen() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        if let s = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
            return s
        }
        return NSScreen.main ?? NSScreen.screens[0]
    }

    /// Always re-center onto the screen under the mouse (or main).
    static func forceMainWindowOnScreen() {
        let apply: () -> Void = {
            let windows = NSApp.windows.filter {
                $0.contentView != nil && !$0.className.contains("NSStatusBar") && $0.canBecomeMain
            }
            let all = windows.isEmpty ? NSApp.windows.filter { $0.contentView != nil } : windows
            guard let win = all.first(where: { $0.isMainWindow || $0.isKeyWindow }) ?? all.first else { return }
            NSApp.activate(ignoringOtherApps: true)
            win.isRestorable = false
            win.makeKeyAndOrderFront(nil)
            let screenFrame = targetScreen().visibleFrame
            guard screenFrame.width > 0, screenFrame.height > 0 else { return }
            let w = min(1280, screenFrame.width - 40)
            let h = min(820, screenFrame.height - 40)
            let f = NSRect(
                x: screenFrame.midX - w / 2,
                y: screenFrame.midY - h / 2,
                width: w,
                height: h
            )
            win.setFrame(f, display: true, animate: false)
            win.orderFrontRegardless()
        }
        if Thread.isMainThread { apply() } else { DispatchQueue.main.async(execute: apply) }
    }
}

private struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.isRestorable = false
            SuperWorkbenchApp.forceMainWindowOnScreen()
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.isRestorable = false
            SuperWorkbenchApp.forceMainWindowOnScreen()
        }
    }
}
