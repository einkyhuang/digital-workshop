import SwiftUI

@main
struct SuperWorkbenchApp: App {
    @StateObject private var store = WorkspaceStore()

    var body: some Scene {
        WindowGroup("超级工作台") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1100, minHeight: 720)
                .onAppear { store.load() }
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
}
