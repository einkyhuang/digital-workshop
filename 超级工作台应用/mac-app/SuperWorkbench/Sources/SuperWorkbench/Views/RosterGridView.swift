import SwiftUI
import AppKit

private struct RosterWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 1200
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct RosterGridView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var groupFilter: String = "全部"
    @State private var contentWidth: CGFloat = 1200

    private var groupOrder: [String] {
        if let o = store.data.groupsOrder, !o.isEmpty { return o }
        return ["管理中枢","网站项目","服装外贸","运营管理","战略决策","视觉设计","短剧组","外贸营销","个人成长","内容营销"]
    }

    private var chips: [String] { ["全部"] + groupOrder }

    private var bots: [Bot] {
        let base = store.filteredBots
        if groupFilter == "全部" { return base }
        return base.filter { $0.belongs(to: groupFilter) }
    }

    private var visibleGroups: [(String, [Bot])] {
        if groupFilter != "全部" { return [(groupFilter, bots)] }
        return groupOrder.compactMap { g in
            let items = bots.filter { $0.belongs(to: g) }
            return items.isEmpty ? nil : (g, items)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { g in
                        let count = g == "全部" ? store.data.bots.count : store.data.bots.filter { $0.belongs(to: g) }.count
                        Button("\(g) \(count)") { groupFilter = g }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(groupFilter == g ? SWTheme.accent : Color.white)
                            .foregroundStyle(groupFilter == g ? Color.white : SWTheme.text)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(SWTheme.borderSoft))
                    }
                }
            }

            RosterGroupBoard(
                groups: visibleGroups.map { (title: $0.0, bots: $0.1) },
                cardWidth: SWTheme.Roster.cardMinWidth
            ) { bot in
                store.selectedBotId = bot.id
                store.showingBotDetail = true
            }
            // Keep layout aware of measured width (parity with OverviewView)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(contentWidth)

            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: RosterWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(RosterWidthKey.self) { contentWidth = max($0, 320) }
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
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(SWTheme.borderSoft))

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    labeled("职责", bot.duty)
                    labeled("工具 / 模型", bot.tools)
                    labeled("知识库", bot.knowledge)
                    labeled("技能", bot.skills)
                    labeled("记忆", bot.memory)
                    labeled("最近交付", bot.lastDelivery)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SWTheme.borderSoft))

                VStack(alignment: .leading, spacing: 12) {
                    Text("可编辑").font(.headline)
                    Picker("状态", selection: $bot.status) {
                        ForEach(["在线", "忙碌", "空闲"], id: \.self) { Text($0) }
                    }
                    HStack {
                        Text("进度 \(bot.progress)%")
                        Slider(value: Binding(get: { Double(bot.progress) }, set: { bot.progress = Int($0) }), in: 0...100)
                    }
                    TextField("OKR", text: $bot.okr)
                    TextField("周报", text: $bot.weekly, axis: .vertical).lineLimit(3...6)
                    Button("保存到 workspace.json") { store.updateBot(bot) }
                        .buttonStyle(.borderedProminent).tint(.black)
                }
                .padding(16)
                .frame(width: 340, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SWTheme.borderSoft))
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
