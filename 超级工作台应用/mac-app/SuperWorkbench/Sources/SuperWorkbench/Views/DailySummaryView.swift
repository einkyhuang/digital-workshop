import SwiftUI

/// 「每日总结」— 左侧日期列表 + 右侧纪纪日报卡片（按需加载 Markdown）
struct DailySummaryView: View {
    @EnvironmentObject var store: WorkspaceStore

    var body: some View {
        HStack(spacing: 0) {
            dateList
                .frame(width: 220)
                .background(SWTheme.card)
                .overlay(alignment: .trailing) { Divider() }

            reportPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SWTheme.pageBg)
        }
        .onAppear {
            store.refreshDailyReportDates()
            if let d = store.selectedDailyReportDate {
                store.loadDailyReport(date: d)
            }
        }
        .onChange(of: store.selectedDailyReportDate) { _, new in
            if let d = new { store.loadDailyReport(date: d) }
        }
    }

    private var dateList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("日报日期")
                .font(.system(size: SWTheme.Typography.caption, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)
            if store.dailyReportDates.isEmpty {
                Text("暂无日报\nbots/管理中枢/总结助手/deliverables/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(14)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(store.dailyReportDates, id: \.self) { d in
                            Button {
                                store.selectedDailyReportDate = d
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(d).font(.system(size: SWTheme.Typography.nav, weight: store.selectedDailyReportDate == d ? .bold : .regular))
                                        Text("纪纪-总结助手")
                                            .font(.caption2)
                                            .foregroundStyle(SWTheme.textMuted)
                                    }
                                    Spacer()
                                    if store.selectedDailyReportDate == d {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(store.selectedDailyReportDate == d ? Color.black.opacity(0.06) : Color.clear)
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

    private var reportPane: some View {
        Group {
            if store.isDailyReportLoading {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("加载日报…").font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let md = store.dailyReportMarkdown, let date = store.selectedDailyReportDate {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("团队日报 \(date)")
                                    .font(.system(size: SWTheme.Typography.h1, weight: .bold))
                                Text("来源：bots/管理中枢/总结助手/deliverables/日报-\(date).md")
                                    .font(.system(size: SWTheme.Typography.caption))
                                    .foregroundStyle(SWTheme.textMuted)
                            }
                            Spacer()
                            Button {
                                store.openScheduleDay(date)
                            } label: {
                                Label("查看当日日程", systemImage: "calendar")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.bottom, 4)

                        let sections = DailyReportParser.cards(from: md)
                        ForEach(sections) { sec in
                            reportCard(sec)
                        }
                    }
                    .padding(24)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("选择左侧日期查看日报")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func reportCard(_ sec: DailyReportParser.Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(sec.title, systemImage: sec.icon)
                    .font(.system(size: SWTheme.Typography.h3, weight: .bold))
                Spacer()
            }
            if sec.body.isEmpty {
                Text("—").foregroundStyle(.secondary).font(.system(size: SWTheme.Typography.body))
            } else {
                Text(sec.body)
                    .font(.system(size: SWTheme.Typography.body))
                    .lineSpacing(SWTheme.Typography.body * (SWTheme.Typography.bodyLine - 1))
                    .foregroundStyle(SWTheme.text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous)
                .stroke(SWTheme.borderSoft)
        )
        .shadow(color: SWTheme.shadowElevated, radius: 6, y: 2)
    }
}

enum DailyReportParser {
    struct Section: Identifiable {
        var id: String { title }
        var title: String
        var icon: String
        var body: String
    }

    /// Map 纪纪日报 headings → display cards (完成事项 / 交付物 / 卡住的事 / 待用户决定的事)
    static func cards(from md: String) -> [Section] {
        let blocks = splitSections(md)
        func body(matching keys: [String]) -> String {
            for k in keys {
                if let b = blocks.first(where: { $0.0.contains(k) }) {
                    return trim(b.1)
                }
            }
            return ""
        }
        let done = body(matching: ["各 Bot 当日工作", "完成事项", "总览"])
        let deliver = body(matching: ["完成的项目与交付物", "交付物"])
        let stuck = body(matching: ["卡住", "待用户决定"])
        // Split stuck into two cards when possible
        var stuckBody = stuck
        var decideBody = ""
        if stuck.contains("待用户决定") || stuck.contains("重点") {
            // Keep full in 待用户决定; 卡住的事 pulls overview hints if separate
            decideBody = stuck
            stuckBody = body(matching: ["卡住的事"]) // may be empty
            if stuckBody.isEmpty {
                // Derive a short "卡住" blurb from first lines mentioning 卡住
                let lines = stuck.split(separator: "\n").map(String.init)
                let hit = lines.filter { $0.contains("卡住") || $0.contains("待拍板") || $0.contains("连不上") }
                stuckBody = hit.isEmpty ? "见「待用户决定的事」卡片。" : hit.joined(separator: "\n")
            }
        }
        return [
            Section(title: "完成事项", icon: "checkmark.circle.fill", body: done.isEmpty ? trim(blocks.first?.1 ?? String(md.prefix(800))) : done),
            Section(title: "交付物", icon: "shippingbox.fill", body: deliver.isEmpty ? "—" : deliver),
            Section(title: "卡住的事", icon: "exclamationmark.triangle.fill", body: stuckBody.isEmpty ? "—" : stuckBody),
            Section(title: "待用户决定的事", icon: "hand.raised.fill", body: decideBody.isEmpty ? (stuck.isEmpty ? "—" : stuck) : decideBody),
        ]
    }

    private static func splitSections(_ md: String) -> [(String, String)] {
        var result: [(String, String)] = []
        var title = "前言"
        var buf: [String] = []
        for line in md.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            if line.hasPrefix("## ") {
                if !buf.isEmpty || title != "前言" {
                    result.append((title, buf.joined(separator: "\n")))
                }
                title = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                buf = []
            } else {
                buf.append(line)
            }
        }
        result.append((title, buf.joined(separator: "\n")))
        return result
    }

    private static func trim(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
