import SwiftUI
import AppKit

enum WebsiteViewMode: String {
    case list, cards
}

struct ProjectsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var viewMode: WebsiteViewMode = .list
    @State private var categoryFilter: String = "全部"
    @State private var detailId: String? = nil
    @State private var showEditor = false
    @State private var creating: WebsiteProject? = nil

    private var websites: [WebsiteProject] { store.data.websiteProjects ?? [] }
    private var products: [WorkbenchProject] { store.data.projects ?? [] }

    private var categories: [String] {
        ["全部"] + Array(Set(websites.map(\.category))).sorted()
    }

    private var filtered: [WebsiteProject] {
        let q = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return websites.filter { w in
            let catOK = categoryFilter == "全部" || w.category == categoryFilter
            guard catOK else { return false }
            guard !q.isEmpty else { return true }
            let blob = [w.name, w.clientName ?? "", w.clientCompany ?? "", w.url ?? "", w.status].joined(separator: " ").lowercased()
            return blob.contains(q)
        }.sorted { a, b in
            statusRank(a.status) < statusRank(b.status)
        }
    }

    private var detailProject: WebsiteProject? {
        websites.first { $0.id == detailId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Picker("", selection: $viewMode) {
                    Text("列表").tag(WebsiteViewMode.list)
                    Text("卡片").tag(WebsiteViewMode.cards)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.self) { c in
                            let n = c == "全部" ? websites.count : websites.filter { $0.category == c }.count
                            Button(c == "全部" ? "全部 \(n)" : "\(c) \(n)") { categoryFilter = c }
                                .buttonStyle(.bordered)
                                .tint(categoryFilter == c ? .black : .gray)
                        }
                    }
                }

                Spacer()

                if let p = products.first {
                    Button {
                        if let url = p.run?.url, let u = URL(string: url) {
                            NSWorkspace.shared.open(u)
                        } else {
                            store.revealProject(p)
                        }
                    } label: {
                        Label(p.shortName ?? p.name, systemImage: "shippingbox")
                    }
                    .buttonStyle(.bordered)
                    .help("产品项目 · 智能日程管理（不混入网站列表）")
                }

                Button {
                    let neu = WebsiteProject(
                        id: UUID().uuidString.lowercased(),
                        name: "新网站项目",
                        category: "进行中",
                        status: "in_progress",
                        localPath: "",
                        url: "",
                        framework: "React",
                        detail: "",
                        clientName: "",
                        clientCompany: "",
                        totalAmount: 0, depositAmount: 0, paidAmount: 0, unpaidAmount: 0,
                        paymentStatus: "pending",
                        services: [],
                        serviceStartDate: "", serviceEndDate: "", deadline: "",
                        progress: 10, ownerBotId: "seo",
                        source: "workbench", dirty: true, localOnly: true
                    )
                    creating = neu
                    showEditor = true
                } label: { Label("新建", systemImage: "plus") }
                .buttonStyle(.borderedProminent).tint(.black)
            }

            if let sync = store.data.smartplanSync {
                Text("SmartPlan：\(sync.source ?? "?") · \(sync.count ?? 0) 条 · \(sync.direction ?? "") · \(sync.lastSyncAt ?? "")")
                    .font(.caption2).foregroundStyle(.secondary)
            }

            if viewMode == .list {
                listView
            } else {
                cardsView
            }
        }
        .sheet(isPresented: Binding(
            get: { detailId != nil },
            set: { if !$0 { detailId = nil } }
        )) {
            if let id = detailId, let w = store.data.websiteProjects?.first(where: { $0.id == id }) {
                WebsiteDetailSheet(project: w) { detailId = nil }
                    .environmentObject(store)
            } else {
                Text("项目不存在").padding(24)
            }
        }
        .sheet(isPresented: $showEditor) {
            if let creating {
                WebsiteEditorSheet(project: creating) { updated in
                    var u = updated
                    u.dirty = true
                    store.upsertWebsiteProject(u)
                    showEditor = false
                    detailId = u.id
                } onCancel: { showEditor = false }
            }
        }
        .onAppear { applyShotMode() }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("项目").frame(maxWidth: .infinity, alignment: .leading)
                Text("客户").frame(width: 140, alignment: .leading)
                Text("状态").frame(width: 90, alignment: .leading)
                Text("进度").frame(width: 120, alignment: .leading)
                Text("截止").frame(width: 100, alignment: .leading)
                Text("负责人").frame(width: 72, alignment: .center)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { w in
                        Button { detailId = w.id } label: {
                            WebsiteListRow(project: w)
                        }
                        .buttonStyle(.plain)
                        Divider().opacity(0.5)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06)))
        }
    }

    private var cardsView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: SWTheme.Website.cardMinWidth), spacing: 14)], spacing: 14) {
                ForEach(filtered) { w in
                    Button { detailId = w.id } label: {
                        WebsiteProjectCard(project: w)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 80)
        }
    }

    private func statusRank(_ s: String) -> Int {
        switch s {
        case "in_progress": return 0
        case "delivered": return 1
        case "infrastructure": return 2
        default: return 9
        }
    }

    private func applyShotMode() {
        let mode = UserDefaults.standard.string(forKey: "SWShot") ?? ""
        switch mode {
        case "web-list": viewMode = .list
        case "web-cards": viewMode = .cards
        case "web-detail":
            viewMode = .list
            if let first = filtered.first ?? websites.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    detailId = first.id
                }
            }
        default: break
        }
    }
}

