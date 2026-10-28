import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var store: WorkspaceStore

    private var groupOrder: [String] {
        store.data.groupsOrder ?? ["管理中枢","网站项目","服装外贸","运营管理","战略决策","视觉设计","短剧组","外贸营销","个人成长","内容营销"]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SWTheme.Space.s6) {
            if let err = store.loadError {
                Text(err).foregroundStyle(.red).padding().swCard()
            }
            websiteBoard
            scheduleBoard
            emailBoard
            rosterBoard
            Spacer(minLength: 80)
        }
    }

    // MARK: - 1) 网站项目看板

    private var websiteBoard: some View {
        let kpi = store.websiteKPI()
        let webs = store.data.websiteProjects ?? []
        let privacy = !kpi.amountsAvailable
        let top = webs.filter { $0.status == "in_progress" || $0.status == "infrastructure" }
            .sorted { ($0.progress ?? 0) > ($1.progress ?? 0) }
            .prefix(5)

        return VStack(alignment: .leading, spacing: SWTheme.Space.s4) {
            sectionHead("网站项目看板", badge: "\(webs.count)")
            Text("口径：金算盘 · 基准 \(kpi.asOf) · CNY")
                .font(.caption).foregroundStyle(SWTheme.textMuted)

            // Row A — 存量
            Text("存量健康").font(.caption.weight(.semibold)).foregroundStyle(SWTheme.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                kpiCard("合同总额", privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioContract), "全库 Σ totalAmount")
                kpiCard("已收", privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioPaid), "全库 Σ paidAmount")
                kpiCard("待收", privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioUnpaid), "存量 · 主卡")
                kpiCard("逾期", privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.portfolioOverdue), kpi.overdueRiskCount > 0 ? "另有风险 \(kpi.overdueRiskCount)" : "有截止日且待收")
                kpiCard("有金额项目", privacy ? "仅本地可见" : "\(kpi.pricedCount)", "totalAmount > 0")
            }

            // Row B — 目标
            Text("本年目标完成率").font(.caption.weight(.semibold)).foregroundStyle(SWTheme.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                kpiCard(
                    "合同目标完成率",
                    privacy ? "仅本地可见" : OverviewMetrics.pct(kpi.yearContract, kpi.yearContractTarget),
                    privacy ? "—" : (kpi.yearContractTarget == nil ? "目标待设定" : "本年合同 \(OverviewMetrics.currency(kpi.yearContract)) / \(OverviewMetrics.currency(kpi.yearContractTarget!))")
                )
                kpiCard(
                    "回款目标完成率",
                    privacy ? "仅本地可见" : OverviewMetrics.pct(kpi.yearPaid, kpi.yearCollectionTarget),
                    privacy ? "—" : (kpi.yearCollectionTarget == nil ? "目标待设定" : "本年已收 \(OverviewMetrics.currency(kpi.yearPaid)) / \(OverviewMetrics.currency(kpi.yearCollectionTarget!))")
                )
                kpiCard(
                    "本年合同额",
                    privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.yearContract),
                    "合同归属年"
                )
                kpiCard(
                    "本月合同额",
                    privacy ? "仅本地可见" : OverviewMetrics.currency(kpi.monthContract),
                    "合同归属月"
                )
            }

            if !kpi.quality.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("数据质量").font(.caption.weight(.semibold)).foregroundStyle(SWTheme.textSecondary)
                    Text(kpi.quality.map { "\($0.label) \($0.count)" }.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(Color(red: 0.76, green: 0.25, blue: 0.05))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SWTheme.projHoldFill)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack(alignment: .top, spacing: 12) {
                statusDist(webs)
                paymentDist(webs, overdueAmt: kpi.portfolioOverdue, risk: kpi.overdueRiskCount)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("进行中优先").font(.subheadline.weight(.semibold)).foregroundStyle(SWTheme.textSecondary)
                if top.isEmpty {
                    Text("暂无进行中项目").font(.caption).foregroundStyle(SWTheme.textMuted)
                } else {
                    ForEach(Array(top)) { w in
                        HStack(spacing: 10) {
                            StatusPill(status: w.status, category: w.category, progress: w.progress)
                            Text(w.name).font(.subheadline.weight(.medium)).lineLimit(1)
                            Spacer()
                            Text("\(w.progress ?? 0)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(SWTheme.textMuted)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(SWTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SWTheme.borderSoft))
                    }
                }
            }
        }
        .padding(SWTheme.Space.s4)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.group, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.group).stroke(SWTheme.borderGroup))
    }

    private func kpiCard(_ label: String, _ value: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: value.count > 10 ? 16 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(SWTheme.text)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
            Text(label).font(.subheadline.weight(.semibold))
            Text(detail).font(.caption2).foregroundStyle(SWTheme.textMuted).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(SWTheme.pageBg)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.panel).stroke(SWTheme.borderSoft))
    }

    private func statusDist(_ webs: [WebsiteProject]) -> some View {
        let keys = ["in_progress", "delivered", "infrastructure", "inactive"]
        let labels = ["进行中", "已交付", "筹建", "挂起"]
        return VStack(alignment: .leading, spacing: 8) {
            Text("状态分布").font(.subheadline.weight(.semibold)).foregroundStyle(SWTheme.textSecondary)
            ForEach(Array(keys.enumerated()), id: \.offset) { i, k in
                let n = webs.filter { $0.status == k }.count
                HStack {
                    Circle().fill(SWTheme.websiteStatusColor(k)).frame(width: 8, height: 8)
                    Text(labels[i]).font(.caption)
                    Spacer()
                    Text("\(n)").font(.caption.weight(.semibold).monospacedDigit())
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SWTheme.pageBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func paymentDist(_ webs: [WebsiteProject], overdueAmt: Double, risk: Int) -> some View {
        let keys = ["fully_paid", "deposit_paid", "pending"]
        let labels = ["已结清", "已付定金", "待收款"]
        return VStack(alignment: .leading, spacing: 8) {
            Text("收款状态").font(.subheadline.weight(.semibold)).foregroundStyle(SWTheme.textSecondary)
            ForEach(Array(keys.enumerated()), id: \.offset) { i, k in
                let n = webs.filter { ($0.paymentStatus ?? "") == k }.count
                HStack {
                    Text(labels[i]).font(.caption)
                    Spacer()
                    Text("\(n)").font(.caption.weight(.semibold).monospacedDigit())
                }
            }
            HStack {
                Text("逾期风险(无截止)").font(.caption)
                Spacer()
                Text("\(risk)").font(.caption.weight(.semibold).monospacedDigit())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SWTheme.pageBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 2) 日程

    private var scheduleBoard: some View {
        let tasks = store.overviewBoardTasks()
        let cols: [TaskColumn] = [.todo, .doing, .review, .done]
        return VStack(alignment: .leading, spacing: SWTheme.Space.s3) {
            sectionHead("日程管理 · 任务看板", badge: "\(tasks.count)")
            Text("只读 · 工作台任务 + SmartPlan（若本地库可读）")
                .font(.caption).foregroundStyle(SWTheme.textMuted)
            HStack(alignment: .top, spacing: 10) {
                ForEach(cols) { col in
                    let items = tasks.filter {
                        $0.status == col.rawValue || (col == .review && ($0.status == "审核" || $0.status == "验收"))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle().fill(SWTheme.columnColor(col)).frame(width: 8, height: 8)
                            Text(col.rawValue).font(.caption.weight(.semibold))
                            Text("\(items.count)").font(.caption2).foregroundStyle(SWTheme.textMuted)
                        }
                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(items.prefix(8)) { t in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(t.title).font(.caption.weight(.medium)).lineLimit(2)
                                        HStack {
                                            Text(t.source == "smartplan" ? "SmartPlan" : "工作台")
                                                .font(.system(size: 9)).foregroundStyle(SWTheme.textMuted)
                                            if let d = t.dueDate, !d.isEmpty {
                                                Text(d).font(.system(size: 9)).foregroundStyle(SWTheme.textMuted)
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(SWTheme.borderSoft))
                                }
                                if items.isEmpty {
                                    Text("—").font(.caption).foregroundStyle(SWTheme.textMuted).padding(8)
                                }
                            }
                        }
                        .frame(maxHeight: 220)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(SWTheme.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(SWTheme.Space.s4)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.group, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.group).stroke(SWTheme.borderGroup))
    }

    // MARK: - 3) 邮件

    private var emailBoard: some View {
        VStack(alignment: .leading, spacing: SWTheme.Space.s3) {
            sectionHead("邮件看板", badge: "\(store.emailDaily.count)")
            Text("信鸽-邮件助手 · email-daily")
                .font(.caption).foregroundStyle(SWTheme.textMuted)
            if store.emailDaily.isEmpty {
                Text("暂无每日邮件总结。放入 bots/外贸营销/超级邮件助手/deliverables/email-daily/YYYY-MM-DD.json 后刷新。")
                    .font(.subheadline).foregroundStyle(SWTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SWTheme.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(store.emailDaily) { day in
                    emailDayRow(day)
                }
            }
        }
        .padding(SWTheme.Space.s4)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.group, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.group).stroke(SWTheme.borderGroup))
    }

    private func emailDayRow(_ day: OverviewMetrics.EmailDaily) -> some View {
        let open = store.expandedEmailDate == day.date
        return VStack(alignment: .leading, spacing: 10) {
            Button {
                store.expandedEmailDate = open ? nil : day.date
            } label: {
                HStack {
                    Text(day.date).font(.subheadline.weight(.bold))
                    Text("新\(day.countNew)").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(SWTheme.projProgressFill).clipShape(Capsule())
                    Text("清理\(day.countCleaned)").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.black.opacity(0.05)).clipShape(Capsule())
                    Text("待回\(day.pendingReplies)").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(SWTheme.projHoldFill).clipShape(Capsule())
                    Spacer()
                    Image(systemName: open ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(SWTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if open {
                if let src = day.source {
                    Text(src).font(.caption2).foregroundStyle(SWTheme.textMuted)
                }
                if !day.cleanupCategories.isEmpty {
                    Text("清理：" + day.cleanupCategories.map { "\($0.key) \($0.value)" }.joined(separator: " · "))
                        .font(.caption2).foregroundStyle(SWTheme.textSecondary)
                }
                if !day.tags.isEmpty {
                    HStack {
                        ForEach(day.tags, id: \.self) { tag in
                            Text(tag).font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.black.opacity(0.05)).clipShape(Capsule())
                        }
                    }
                }
                ForEach(day.important) { m in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(m.company).font(.caption.weight(.bold))
                            Spacer()
                            Text(m.urgency).font(.caption2.weight(.semibold))
                                .foregroundStyle(m.urgency == "高" ? Color.red : SWTheme.textMuted)
                        }
                        Text(m.subject).font(.caption.weight(.semibold))
                        if !m.summary.isEmpty {
                            Text(m.summary).font(.caption2).foregroundStyle(SWTheme.textSecondary)
                        }
                        if !m.todo.isEmpty {
                            Text("待办：\(m.todo)").font(.caption2).foregroundStyle(SWTheme.projProgressFg)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SWTheme.pageBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SWTheme.borderSoft))
    }

    // MARK: - 4) 员工

    private var rosterBoard: some View {
        VStack(alignment: .leading, spacing: SWTheme.Space.s3) {
            sectionHead("员工看板", badge: "\(store.data.bots.count)")
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
                    .padding(SWTheme.Space.s3)
                    .background(SWTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.group, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.group).stroke(SWTheme.borderGroup))
                }
            }
        }
    }

    private func sectionHead(_ title: String, badge: String) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 18, weight: .bold))
            Text(badge)
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.black.opacity(0.06)).clipShape(Capsule())
            Spacer()
        }
    }
}
