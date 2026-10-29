import SwiftUI

/// Generic feed browser (SEO card style). Driven by feeds-registry id "seo".
struct DailySeoView: View {
    @EnvironmentObject var store: WorkspaceStore

    private let feedId = "seo"

    var body: some View {
        HStack(spacing: 0) {
            dateList
                .frame(width: 240)
                .background(SWTheme.card)
                .overlay(alignment: .trailing) { Divider() }
            detailPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SWTheme.pageBg)
        }
        .onAppear {
            store.ensureFeedsLoaded()
            store.refreshFeedIndex(feedId: feedId)
            store.watchFeed(feedId: feedId)
            if store.selectedFeedDates[feedId] == nil,
               let first = store.feedIndexes[feedId]?.dates.first?.date {
                store.selectFeedDate(feedId: feedId, date: first)
            }
        }
        .onDisappear {
            // keep watcher; cheap. Uncomment to stop: store.unwatchFeed(feedId: feedId)
        }
    }

    private var dates: [FeedIndexDate] {
        store.feedIndexes[feedId]?.dates ?? []
    }

    private var selected: String? {
        store.selectedFeedDates[feedId]
    }

    private var day: FeedDayDoc? {
        guard let d = selected else { return nil }
        return store.feedDays[feedId]?[d]
    }

    private var dateList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SEO 日期")
                .font(.system(size: SWTheme.Type.caption, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)
            if dates.isEmpty {
                Text("暂无 feed\n写入 data/feeds/seo/YYYY-MM-DD.json\n后跑 rebuild-feeds-index.mjs")
                    .font(.system(size: SWTheme.Type.caption))
                    .foregroundStyle(.secondary)
                    .padding(14)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(dates) { item in
                            Button {
                                store.selectFeedDate(feedId: feedId, date: item.date)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.date)
                                            .font(.system(size: SWTheme.Type.nav, weight: selected == item.date ? .semibold : .regular))
                                        Text(item.summary ?? "搜搜-SEO专家")
                                            .font(.system(size: SWTheme.Type.caption))
                                            .foregroundStyle(SWTheme.textMuted)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    if (item.issueCount ?? 0) > 0 {
                                        Text("\(item.issueCount!)")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selected == item.date ? Color.black.opacity(0.06) : Color.clear)
                                )
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let day, let date = day.date ?? selected {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("每日 SEO · \(date)")
                            .font(.title2.weight(.bold))
                        Text(day.botName ?? "搜搜-SEO专家")
                            .font(.system(size: SWTheme.Type.body))
                            .foregroundStyle(.secondary)
                        if let s = day.summary, !s.isEmpty {
                            Text(s).font(.body)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SWTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    sectionTitle("发布 / 草稿文章")
                    if let arts = day.articles, !arts.isEmpty {
                        ForEach(arts) { a in
                            articleCard(a)
                        }
                    } else {
                        emptyCard("当日无文章条目")
                    }

                    sectionTitle("关键词")
                    if let kws = day.keywords, !kws.isEmpty {
                        FlowKW(kws)
                    } else {
                        emptyCard("无关键词")
                    }

                    sectionTitle("日检")
                    if let checks = day.checks, !checks.isEmpty {
                        ForEach(checks) { c in
                            checkCard(c)
                        }
                    } else {
                        emptyCard("无日检项")
                    }

                    sectionTitle("问题")
                    if let issues = day.issues, !issues.isEmpty {
                        ForEach(Array(issues.enumerated()), id: \.offset) { _, iss in
                            issueCard(iss)
                        }
                    } else {
                        emptyCard("无问题")
                    }

                    Text("数据：超级工作台应用/data/feeds/seo/ · 私有补充见 private/feeds/seo/")
                        .font(.system(size: SWTheme.Type.caption))
                        .foregroundStyle(SWTheme.textMuted)
                }
                .padding(24)
            }
        } else if store.feedLoading {
            ProgressView("加载…").frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("选择左侧日期").foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.system(size: SWTheme.Type.h3, weight: .semibold))
    }

    private func emptyCard(_ t: String) -> some View {
        Text(t).font(.system(size: SWTheme.Type.caption)).foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SWTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func articleCard(_ a: FeedArticle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(a.title ?? a.id).font(.subheadline.weight(.semibold))
                Spacer()
                Text(a.status ?? "")
                    .font(.system(size: SWTheme.Type.caption))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
            }
            if let kw = a.primaryKeyword, !kw.isEmpty {
                Text("主词：\(kw)").font(.system(size: SWTheme.Type.caption)).foregroundStyle(.secondary)
            }
            if let url = a.url, let u = URL(string: url) {
                Link(url, destination: u).font(.system(size: SWTheme.Type.caption))
            }
            if let n = a.notes, !n.isEmpty {
                Text(n).font(.system(size: SWTheme.Type.caption)).foregroundStyle(SWTheme.textMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SWTheme.borderSoft))
    }

    private func checkCard(_ c: FeedCheck) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(checkColor(c.status))
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 4) {
                Text(c.name ?? c.id).font(.subheadline.weight(.semibold))
                if let d = c.detail { Text(d).font(.system(size: SWTheme.Type.caption)).foregroundStyle(.secondary) }
            }
            Spacer()
            Text(c.status ?? "").font(.system(size: SWTheme.Type.caption)).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func issueCard(_ iss: FeedIssue) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(iss.title ?? "问题").font(.subheadline.weight(.semibold))
                Spacer()
                Text(iss.severity ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.orange)
            }
            if let d = iss.detail { Text(d).font(.system(size: SWTheme.Type.caption)).foregroundStyle(.secondary) }
        }
        .padding(12)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func checkColor(_ s: String?) -> Color {
        switch s {
        case "pass": return .green
        case "warn": return .orange
        case "fail": return .red
        default: return .gray
        }
    }
}

private struct FlowKW: View {
    let items: [FeedKeyword]
    init(_ items: [FeedKeyword]) { self.items = items }
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, kw in
                Text("\(kw.term ?? "") · \(kw.intent ?? "")")
                    .font(.system(size: SWTheme.Type.caption))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
