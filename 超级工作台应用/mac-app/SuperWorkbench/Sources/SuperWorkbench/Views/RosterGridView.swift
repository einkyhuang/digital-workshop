import SwiftUI
import AppKit

struct RosterGridView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var layerFilter: String = "全部"

    private var layers: [String] { ["全部", "幕僚室", "Studio执行层", "生活层"] }

    private var bots: [Bot] {
        let base = store.filteredBots
        if layerFilter == "全部" { return base }
        return base.filter { $0.layer == layerFilter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(layers, id: \.self) { layer in
                    Button(layer) { layerFilter = layer }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(layerFilter == layer ? Color.black : Color.white)
                        .foregroundStyle(layerFilter == layer ? Color.white : Color.primary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(SWTheme.border))
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                ForEach(bots) { bot in
                    Button {
                        store.selectedBotId = bot.id
                        store.showingBotDetail = true
                    } label: {
                        EmployeeCard(bot: bot, compact: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 80)
        }
    }
}

struct BotDetailView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State var bot: Bot

    var files: [URL] { store.listBotFiles(bot) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(SWTheme.layerColor(bot.layer).opacity(0.15)).frame(width: 72, height: 72)
                    Text(bot.emoji).font(.largeTitle)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(bot.role).foregroundStyle(.secondary)
                    HStack {
                        TagChip(text: bot.layer, color: SWTheme.layerColor(bot.layer))
                        HStack(spacing: 4) {
                            Circle().fill(SWTheme.statusColor(bot.status)).frame(width: 8, height: 8)
                            Text(bot.status).font(.caption)
                        }
                    }
                    Text("文件夹 bots/\(bot.folderName)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    store.revealBotFolder(bot)
                } label: {
                    Label("在 Finder 中显示", systemImage: "folder")
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .swCard()

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    labeled("职责", bot.duty)
                    labeled("工具", bot.tools)
                    labeled("知识库", bot.knowledge)
                    labeled("技能", bot.skills)
                    labeled("记忆", bot.memory)
                    labeled("测试用例", bot.testCases)
                    labeled("最近交付", bot.lastDelivery)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .swCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("可编辑").font(.headline)
                    Picker("状态", selection: $bot.status) {
                        ForEach(["在线", "忙碌", "空闲"], id: \.self) { Text($0) }
                    }
                    HStack {
                        Text("进度 \(bot.progress)%")
                        Slider(value: Binding(
                            get: { Double(bot.progress) },
                            set: { bot.progress = Int($0) }
                        ), in: 0...100, step: 1)
                    }
                    TextField("OKR", text: $bot.okr)
                    TextField("周报", text: $bot.weekly, axis: .vertical).lineLimit(3...6)
                    Button("保存到 workspace.json") {
                        store.updateBot(bot)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)

                    Divider()
                    Text("Bot 文件夹文件").font(.headline)
                    if files.isEmpty {
                        Text("暂无交付文件（忽略 .gitkeep）").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(files, id: \.path) { url in
                            HStack {
                                Image(systemName: "doc.text")
                                Text(shortPath(url)).font(.caption).lineLimit(1)
                                Spacer()
                                Button("打开") { NSWorkspace.shared.open(url) }
                                    .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(width: 340, alignment: .leading)
                .swCard()
            }
            Spacer(minLength: 80)
        }
        .onAppear { bot = store.bot(id: bot.id) ?? bot }
    }

    private func labeled(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(text).font(.subheadline)
        }
    }

    private func shortPath(_ url: URL) -> String {
        let root = store.botsRootURL.appendingPathComponent(bot.folderName).path
        return url.path.replacingOccurrences(of: root + "/", with: "")
    }
}
