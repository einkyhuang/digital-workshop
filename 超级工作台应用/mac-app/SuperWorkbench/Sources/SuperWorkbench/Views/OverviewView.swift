import SwiftUI

private struct OverviewWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 1200
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct OverviewView: View {
    @EnvironmentObject var store: WorkspaceStore
    /// Measured via background GeometryReader — ContentView already wraps us in ScrollView,
    /// so an outer GeometryReader here collapses to ~0 height (blank overview).
    @State private var contentWidth: CGFloat = 1200

    private var groupOrder: [String] {
        store.data.groupsOrder ?? ["管理中枢","网站项目","服装外贸","运营管理","战略决策","视觉设计","短剧组","外贸营销","个人成长","内容营销"]
    }

    var body: some View {
        let w = contentWidth
        let stackGap: CGFloat = w >= 2560 ? 32 : (w >= 1920 ? 28 : 24)
        let kpiCols = kpiColumnCount(w)
        let goalCols = goalColumnCount(w)
        let emailCols = emailColumnCount(w)
        let rosterMin: CGFloat = w >= 2560 ? 420 : (w >= 1920 ? 400 : 340)

        VStack(alignment: .leading, spacing: stackGap) {
            if let err = store.loadError {
                Text(err).foregroundStyle(.red).padding().swCard()
            }
            websiteBoard(kpiCols: kpiCols, goalCols: goalCols)
            scheduleBoard
            emailBoard(cols: emailCols)
            rosterBoard(minWidth: rosterMin)
            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // FULL WIDTH — no 1680 cap
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: OverviewWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(OverviewWidthKey.self) { contentWidth = max($0, 320) }
    }

    /// FULL-WIDTH: ≥2560 gets more columns instead of centering/capping.
    private func kpiColumnCount(_ w: CGFloat) -> Int {
        if w >= 2560 { return 6 }
        if w >= 1920 { return 5 }
        if w >= 1440 { return 4 }
        if w >= 900 { return 3 }
        return 2
    }
    private func goalColumnCount(_ w: CGFloat) -> Int {
        if w >= 2560 { return 5 }
        if w >= 1920 { return 4 }
        if w >= 1100 { return 2 }
        return 1
    }
    private func emailColumnCount(_ w: CGFloat) -> Int {
        if w >= 2560 { return 3 }
        if w >= 1920 { return 2 }
        return 1
    }

    // MARK: - Website

    private func websiteBoard(kpiCols: Int, goalCols: Int) -> some View {
        let kpi = store.websiteKPI()
        let webs = store.data.websiteProjects ?? []
        let privacy = !kpi.amountsAvailable
        let top = webs.filter { $0.status == "in_progress" || $0.status == "infrastructure" }
            .sorted { ($0.progress ?? 0) > ($1.progress ?? 0) }
            .prefix(5)

        return VStack(alignment: .leading, spacing: 14) {
            sectionHead("网站项目看板", badge: "\(webs.count)")
            Text("口径：金算盘 · 基准 \(kpi.asOf) · CNY")
                .font(.system(size: 12)).foregroundStyle(SWTheme.textMuted)

            Text("存量健康").font(.system(size: 12, weight: .semibold)).foregroundStyle(SWTheme.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: kpiCols), spacing: 14) {
                kpiCard(icon: "¥", value: privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioContract),
                        label: "合同总额", detail: "全库 Σ totalAmount", tone: .blue)
                kpiCard(icon: "收", value: privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioPaid),
                        label: "已收", detail: "全库 Σ paidAmount", tone: .green)
                kpiCard(icon: "待", value: privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioUnpaid),
                        label: "待收", detail: "存量 · 主卡", tone: .amber)
                kpiCard(icon: "逾", value: privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioOverdue),
                        label: "逾期", detail: kpi.overdueRiskCount > 0 ? "另有风险 \(kpi.overdueRiskCount)" : "有截止日且待收", tone: .rose)
                kpiCard(icon: "#", value: privacy ? "仅本地可见" : "\(kpi.pricedCount)",
                        label: "有金额项目", detail: "totalAmount > 0", tone: .violet)
            }

            Text("本年目标完成率").font(.system(size: 12, weight: .semibold)).foregroundStyle(SWTheme.textSecondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: goalCols), spacing: 14) {
                goalCard(
                    title: "合同目标", sub: "完成率",
                    ringLabel: privacy ? "—" : OverviewMetrics.pct(kpi.yearContract, kpi.yearContractTarget),
                    progress: privacy ? 0 : rate(kpi.yearContract, kpi.yearContractTarget),
                    detail: privacy ? "—" : (kpi.yearContractTarget == nil ? "目标待设定" : "本年合同 \(OverviewMetrics.currency(kpi.yearContract)) / \(OverviewMetrics.currency(kpi.yearContractTarget!))"),
                    color: SWTheme.ringContract, paid: false
                )
                goalCard(
                    title: "回款目标", sub: "完成率",
                    ringLabel: privacy ? "—" : OverviewMetrics.pct(kpi.yearPaid, kpi.yearCollectionTarget),
                    progress: privacy ? 0 : rate(kpi.yearPaid, kpi.yearCollectionTarget),
                    detail: privacy ? "—" : (kpi.yearCollectionTarget == nil ? "目标待设定" : "本年已收 \(OverviewMetrics.currency(kpi.yearPaid)) / \(OverviewMetrics.currency(kpi.yearCollectionTarget!))"),
                    color: SWTheme.ringPaid, paid: true
                )
                goalCard(
                    title: "本年合同额", sub: "合同归属年",
                    ringLabel: privacy ? "—" : shortYen(kpi.yearContract),
                    progress: privacy ? 0 : 1,
                    detail: privacy ? "—" : OverviewMetrics.currency(kpi.yearContract),
                    color: Color(red: 0.545, green: 0.361, blue: 0.965), paid: false
                )
                goalCard(
                    title: "本月合同额", sub: "合同归属月",
                    ringLabel: privacy ? "—" : shortYen(kpi.monthContract),
                    progress: privacy ? 0 : (kpi.yearContract > 0 ? min(1, kpi.monthContract / kpi.yearContract) : 0),
                    detail: privacy ? "—" : OverviewMetrics.currency(kpi.monthContract),
                    color: SWTheme.urgencyMid, paid: false
                )
            }

            if !kpi.quality.isEmpty {
                Text("数据质量：" + kpi.quality.map { "\($0.label) \($0.count)" }.joined(separator: " · "))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 0.76, green: 0.25, blue: 0.05))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 1, green: 0.929, blue: 0.835))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(alignment: .top, spacing: 12) {
                statusDist(webs)
                paymentDist(webs, risk: kpi.overdueRiskCount)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("进行中优先").font(.system(size: 12, weight: .semibold)).foregroundStyle(SWTheme.textSecondary)
                ForEach(Array(top)) { w in
                    HStack(spacing: 10) {
                        StatusPill(status: w.status, category: w.category, progress: w.progress)
                        Text(w.name).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Spacer()
                        Text("\(w.progress ?? 0)%").font(.system(size: 12).monospacedDigit()).foregroundStyle(SWTheme.textMuted)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SWTheme.borderSoft))
                    .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
                }
            }
        }
        .padding(22)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.radiusSection, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.radiusSection).stroke(SWTheme.borderGroup))
        .shadow(color: SWTheme.shadowElevated, radius: 20, y: 6)
    }

    private enum KPITone { case blue, green, amber, rose, violet }

    private func kpiCard(icon: String, value: String, label: String, detail: String, tone: KPITone) -> some View {
        let bot: Color = {
            switch tone {
            case .blue: return SWTheme.gradBlueBot
            case .green: return SWTheme.gradGreenBot
            case .amber: return SWTheme.gradAmberBot
            case .rose: return SWTheme.gradRoseBot
            case .violet: return SWTheme.gradVioletBot
            }
        }()
        let iconBg: Color = {
            switch tone {
            case .blue: return Color(red: 0.937, green: 0.965, blue: 1)
            case .green: return Color(red: 0.925, green: 0.992, blue: 0.961)
            case .amber: return Color(red: 1, green: 0.984, blue: 0.922)
            case .rose: return Color(red: 1, green: 0.945, blue: 0.949)
            case .violet: return Color(red: 0.961, green: 0.953, blue: 1)
            }
        }()
        let iconFg: Color = {
            switch tone {
            case .blue: return Color(red: 0.145, green: 0.388, blue: 0.922)
            case .green: return Color(red: 0.02, green: 0.588, blue: 0.412)
            case .amber: return Color(red: 0.851, green: 0.467, blue: 0.024)
            case .rose: return Color(red: 0.882, green: 0.114, blue: 0.282)
            case .violet: return Color(red: 0.486, green: 0.227, blue: 0.929)
            }
        }()
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(iconFg)
                    .frame(width: 32, height: 32)
                    .background(iconBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
            }
            .padding(.bottom, 12)
            Text(value)
                .font(.system(size: value.count > 10 ? 20 : 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text(label).font(.system(size: 12, weight: .semibold)).padding(.top, 6)
            Text(detail).font(.system(size: 11)).foregroundStyle(SWTheme.textMuted).padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background(
            LinearGradient(colors: [.white, bot], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.radiusKPI, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.radiusKPI).stroke(SWTheme.borderSoft))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func goalCard(title: String, sub: String, ringLabel: String, progress: Double, detail: String, color: Color, paid: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(SWTheme.ringTrack, lineWidth: 5)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                Text(ringLabel)
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold))
                Text(sub).font(.system(size: 12, weight: .semibold))
                Text(detail).font(.system(size: 11)).foregroundStyle(SWTheme.textMuted).lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [.white, paid ? SWTheme.gradGreenBot : SWTheme.gradBlueBot],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.radiusKPI, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.radiusKPI).stroke(SWTheme.borderSoft))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func rate(_ n: Double, _ d: Double?) -> Double {
        guard let d, d > 0 else { return 0 }
        return min(1, n / d)
    }
    private func shortYen(_ v: Double) -> String {
        if v >= 1000 { return String(format: "¥%.0fk", v / 1000) }
        return OverviewMetrics.currency(v)
    }

    private func statusDist(_ webs: [WebsiteProject]) -> some View {
        let keys = ["in_progress", "delivered", "infrastructure", "inactive"]
        let labels = ["进行中", "已交付", "筹建", "挂起"]
        return VStack(alignment: .leading, spacing: 8) {
            Text("状态分布").font(.system(size: 12, weight: .semibold)).foregroundStyle(SWTheme.textSecondary)
            ForEach(Array(keys.enumerated()), id: \.offset) { i, k in
                let n = webs.filter { $0.status == k }.count
                HStack {
                    Circle().fill(SWTheme.websiteStatusColor(k)).frame(width: 8, height: 8)
                    Text(labels[i]).font(.system(size: 12))
                    Spacer()
                    Text("\(n)").font(.system(size: 12, weight: .semibold).monospacedDigit())
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SWTheme.pageBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SWTheme.borderSoft))
    }

    private func paymentDist(_ webs: [WebsiteProject], risk: Int) -> some View {
        let keys = ["fully_paid", "deposit_paid", "pending"]
        let labels = ["已结清", "已付定金", "待收款"]
        return VStack(alignment: .leading, spacing: 8) {
            Text("收款状态").font(.system(size: 12, weight: .semibold)).foregroundStyle(SWTheme.textSecondary)
            ForEach(Array(keys.enumerated()), id: \.offset) { i, k in
                let n = webs.filter { ($0.paymentStatus ?? "") == k }.count
                HStack {
                    Text(labels[i]).font(.system(size: 12))
                    Spacer()
                    Text("\(n)").font(.system(size: 12, weight: .semibold).monospacedDigit())
                }
            }
            HStack {
                Text("逾期风险(无截止)").font(.system(size: 12))
                Spacer()
                Text("\(risk)").font(.system(size: 12, weight: .semibold).monospacedDigit())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SWTheme.pageBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SWTheme.borderSoft))
    }

    // MARK: - Schedule

    private var scheduleBoard: some View {
        let tasks = store.overviewBoardTasks()
        let cols: [TaskColumn] = [.todo, .doing, .review, .done]
        return VStack(alignment: .leading, spacing: 12) {
            sectionHead("日程管理 · 任务看板", badge: "\(tasks.count)")
            Text("只读 · 工作台任务 + SmartPlan（若本地库可读）")
                .font(.system(size: 12)).foregroundStyle(SWTheme.textMuted)
            HStack(alignment: .top, spacing: 12) {
                ForEach(cols) { col in
                    let items = tasks.filter {
                        $0.status == col.rawValue || (col == .review && ($0.status == "审核" || $0.status == "验收"))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle().fill(SWTheme.columnColor(col)).frame(width: 8, height: 8)
                            Text(col.rawValue).font(.system(size: 12, weight: .semibold))
                            Text("\(items.count)").font(.system(size: 11)).foregroundStyle(SWTheme.textMuted)
                        }
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(items.prefix(8)) { t in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(t.title).font(.system(size: 12, weight: .semibold)).lineLimit(2)
                                        Text(t.source == "smartplan" ? "SmartPlan" : "工作台")
                                            .font(.system(size: 10)).foregroundStyle(SWTheme.textMuted)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SWTheme.borderSoft))
                                    .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
                                }
                                if items.isEmpty {
                                    Text("—").font(.caption).foregroundStyle(SWTheme.textMuted).padding(8)
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(SWTheme.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(SWTheme.borderSoft))
                }
            }
        }
        .padding(22)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.radiusSection, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.radiusSection).stroke(SWTheme.borderGroup))
        .shadow(color: SWTheme.shadowElevated, radius: 20, y: 6)
    }

    // MARK: - Email

    private func emailBoard(cols: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHead("邮件看板", badge: "\(store.emailDaily.count)")
            Text("信鸽-邮件助手 · email-daily")
                .font(.system(size: 12)).foregroundStyle(SWTheme.textMuted)
            if store.emailDaily.isEmpty {
                Text("暂无每日邮件总结。")
                    .font(.subheadline).foregroundStyle(SWTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SWTheme.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(store.emailDaily) { day in
                    emailDay(day, cols: cols)
                }
            }
        }
        .padding(22)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.radiusSection, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.radiusSection).stroke(SWTheme.borderGroup))
        .shadow(color: SWTheme.shadowElevated, radius: 20, y: 6)
    }

    private func emailDay(_ day: OverviewMetrics.EmailDaily, cols: Int) -> some View {
        let open = store.expandedEmailDate == day.date
        return VStack(alignment: .leading, spacing: 10) {
            Button {
                store.expandedEmailDate = open ? nil : day.date
            } label: {
                HStack(spacing: 8) {
                    Text(day.date).font(.system(size: 13, weight: .bold))
                    Text("新\(day.countNew)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color(red: 0.859, green: 0.918, blue: 0.996))
                        .foregroundStyle(Color(red: 0.114, green: 0.306, blue: 0.847))
                        .clipShape(Capsule())
                    Text("清理\(day.countCleaned)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Capsule())
                    Text("待回\(day.pendingReplies)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color(red: 1, green: 0.929, blue: 0.835))
                        .foregroundStyle(Color(red: 0.76, green: 0.25, blue: 0.05))
                        .clipShape(Capsule())
                    Spacer()
                    Image(systemName: open ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(SWTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if open {
                if let src = day.source {
                    Text(src).font(.system(size: 12)).foregroundStyle(SWTheme.textMuted)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: cols), spacing: 10) {
                    ForEach(day.important) { m in
                        emailCard(m)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SWTheme.borderSoft))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func emailCard(_ m: OverviewMetrics.EmailImportant) -> some View {
        let tone: Color = {
            switch m.urgency {
            case "高": return SWTheme.urgencyHigh
            case "中": return SWTheme.urgencyMid
            default: return SWTheme.urgencyLow
            }
        }()
        let wash: Color = {
            switch m.urgency {
            case "高": return Color(red: 1, green: 0.949, blue: 0.949)
            case "中": return Color(red: 1, green: 0.984, blue: 0.922)
            default: return Color(red: 0.973, green: 0.98, blue: 0.988)
            }
        }()
        return HStack(alignment: .top, spacing: 0) {
            Rectangle().fill(tone).frame(width: 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(m.company).font(.system(size: 12, weight: .bold))
                    Spacer()
                    Text(m.urgency).font(.system(size: 11, weight: .bold)).foregroundStyle(tone)
                }
                Text(m.subject).font(.system(size: 13, weight: .semibold))
                if !m.summary.isEmpty {
                    Text(m.summary).font(.system(size: 12)).foregroundStyle(SWTheme.textSecondary).lineLimit(3)
                }
                if !m.todo.isEmpty {
                    Text("待办：\(m.todo)").font(.system(size: 11, weight: .medium)).foregroundStyle(SWTheme.projProgressFg)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [wash, .white], startPoint: .leading, endPoint: UnitPoint(x: 0.32, y: 0.5))
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SWTheme.borderSoft))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Roster (v1 cards unchanged)

    private func rosterBoard(minWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHead("员工看板", badge: "\(store.data.bots.count)")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth), spacing: 16)], spacing: 16) {
                ForEach(groupOrder, id: \.self) { g in
                    let items = store.filteredBots.filter { $0.belongs(to: g) }
                    if !items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(g).font(.system(size: 15, weight: .semibold))
                                Text("\(items.count)")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 7).padding(.vertical, 2)
                                    .background(Color.black.opacity(0.06)).clipShape(Capsule())
                            }
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
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
                        .padding(12)
                        .background(SWTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.group, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.group).stroke(SWTheme.borderGroup))
                    }
                }
            }
        }
    }

    private func sectionHead(_ title: String, badge: String) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.system(size: 18, weight: .bold)).tracking(-0.2)
            Text(badge)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Color.black.opacity(0.06))
                .foregroundStyle(SWTheme.textMuted)
                .clipShape(Capsule())
            Spacer()
        }
    }
}