struct WebsiteListRow: View {
    @EnvironmentObject var store: WorkspaceStore
    let project: WebsiteProject

    private var owner: Bot? {
        guard let id = project.ownerBotId, !id.isEmpty else { return nil }
        return store.data.bots.first { $0.id == id }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(statusTint.opacity(0.15))
                Text(initials(project.name))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(statusTint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(project.framework ?? "—").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(project.displayClient)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            TagChip(text: project.category, color: statusTint)
                .frame(width: 90, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                ProgressView(value: Double(project.displayProgress), total: 100)
                    .tint(statusTint)
                Text("\(project.displayProgress)%").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 120, alignment: .leading)

            Text(project.deadline ?? project.serviceEndDate ?? "—")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Group {
                if let owner, let img = NSImage(contentsOf: owner.avatarURL) {
                    Image(nsImage: img).resizable().scaledToFill()
                } else if let owner {
                    Text(String(owner.name.prefix(1)))
                        .font(.caption.bold()).frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.2))
                } else {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
            .frame(width: 72, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(Color.white)
    }

    private var statusTint: Color {
        SWTheme.websiteStatusColor(project.status)
    }

    private func initials(_ name: String) -> String {
        let cleaned = name.trimmingCharacters(in: .whitespaces)
        return String(cleaned.prefix(2)).uppercased()
    }
}

struct WebsiteProjectCard: View {
    let project: WebsiteProject
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 14)
            ZStack {
                Circle().fill(Color.white)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                ZStack {
                    Circle().fill(statusTint.opacity(0.18))
                    Text(String(project.name.prefix(1)).uppercased())
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(statusTint)
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
            }

            Spacer(minLength: 12)

            HStack {
                Text(project.framework?.prefix(6) ?? "WEB")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
                TagChip(text: project.category, color: statusTint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(project.name)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                Text(project.displayClient)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.45))
                    .lineLimit(1)
                ProgressView(value: Double(project.displayProgress), total: 100)
                    .tint(statusTint)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .frame(minHeight: SWTheme.Website.cardMinHeight)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Website.cardCorner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.Website.cardCorner).stroke(Color.black.opacity(0.06)))
        .shadow(color: .black.opacity(hovering ? 0.12 : 0.05), radius: hovering ? 14 : 8, y: hovering ? 8 : 3)
        .scaleEffect(hovering ? 1.02 : 1)
        .onHover { hovering = $0 }
    }

    private var statusTint: Color {
        SWTheme.websiteStatusColor(project.status)
    }
}

