import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var showNewTask = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                SidebarView()
                    .frame(width: SWTheme.sidebarWidth)
                Divider()
                VStack(spacing: 0) {
                    TopBar(
                        searchFocused: $searchFocused,
                        onNew: { handleNew() },
                        onSync: { store.syncGit() }
                    )
                    // Projects (and similar) own a Lazy ScrollView — nesting breaks laziness at scale.
                    if store.selectedSection == .projects {
                        sectionBody
                            .padding(24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(SWTheme.pageBg)
                    } else {
                        ScrollView {
                            sectionBody
                                .padding(24)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(SWTheme.pageBg)
                    }
                }
            }

            FloatingCommandBar()
                .padding(.bottom, 18)
        }
        .background(SWTheme.pageBg)
        .alert("同步", isPresented: Binding(
            get: { !store.syncMessage.isEmpty && !store.isSyncing },
            set: { if !$0 { store.syncMessage = "" } }
        )) {
            Button("好") { store.syncMessage = "" }
        } message: {
            Text(store.syncMessage)
        }
        .sheet(isPresented: $showNewTask) {
            NewTaskSheet().environmentObject(store)
        }
        .overlay {
            if store.isSyncing {
                ProgressView("同步中…")
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "k" {
                    searchFocused = true
                    return nil
                }
                return event
            }
        }
    }

    @ViewBuilder
    private var sectionBody: some View {
        switch store.selectedSection {
        case .overview: OverviewView()
        case .roster:
            if store.showingBotDetail, let bot = store.bot(id: store.selectedBotId) {
                BotDetailView(bot: bot)
            } else {
                RosterGridView()
            }
        case .tasks: KanbanView()
        case .scheduleCenter: ScheduleCenterView()
        case .dailySummary: DailySummaryView()
        case .tradeLeads: TradeLeadsView()
        case .tradePipeline: TradePipelineView()
        case .tradeQuotes: TradeQuotesView()
        case .rooms: RoomsView()
        case .routines: RoutinesView()
        case .hiring: HiringView()
        case .rules: RulesView()
        case .projects: ProjectsView()
        }
    }

    private func handleNew() {
        switch store.selectedSection {
        case .tasks, .overview: showNewTask = true
        default: showNewTask = true
        }
    }
}

struct TopBar: View {
    @EnvironmentObject var store: WorkspaceStore
    var searchFocused: FocusState<Bool>.Binding
    var onNew: () -> Void
    var onSync: () -> Void

