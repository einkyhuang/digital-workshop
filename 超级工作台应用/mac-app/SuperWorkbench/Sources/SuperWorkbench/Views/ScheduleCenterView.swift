import SwiftUI

/// 「任务与日程中心」— month calendar + day detail sheet（样式对齐网站项目详情弹层）
struct ScheduleCenterView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var showDayDetail = false

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        c.firstWeekday = 2 // Monday
        return c
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                monthHeader
                weekdayHeader
                calendarGrid
                if store.isScheduleLoading {
                    HStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("加载当月日程…").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                legend
            }
            .padding(24)
        }
        .background(SWTheme.pageBg)
        .onAppear {
            store.loadScheduleMonth(around: store.calendarMonth)
        }
        .sheet(isPresented: $showDayDetail) {
            if let ymd = store.selectedCalendarDate {
                ScheduleDayDetailSheet(ymd: ymd)
                    .environmentObject(store)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(monthTitle)
                .font(.system(size: 22, weight: .bold))

            Spacer()

            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)

            Button("今天") {
                store.calendarMonth = Date()
                store.loadScheduleMonth(around: Date())
            }
            .buttonStyle(.bordered)
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.timeZone = TimeZone(identifier: "Asia/Shanghai")
        f.dateFormat = "yyyy年 M月"
        return f.string(from: store.calendarMonth)
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: store.calendarMonth) {
            store.calendarMonth = d
            store.loadScheduleMonth(around: d)
        }
    }

    private var weekdayHeader: some View {
        let labels = ["一", "二", "三", "四", "五", "六", "日"]
        return HStack(spacing: 8) {
            ForEach(labels, id: \.self) { w in
                Text(w)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(SWTheme.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let days = monthCells()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(days, id: \.id) { cell in
                dayCell(cell)
            }
        }
    }

    private func dayCell(_ cell: DayCell) -> some View {
        let doc = cell.ymd.flatMap { store.scheduleDay(for: $0) }
        let taskN = doc?.tasks?.count ?? 0
        let schedN = doc?.schedule?.count ?? 0
        let hasEmail = doc?.meta?.hasEmailSummary == true
        let hasReport = doc?.meta?.hasDailyReport == true
        let isToday = cell.ymd == WorkspaceStore.ymd(Date())
        let isSelected = cell.ymd == store.selectedCalendarDate

        return Button {
            guard let ymd = cell.ymd else { return }
            store.selectedCalendarDate = ymd
            showDayDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(cell.dayLabel)
                        .font(.system(size: 14, weight: isToday ? .bold : .semibold))
                        .foregroundStyle(cell.inMonth ? SWTheme.text : SWTheme.textMuted.opacity(0.5))
                    Spacer()
                    if isToday {
                        Circle().fill(SWTheme.focus).frame(width: 6, height: 6)
                    }
                }
                if cell.inMonth {
                    VStack(alignment: .leading, spacing: 3) {
                        if taskN > 0 {
                            Label("\(taskN) 任务", systemImage: "checklist")
                                .font(.system(size: 10))
                                .foregroundStyle(SWTheme.projProgressFg)
                                .lineLimit(1)
                        }
                        if schedN > 0 {
                            Label("\(schedN) 日程", systemImage: "clock")
                                .font(.system(size: 10))
                                .foregroundStyle(SWTheme.textSecondary)
                                .lineLimit(1)
                        }
                        HStack(spacing: 4) {
                            if hasEmail {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(red: 0.45, green: 0.55, blue: 0.95))
                            }
                            if hasReport {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color(red: 0.15, green: 0.65, blue: 0.45))
                            }
                            if taskN == 0 && schedN == 0 && !hasEmail && !hasReport {
                                Text("—")
                                    .font(.system(size: 10))
                                    .foregroundStyle(SWTheme.textMuted.opacity(0.4))
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous)
                    .fill(cell.inMonth ? SWTheme.card : SWTheme.card.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous)
                    .stroke(isSelected ? SWTheme.focus : SWTheme.borderSoft, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: cell.inMonth ? SWTheme.shadowElevated : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!cell.inMonth || cell.ymd == nil)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label("任务数", systemImage: "checklist").font(.caption).foregroundStyle(.secondary)
            Label("日程数", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
            Label("邮件总结", systemImage: "envelope.fill").font(.caption).foregroundStyle(.secondary)
            Label("纪纪日报", systemImage: "doc.text.fill").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text("仅加载当月 · data/schedule/")
                .font(.caption2)
                .foregroundStyle(SWTheme.textMuted)
        }
        .padding(.top, 4)
    }

    // MARK: - Grid helpers

    private struct DayCell: Identifiable {
        var id: String
        var ymd: String?
        var dayLabel: String
        var inMonth: Bool
    }

    private func monthCells() -> [DayCell] {
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: store.calendarMonth))!
        let range = cal.range(of: .day, in: .month, for: monthStart)!
        let firstWeekday = cal.component(.weekday, from: monthStart) // 1=Sun
        // Convert to Monday-first offset: Mon=0 … Sun=6
        let offset = (firstWeekday + 5) % 7
        var cells: [DayCell] = []
        for i in 0..<offset {
            cells.append(DayCell(id: "pad-\(i)", ymd: nil, dayLabel: "", inMonth: false))
        }
        for day in range {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let ymd = WorkspaceStore.ymd(date)
            cells.append(DayCell(id: ymd, ymd: ymd, dayLabel: "\(day)", inMonth: true))
        }
        while cells.count % 7 != 0 {
            cells.append(DayCell(id: "pad-end-\(cells.count)", ymd: nil, dayLabel: "", inMonth: false))
        }
        return cells
    }
}