struct WebsiteDetailSheet: View {
    @EnvironmentObject var store: WorkspaceStore
    @State var project: WebsiteProject
    var onClose: () -> Void
    @State private var tab: Int = 0 // 0 CRM 1 Finance 2 Tech

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.black)
                    Image(systemName: "globe").foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name).font(.title3.bold())
                        TagChip(text: project.category, color: .blue)
                        if project.dirty == true { TagChip(text: "待写回", color: .orange) }
                    }
                    HStack(spacing: 8) {
                        if let url = project.url, !url.isEmpty {
                            Link(url.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""),
                                 destination: URL(string: url) ?? URL(string: "about:blank")!)
                                .font(.caption.monospaced())
                        } else {
                            Text("未配置线上网址").font(.caption).foregroundStyle(.secondary)
                        }
                        if let path = project.localPath, !path.isEmpty {
                            Text("· \(path)").font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                        }
                    }
                    if let services = project.services, !services.isEmpty {
                        HStack(spacing: 4) {
                            Text("已订服务:").font(.caption2).foregroundStyle(.secondary)
                            ForEach(services, id: \.self) { TagChip(text: $0, color: .gray) }
                        }
                    }
                }
                Spacer()
                Button("关闭", action: onClose).keyboardShortcut(.cancelAction)
            }
            .padding(16)
            .background(Color.white)

            // Tabs (omit assets/credentials)
            HStack(spacing: 8) {
                tabBtn("客户与服务", 0)
                tabBtn("财务款项", 1)
                tabBtn("技术与进度", 2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.03))

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if tab == 0 { crmTab }
                    if tab == 1 { financeTab }
                    if tab == 2 { techTab }
                }
                .padding(20)
            }

            HStack {
                statusQuick
                Spacer()
                Button("保存并标记写回") {
                    project.dirty = true
                    store.upsertWebsiteProject(project)
                    onClose()
                }
                .buttonStyle(.borderedProminent).tint(.black)
            }
            .padding(16)
            .background(Color.white)
            .overlay(alignment: .top) { Divider() }
        }
        .frame(width: SWTheme.Website.detailWidth, height: SWTheme.Website.detailHeight)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var statusQuick: some View {
        HStack {
            ForEach(WebsiteFieldConfig.statusOptions, id: \.status) { opt in
                Button(opt.label) {
                    project.status = opt.status
                    project.category = opt.category
                    project.progress = opt.progress
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var crmTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            section("客户资料") {
                field("客户名", Binding(get: { project.clientName ?? "" }, set: { project.clientName = $0 }))
                field("公司", Binding(get: { project.clientCompany ?? "" }, set: { project.clientCompany = $0 }))
                Text("联系方式不同步到工作台（电话/微信/邮箱仅留在 SmartPlan）")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            section("服务周期") {
                field("开始", Binding(get: { project.serviceStartDate ?? "" }, set: { project.serviceStartDate = $0 }))
                field("截止", Binding(get: { project.deadline ?? project.serviceEndDate ?? "" }, set: {
                    project.deadline = $0; project.serviceEndDate = $0
                }))
            }
            section("已订服务（逗号分隔）") {
                field("服务", Binding(
                    get: { (project.services ?? []).joined(separator: ", ") },
                    set: { project.services = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                ))
            }
            section("负责人") {
                Picker("员工", selection: Binding(get: { project.ownerBotId ?? "" }, set: { project.ownerBotId = $0 })) {
                    Text("未指定").tag("")
                    ForEach(store.data.bots.filter { $0.belongs(to: "网站项目") || ["seo","coo","chief"].contains($0.id) }) { b in
                        Text(b.name).tag(b.id)
                    }
                }
            }
        }
    }

    private var financeTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            section("财务金额") {
                numField("总额", Binding(get: { project.totalAmount ?? 0 }, set: { project.totalAmount = $0 }))
                numField("定金", Binding(get: { project.depositAmount ?? 0 }, set: { project.depositAmount = $0 }))
                numField("已付", Binding(get: { project.paidAmount ?? 0 }, set: { project.paidAmount = $0 }))
                numField("未付", Binding(get: { project.unpaidAmount ?? 0 }, set: { project.unpaidAmount = $0 }))
                Picker("付款状态", selection: Binding(get: { project.paymentStatus ?? "pending" }, set: { project.paymentStatus = $0 })) {
                    Text("待付").tag("pending")
                    Text("已付定金").tag("deposit_paid")
                    Text("已结清").tag("fully_paid")
                }
            }
        }
    }

    private var techTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            section("技术信息") {
                field("名称", Binding(get: { project.name }, set: { project.name = $0 }))
                field("URL", Binding(get: { project.url ?? "" }, set: { project.url = $0 }))
                field("框架", Binding(get: { project.framework ?? "" }, set: { project.framework = $0 }))
                field("本地路径", Binding(get: { project.localPath ?? "" }, set: { project.localPath = $0 }))
                field("描述", Binding(get: { project.detail ?? "" }, set: { project.detail = $0 }))
            }
            section("进度") {
                Stepper("进度 \(project.progress ?? 0)%", value: Binding(get: { project.progress ?? 0 }, set: { project.progress = $0 }), in: 0...100, step: 5)
                ProgressView(value: Double(project.displayProgress), total: 100)
            }
            Text("点工作台「同步」会执行 sync-smartplan --push 写回 SmartPlan（不含凭证字段）。")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func tabBtn(_ title: String, _ i: Int) -> some View {
        Button(title) { tab = i }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tab == i ? Color.black : Color.white)
            .foregroundStyle(tab == i ? Color.white : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.08)))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06)))
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 72, alignment: .leading).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: text).textFieldStyle(.roundedBorder)
        }
    }

    private func numField(_ label: String, _ value: Binding<Double>) -> some View {
        HStack {
            Text(label).frame(width: 72, alignment: .leading).font(.caption).foregroundStyle(.secondary)
            TextField(label, value: value, format: .number).textFieldStyle(.roundedBorder)
        }
    }
}

struct WebsiteEditorSheet: View {
    @State var project: WebsiteProject
    var onSave: (WebsiteProject) -> Void
    var onCancel: () -> Void
    @EnvironmentObject var store: WorkspaceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("新建网站项目").font(.title2.bold())
            Form {
                TextField("名称", text: $project.name)
                TextField("客户", text: Binding(get: { project.clientName ?? "" }, set: { project.clientName = $0 }))
                TextField("URL", text: Binding(get: { project.url ?? "" }, set: { project.url = $0 }))
            }
            HStack {
                Button("取消", action: onCancel)
                Spacer()
                Button("创建") { project.dirty = true; project.localOnly = true; onSave(project) }
                    .buttonStyle(.borderedProminent).tint(.black)
            }
        }
        .padding(24)
        .frame(width: 420, height: 280)
    }
}