    private var title: String { store.selectedSection.rawValue }
    private var subtitle: String {
        switch store.selectedSection {
        case .overview: return "网站业绩 → 日程 → 邮件 → 员工 · 金额仅本地"
        case .roster: return store.showingBotDetail ? "员工详情 · 可查看 bots 文件夹" : "共 \(store.data.bots.count) 位数字员工 · 点击卡片查看详情"
        case .tasks: return "共 \(store.data.tasks.count) 项任务 · 拖拽卡片改状态 · 待办/进行中/验收/完成"
        case .scheduleCenter: return "月历 · 当日任务/日程/邮件标记/纪纪日报 · 仅加载当月"
        case .dailySummary: return "纪纪日报 · 按需加载 · 左选日期右看卡片"
        case .tradeLeads: return "线索/档案聚合计数 · 明细仅本地 private"
        case .tradePipeline: return "开发进度聚合 · 无客户名"
        case .tradeQuotes: return "询盘与报价计数 · 金额不上 Pages"
        case .rooms: return "群聊协作时间线"
        case .routines: return "规划中的定时巡检（尚未启用）"
        case .hiring: return "待招岗位 · 本地标记不会真正创建 Bot"
        case .rules: return "协作铁律与审批边界"
        case .projects: return "SmartPlan 同步的客户网站档案"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                if store.selectedSection == .roster && store.showingBotDetail {
                    Button {
                        store.showingBotDetail = false
                    } label: {
                        Label("返回员工档案", systemImage: "chevron.left")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                HStack(alignment: .center, spacing: 12) {
                    Text(pageTitle).font(.system(size: 28, weight: .bold))
                    if store.selectedSection == .overview, !store.workbenches.isEmpty {
                        workbenchSegment
                    }
                }
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("搜索…", text: $store.searchText)
                        .textFieldStyle(.plain)
                        .focused(searchFocused)
                        .frame(width: 160)
                    Text("⌘K")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SWTheme.border))

                Button(action: onSync) {
                    Label("同步", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)

                Button(action: onNew) {
                    Label("新建", systemImage: "plus")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.9))
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder
    private var workbenchSegment: some View {
        let items = store.workbenches
        if items.count > 1 {
            HStack(spacing: 0) {
                ForEach(items) { wb in
                    Button {
                        store.switchWorkbench(wb.id)
                    } label: {
                        Text(wb.name)
                            .font(.system(size: 13, weight: store.activeWorkbenchId == wb.id ? .semibold : .regular))
                            .foregroundStyle(store.activeWorkbenchId == wb.id ? Color.white : Color.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(store.activeWorkbenchId == wb.id ? Color.accentColor : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var pageTitle: String {
        if store.selectedSection == .roster, store.showingBotDetail, let b = store.bot(id: store.selectedBotId) {
            return b.name
        }
        switch store.selectedSection {
        case .tasks: return "任务看板与待办"
        case .roster: return "员工档案"
        case .overview: return "工作台总览"
        case .scheduleCenter: return "任务与日程中心"
        case .dailySummary: return "每日总结"
        case .tradeLeads: return "客户与线索"
        case .tradePipeline: return "开发进度"
        case .tradeQuotes: return "询盘与报价"
        case .projects: return selectedProjectTitle
        default: return title
        }
    }

    private var selectedProjectTitle: String {
        "网站项目"
    }
}

struct FloatingCommandBar: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles").foregroundStyle(.yellow)
            TextField("向工作台发送指令（本地提示，不会调用外部模型）…", text: $store.commandText)
                .textFieldStyle(.plain)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip("查待办") { store.selectedSection = .tasks; store.searchText = "待办" }
                    chip("打开员工") { store.selectedSection = .roster; store.showingBotDetail = false }
                    chip("同步") { store.syncGit() }
                }
            }
            Button {
                applyCommand()
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 780)
        .background(Color(white: 0.12))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
    }

    private func chip(_ t: String, action: @escaping () -> Void) -> some View {
        Button(t, action: action)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.12))
            .clipShape(Capsule())
            .buttonStyle(.plain)
    }

    private func applyCommand() {
        let q = store.commandText.lowercased()
        if q.contains("同步") { store.syncGit() }
        else if q.contains("员工") || q.contains("档案") { store.selectedSection = .roster }
        else if q.contains("看板") || q.contains("任务") || q.contains("待办") { store.selectedSection = .tasks }
        else if q.contains("招聘") { store.selectedSection = .hiring }
        else if !q.isEmpty { store.searchText = store.commandText }
        store.commandText = ""
    }
}

struct NewTaskSheet: View {
    @EnvironmentObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var note = ""
    @State private var executor = ""
    @State private var reviewer = "最强大脑"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("新建任务").font(.title2.bold())
            TextField("标题", text: $title)
            TextField("备注", text: $note)
            Picker("执行人", selection: $executor) {
                ForEach(store.data.bots.map(\.name), id: \.self) { Text($0).tag($0) }
            }
            Picker("验收人", selection: $reviewer) {
                ForEach(store.data.bots.map(\.name) + ["用户"], id: \.self) { Text($0).tag($0) }
            }
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("添加") {
                    store.addTask(title: title, note: note, executor: executor, reviewer: reviewer)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            if executor.isEmpty { executor = store.data.bots.first(where: { $0.id != "chief" })?.name ?? store.data.bots.first?.name ?? "" }
        }
    }
}
