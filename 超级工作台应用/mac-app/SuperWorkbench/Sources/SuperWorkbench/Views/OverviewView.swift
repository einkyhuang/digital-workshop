import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: WorkspaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let err = store.loadError {
                Text(err).foregroundStyle(.red).padding().swCard()
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                MetricCard(value: "\(store.data.bots.count)", label: "数字员工", detail: "当前名册")
                MetricCard(value: "\(store.data.tasks.filter { $0.status == "进行中" }.count)", label: "进行中", detail: "看板统计")
                MetricCard(value: "\(store.data.bots.filter { $0.lastDelivery != "暂无" }.count)", label: "本周交付", detail: "有交付记录")
                MetricCard(value: "\(store.data.groups.count)", label: "群聊数", detail: "已建协作群")
            }

            Text("员工速览").font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                ForEach(store.filteredBots) { bot in
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
                    .swCard()
                }
            }
            Spacer(minLength: 80)
        }
    }
}
