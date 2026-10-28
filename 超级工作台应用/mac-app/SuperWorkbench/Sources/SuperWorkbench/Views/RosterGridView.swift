import SwiftUI
import AppKit

struct RosterGridView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var groupFilter: String = "全部"

    private var groupOrder: [String] {
        if let o = store.data.groupsOrder, !o.isEmpty { return o }
        return ["管理中枢","网站项目","服装外贸","运营管理","战略决策","视觉设计","外贸营销","个人成长","内容营销"]
    }

    private var chips: [String] { ["全部"] + groupOrder }

    private var bots: [Bot] {
        let base = store.filteredBots
        if groupFilter == "全部" { return base }
        return base.filter { $0.belongs(to: groupFilter) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { g in
                        let count = g == "全部" ? store.data.bots.count : store.data.bots.filter { $0.belongs(to: g) }.count
                        Button("\(g) \(count)") { groupFilter = g }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(groupFilter == g ? Color.black : Color.white)
                            .foregroundStyle(groupFilter == g ? Color.white : Color.primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.black.opacity(0.08)))
                    }
                }
            }

            if groupFilter == "全部" {
                ForEach(groupOrder, id: \.self) { g in
                    let items = bots.filter { $0.belongs(to: g) }
                    if !items.isEmpty {
                        section(g, items)
                    }
                }
            } else {
                section(groupFilter, bots)
            }
            Spacer(minLength: 80)
        }
    }

    private func section(_ title: String, _ items: [Bot]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Text("\(items.count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 14)], spacing: 14) {
                ForEach(items) { bot in
                    Button {
                        store.selectedBotId = bot.id
                        store.showingBotDetail = true
                    } label: {
                        EmployeeCard(bot: bot, compact: false)
                    }
                    .buttonStyle(.plain)
                }
            }
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
                Group {
                    if let img = NSImage(contentsOf: bot.avatarURL) {
                        Image(nsImage: img).resizable().scaledToFill()
                    } else {
                        Text(String(bot.name.prefix(1))).font(.largeTitle)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(radius: 4, y: 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(bot.displayCode) · \(bot.role)").foregroundStyle(.secondary)
                    HStack {
                        TagChip(text: bot.displayGroup, color: .blue)
                        TagChip(text: bot.layerShort, color: SWTheme.layerColor(bot.layer))
                        HStack(spacing: 4) {
                            Circle().fill(SWTheme.statusColor(bot.status)).frame(width: 8, height: 8)
                            Text(bot.status).font(.caption)
                        }
                    }
                    Text("bots/\(bot.folderName)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button { store.revealBotFolder(bot) } label: {
                    Label("在 Finder 中显示", systemImage: "folder")
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06)))

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    labeled("职责", bot.duty)
                    labeled("工具 / 模型", bot.tools)
                    labeled("知识库", bot.knowledge)
                    labeled("技能", bot.skills)
                    labeled("记忆", bot.memory)
                    labeled("测试用例", bot.testCases)
                    labeled("最近交付", bot.lastDelivery)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06)))

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
                    Button("保存到 workspace.json") { store.updateBot(bot) }
                        .buttonStyle(.borderedProminent).tint(.black)
                    Divider()
                    Text("Bot 文件夹文件").font(.headline)
                    if files.isEmpty {
                        Text("暂无交付文件").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(files, id: \.path) { url in
                            HStack {
                                Image(systemName: "doc.text")
                                Text(url.lastPathComponent).font(.caption).lineLimit(1)
                                Spacer()
                                Button("打开") { NSWorkspace.shared.open(url) }.buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(width: 340, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06)))
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
}