// MARK: - Day detail sheet

struct ScheduleDayDetailSheet: View {
    @EnvironmentObject var store: WorkspaceStore
    let ymd: String
    @Environment(\.dismiss) private var dismiss

    private var doc: ScheduleDayDoc? { store.scheduleDay(for: ymd) }
    private var email: OverviewMetrics.EmailDaily? { store.emailSummary(for: ymd) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ymd)
                        .font(.system(size: 22, weight: .bold))
                    Text("任务 · 日程 · 邮件总结 · 纪纪日报")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(SWTheme.card)
            .overlay(alignment: .bottom) { Divider() }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    tasksCard
                    scheduleCard
                    emailCard
                    reportCard
                }
                .padding(16)
            }
            .background(SWTheme.pageBg)
        }
        .frame(minWidth: 640, idealWidth: 720, minHeight: 520, idealHeight: 640)
    }

    private var tasksCard: some View {
        detailCard(title: "任务列表", badge: "\(doc?.tasks?.count ?? 0)", icon: "checklist") {
            let items = doc?.tasks ?? []
            if items.isEmpty {
                Text("本日暂无任务落库").font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(items) { t in
                    HStack(alignment: .top, spacing: 10) {
                        statusPill(t.status ?? "待办")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t.title).font(.subheadline.weight(.semibold))
                            HStack(spacing: 8) {
                                if let o = t.ownerName ?? t.ownerBotId {
                                    Text(o).font(.caption).foregroundStyle(.secondary)
                                }
                                if let due = t.dueAt {
                                    Text(shortTime(due)).font(.caption).foregroundStyle(SWTheme.textMuted)
                                }
                            }
                            if let n = t.note, !n.isEmpty {
                                Text(n).font(.caption).foregroundStyle(SWTheme.textMuted).lineLimit(2)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var scheduleCard: some View {
        detailCard(title: "日程安排", badge: "\(doc?.schedule?.count ?? 0)", icon: "clock") {
            let items = doc?.schedule ?? []
            if items.isEmpty {
                Text("本日暂无日程块").font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(items) { s in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timeRange(s)).font(.caption.monospaced()).foregroundStyle(SWTheme.focus)
                            Text(s.title).font(.subheadline.weight(.semibold))
                            HStack(spacing: 8) {
                                if let w = s.who { Text(w).font(.caption).foregroundStyle(.secondary) }
                                if let k = s.kind {
                                    Text(k)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.05))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var emailCard: some View {
        let has = doc?.meta?.hasEmailSummary == true || email != nil
        return detailCard(title: "邮件总结（信鸽）", badge: has ? "有" : "无", icon: "envelope") {
            if let e = email {
                HStack(spacing: 12) {
                    miniStat("新邮件", "\(e.countNew)")
                    miniStat("已清理", "\(e.countCleaned)")
                    miniStat("待回复", "\(e.pendingReplies)")
                }
                if !e.important.isEmpty {
                    Text("重要邮件").font(.caption.weight(.semibold)).padding(.top, 6)
                    ForEach(e.important.prefix(6)) { m in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(m.company).font(.caption.weight(.semibold))
                                if !m.urgency.isEmpty {
                                    Text(m.urgency)
                                        .font(.caption2)
                                        .foregroundStyle(SWTheme.urgencyHigh)
                                }
                            }
                            Text(m.subject).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            if !m.summary.isEmpty {
                                Text(m.summary).font(.caption2).foregroundStyle(SWTheme.textMuted).lineLimit(2)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
                Text("来源：bots/…/email-daily/（私有，不进 Pages）")
                    .font(.caption2)
                    .foregroundStyle(SWTheme.textMuted)
                    .padding(.top, 4)
            } else if has {
                Text("标记有邮件总结，但本地 JSON 暂不可读。")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Text("本日无邮件总结").font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var reportCard: some View {
        let has = doc?.meta?.hasDailyReport == true
            || FileManager.default.fileExists(
                atPath: store.dailyReportDirURL.appendingPathComponent("日报-\(ymd).md").path
            )
        return detailCard(title: "纪纪日报", badge: has ? "有" : "无", icon: "doc.text") {
            if has {
                Text("bots/管理中枢/总结助手/deliverables/日报-\(ymd).md")
                    .font(.caption)
                    .foregroundStyle(SWTheme.textMuted)
                Button {
                    dismiss()
                    store.openDailySummary(date: ymd)
                } label: {
                    Label("打开「每日总结」查看全文", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            } else {
                Text("本日尚无纪纪日报").font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private func detailCard<Content: View>(title: String, badge: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(badge)
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
            }
            content()
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

    private func statusPill(_ s: String) -> some View {
        let color: Color = {
            switch s {
            case "完成": return Color(red: 0.15, green: 0.65, blue: 0.45)
            case "进行中": return SWTheme.focus
            case "验收": return Color(red: 0.85, green: 0.55, blue: 0.1)
            default: return SWTheme.textMuted
            }
        }()
        return Text(s)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.weight(.bold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(SWTheme.pageBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func shortTime(_ iso: String) -> String {
        if iso.count >= 16 { return String(iso.dropFirst(11).prefix(5)) }
        return iso
    }

    private func timeRange(_ s: ScheduleBlockItem) -> String {
        let a = s.startAt.map(shortTime) ?? "—"
        let b = s.endAt.map(shortTime) ?? ""
        return b.isEmpty ? a : "\(a)–\(b)"
    }
}
