import SwiftUI

struct TradeLeadsView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        TradeCountsPage(
            title: "客户与线索",
            subtitle: "聚合计数可上 Pages；客户名/金额仅 private",
            cards: [
                ("线索总数", store.tradeLeadsIndex?.counts?.leadsTotal),
                ("已分层优质", store.tradeLeadsIndex?.counts?.leadsQualified),
                ("客户档案", store.tradeLeadsIndex?.counts?.profiles),
            ],
            activity: store.tradeLeadsIndex?.latestActivity
        )
    }
}

struct TradePipelineView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        TradeCountsPage(
            title: "开发进度",
            subtitle: "进行中的背调 / 开发信 / 跟进（无客户名）",
            cards: [
                ("开发中", store.tradeLeadsIndex?.counts?.inProgressDev),
                ("员工（本台）", store.scopedBots.count),
                ("待办+进行中", store.scopedTasks.filter { $0.status == "进行中" || $0.status == "待办" }.count),
            ],
            activity: store.tradeLeadsIndex?.latestActivity
        )
    }
}

struct TradeQuotesView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        TradeCountsPage(
            title: "询盘与报价",
            subtitle: "公开仓仅显示草稿/开口数量",
            cards: [
                ("开口询盘", store.tradeLeadsIndex?.counts?.inquiriesOpen),
                ("报价草稿", store.tradeLeadsIndex?.counts?.quotesDraft),
            ],
            activity: store.tradeLeadsIndex?.latestActivity
        )
    }
}

struct TradeCountsPage: View {
    var title: String
    var subtitle: String
    var cards: [(String, Int?)]
    var activity: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.title2.weight(.bold))
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    ForEach(cards, id: \.0) { label, value in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(label).font(.caption).foregroundStyle(.secondary)
                            Text(value.map(String.init) ?? "—")
                                .font(.system(size: 28, weight: .bold))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SWTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.panel).stroke(SWTheme.borderSoft))
                    }
                }
                if let activity, !activity.isEmpty {
                    Text("最近动态：\(activity)")
                        .font(.caption)
                        .foregroundStyle(SWTheme.textMuted)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SWTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Text("明细：超级工作台应用/data/private/trade-leads.local.json（gitignore）· 公开索引 trade-leads-index.json")
                    .font(.caption2)
                    .foregroundStyle(SWTheme.textMuted)
            }
            .padding(24)
        }
        .background(SWTheme.pageBg)
    }
}
