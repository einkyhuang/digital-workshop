import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: WorkspaceStore
    private var groups: [(String, [SidebarSection])] {
        store.activeModuleGroups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            workbenchSegment
                .padding(.horizontal, 12)
                .padding(.top, 14)
                .padding(.bottom, 10)

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 32, height: 32)
                    Image(systemName: store.activeWorkbench?.icon ?? "square.grid.2x2.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 14, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(store.activeWorkbench?.name ?? "超级工作台")
                        .font(.system(size: SWTheme.Typography.nav, weight: .semibold))
                        .lineLimit(1)
                    Text("\(store.scopedBots.count) 员工 · \(store.scopedTasks.count) 任务")
                        .font(.system(size: SWTheme.Typography.groupTitle))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if store.activeWorkbenchId == "trade" {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MagicHub")
                                .font(.system(size: SWTheme.Typography.groupTitle, weight: .medium))
                                .foregroundStyle(SWTheme.textMuted)
                                .padding(.horizontal, 14)
                                .padding(.bottom, 4)
                            ForEach(MagicHubNavItem.all) { item in
                                mhNavRow(item)
                            }
                        }
                    } else {
                        ForEach(groups, id: \.0) { group, items in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group)
                                    .font(.system(size: SWTheme.Typography.groupTitle, weight: .medium))
                                    .foregroundStyle(SWTheme.textMuted)
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 4)
                                ForEach(items) { section in
                                    navRow(section)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    openGlobalSettings()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape")
                            .font(.system(size: SWTheme.Typography.navIcon, weight: .regular))
                            .frame(width: 20, alignment: .center)
                        Text("设置")
                            .font(.system(size: SWTheme.Typography.nav, weight: .semibold))
                        Spacer(minLength: 0)
                        Text("⌘,")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(SWTheme.text)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: SWTheme.Typography.navRowMin, alignment: .leading)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.72))
                    )
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.plain)
                .help("全局模型设置（与外贸工作台共用）")

                HStack(spacing: 8) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("数据文件").font(.system(size: SWTheme.Typography.groupTitle, weight: .semibold))
                        Text(store.loadError == nil ? "已连接 workspace.json" : "读取异常")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.black)
                        Text("KY").font(.caption.bold()).foregroundStyle(.white)
                    }
                    .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KY Workspace").font(.system(size: SWTheme.Typography.groupTitle, weight: .semibold))
                        Text("ARM64 · 离线本地").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(12)
        }
        .background(SWTheme.sidebarBg)
    }

    /// 千问风格：灰底胶囊，选中项白底微阴影
    @ViewBuilder
    private var workbenchSegment: some View {
        if store.workbenches.count > 1 {
            HStack(spacing: 0) {
                ForEach(store.workbenches) { wb in
                    segmentButton(wb)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.06))
            )
        }
    }

    private func segmentButton(_ wb: WorkbenchConfig) -> some View {
        let selected = store.activeWorkbenchId == wb.id
        return Button {
            store.switchWorkbench(wb.id)
        } label: {
            Text(wb.shortName ?? wb.name)
                .font(.system(size: SWTheme.Typography.segment, weight: selected ? .semibold : .regular))
                .foregroundStyle(SWTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? Color.white : Color.clear)
                        .shadow(color: selected ? Color.black.opacity(0.08) : .clear, radius: 3, y: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func badge(for section: SidebarSection) -> Int? {
        switch section {
        case .roster: return store.scopedBots.count
        case .tasks: return store.scopedTasks.count
        case .hiring: return store.data.vacancies.filter { !$0.confirmed }.count
        case .rooms: return store.data.groups.count
        case .projects: return store.data.websiteProjects?.count ?? 0
        case .tradeLeads: return store.tradeLeadsIndex?.counts?.leadsTotal
        case .tradePipeline: return store.tradeLeadsIndex?.counts?.inProgressDev
        case .tradeQuotes: return store.tradeLeadsIndex?.counts?.quotesDraft
        case .crmCustomers: return store.crmLeadsTotal
        case .dailySeo: return store.feedIndexes["seo"]?.dates.count
        default: return nil
        }
    }

    private func navRow(_ section: SidebarSection) -> some View {
        let selected = store.selectedSection == section
        return Button {
            store.selectedSection = section
            if section != .roster { store.showingBotDetail = false }
            if section == .scheduleCenter { store.loadScheduleMonth(around: store.calendarMonth) }
            if section == .dailySummary {
                store.refreshDailyReportDates()
                if let d = store.selectedDailyReportDate { store.loadDailyReport(date: d) }
            }
            if section == .dailySeo {
                store.ensureFeedsLoaded()
                store.refreshFeedIndex(feedId: "seo")
                store.watchFeed(feedId: "seo")
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: SWTheme.Typography.navIcon, weight: .regular))
                    .frame(width: 20, alignment: .center)
                    .foregroundStyle(selected ? SWTheme.text : SWTheme.textSecondary)
                Text(section.navTitle)
                    .font(.system(size: SWTheme.Typography.nav, weight: selected ? .semibold : .regular))
                Spacer(minLength: 0)
                if let n = badge(for: section) {
                    Text("\(n)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(selected ? Color.black.opacity(0.10) : Color.black.opacity(0.05))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(SWTheme.text)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: SWTheme.Typography.navRowMin, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color.white.opacity(0.92) : Color.clear)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }


    private func mhNavRow(_ item: MagicHubNavItem) -> some View {
        let selected = store.magicHubTab == item.id
        return Button {
            store.setMagicHubTab(item.id)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: SWTheme.Typography.navIcon, weight: .regular))
                    .frame(width: 20, alignment: .center)
                    .foregroundStyle(selected ? SWTheme.text : SWTheme.textSecondary)
                Text(item.title)
                    .font(.system(size: SWTheme.Typography.nav, weight: selected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(SWTheme.text)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: SWTheme.Typography.navRowMin, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color.white.opacity(0.92) : Color.clear)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }

    private func openGlobalSettings() {
        store.showGlobalModelSettings = true
        if store.activeWorkbenchId == "trade" {
            store.setMagicHubTab("settings")
        }
    }
}
