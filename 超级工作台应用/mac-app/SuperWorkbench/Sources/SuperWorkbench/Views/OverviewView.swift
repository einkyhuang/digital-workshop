import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: WorkspaceStore

    private var groupOrder: [String] {
        store.data.groupsOrder ?? ["网站项目","服装外贸","运营管理","战略决策","视觉设计","短剧组","外贸营销","个人成长","内容营销","管理中枢"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let err = store.loadError {
                Text(err).foregroundStyle(.red).padding().swCard()
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                MetricCard(value: "\(store.data.bots.count)", label: "数字员工", detail: "当前名册")
                MetricCard(value: "\(store.data.tasks.filter { $0.status == "进行中" }.count)", label: "进行中", detail: "看板统计")
                MetricCard(value: "\(store.data.bots.filter { $0.lastDelivery != "暂无" }.count)", label: "本周交付", detail: "有交付记录")
                MetricCard(value: "\(groupOrder.count)", label: "业务分组", detail: "协作编组")
            }

            ForEach(groupOrder, id: \.self) { g in
                let items = store.filteredBots.filter { $0.belongs(to: g) }
                if !items.isEmpty {
                    HStack {
                        Text(g).font(.headline)
                        Text("\(items.count)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.black.opacity(0.06)).clipShape(Capsule())
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                        ForEach(items) { bot in
                            Button {
                                store.selectedBotId = bot.id
                                store.selectedSection = .roster
                                store.showingBotDetail = true
                            } label: {
                                EmployeeCard(bot: bot, compact: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Text("开放任务").font(.headline)
            VStack(spacing: 8) {
                ForEach(store.filteredTasks.prefix(5)) { t in
                    HStack {
                        Circle().fill(SWTheme.columnColor(TaskColumn(rawValue: t.status) ?? .todo)).frame(width: 8, height: 8)
                        Text(t.title).font(.subheadline.weight(.medium))
                        Spacer()
                        TagChip(text: t.status, color: SWTheme.columnColor(TaskColumn(rawValue: t.status) ?? .todo))
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))
                }
            }
            Spacer(minLength: 80)
        }
    }
}
