import SwiftUI
import AppKit

enum WebsiteViewMode: String { case list, cards }

struct ProjectsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var viewMode: WebsiteViewMode = .list
    @State private var categoryFilter: String = "全部"
    @State private var seoOnly = false
    @State private var detailId: String? = nil
    @State private var showCreate = false
    @State private var creating = WebsiteProject(id: "", name: "", category: "进行中", status: "in_progress")

    private var websites: [WebsiteProject] { store.data.websiteProjects ?? [] }
    private var products: [WorkbenchProject] { store.data.projects ?? [] }
    private var categories: [String] { ["全部"] + Array(Set(websites.map(\.category))).sorted() }

    private var filtered: [WebsiteProject] {
        let q = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return websites.filter { w in
            let catOK = categoryFilter == "全部" || w.category == categoryFilter
            let seoOK = !seoOnly || WebsiteFieldConfig.hasSeoService(w.services)
            guard catOK && seoOK else { return false }
            guard !q.isEmpty else { return true }
            let blob = [w.name, w.clientName ?? "", w.clientCompany ?? "", w.url ?? "", w.status, w.framework ?? ""].joined(separator: " ").lowercased()
            return blob.contains(q)
        }
        .sorted { a, b in
            let ua = a.updatedAt ?? ""
            let ub = b.updatedAt ?? ""
            if ua != ub { return ua > ub }
            return WebsiteFieldConfig.statusRank(a.status) < WebsiteFieldConfig.statusRank(b.status)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            toolbar
            if let sync = store.data.smartplanSync {
                Text("SmartPlan：\(sync.source ?? "?") · \(sync.count ?? 0) · 默认按最近更新")
                    .font(.caption2).foregroundStyle(SWTheme.textMuted)
            }
            if viewMode == .list { listView } else { cardsView }
        }
        .sheet(isPresented: Binding(get: { detailId != nil }, set: { if !$0 { detailId = nil } })) {
            if let id = detailId, let w = store.data.websiteProjects?.first(where: { $0.id == id }) {
                WebsiteDetailSheet(project: w) { detailId = nil }.environmentObject(store)
            }
        }
        .sheet(isPresented: $showCreate) {
            WebsiteEditorSheet(project: creating) { u in
                var x = u; x.dirty = true; x.localOnly = true
                store.upsertWebsiteProject(x); showCreate = false; detailId = x.id
            } onCancel: { showCreate = false }
        }
        .onAppear { applyShotMode() }
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Picker("", selection: $viewMode) {
                Text("列表").tag(WebsiteViewMode.list)
                Text("卡片").tag(WebsiteViewMode.cards)
            }.pickerStyle(.segmented).frame(width: 160)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(categories, id: \.self) { c in
                        let n = c == "全部" ? websites.count : websites.filter { $0.category == c }.count
                        chip("\(c) \(n)", active: categoryFilter == c) { categoryFilter = c }
                    }
                    chip("含 SEO/GEO", active: seoOnly) { seoOnly.toggle() }
                }
            }
            Spacer()
            if let p = products.first {
                Button {
                    if let u = p.run?.url, let url = URL(string: u) { NSWorkspace.shared.open(url) }
                    else { store.revealProject(p) }
                } label: { Label(p.shortName ?? p.name, systemImage: "shippingbox") }
                .buttonStyle(.bordered)
            }
            Button {
                creating = WebsiteProject(
                    id: UUID().uuidString.lowercased(), name: "新网站项目",
                    category: "进行中", status: "in_progress", framework: "React",
                    progress: 10, ownerBotId: "seo", source: "workbench",
                    dirty: true, localOnly: true, seoChecklist: Self.emptyChecklist()
                )
                showCreate = true
            } label: { Label("新建", systemImage: "plus") }
            .buttonStyle(.borderedProminent).tint(.black)
        }
    }

    private var listView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(WebsiteFieldConfig.listColumns, id: \.key) { col in
                    Text(col.title).font(.caption.weight(.semibold)).foregroundStyle(SWTheme.textMuted)
                        .frame(width: col.width, alignment: .leading)
                        .frame(maxWidth: col.width == nil ? .infinity : nil, alignment: .leading)
                }
            }.padding(.horizontal, 14).padding(.vertical, 8)
            Divider()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered) { w in
                        Button { detailId = w.id } label: { WebsiteListRow(project: w) }.buttonStyle(.plain)
                        Divider().opacity(0.45)
                    }
                }
            }
            .background(SWTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.panel))
            .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.panel).stroke(SWTheme.borderSoft))
        }
    }

    private var cardsView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: SWTheme.Website.cardMinWidth), spacing: 14)], spacing: 14) {
                ForEach(filtered) { w in
                    Button { detailId = w.id } label: { WebsiteProjectCard(project: w) }.buttonStyle(.plain)
                }
            }
            Spacer(minLength: 80)
        }
    }

    private func chip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action).buttonStyle(.plain)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(active ? SWTheme.accent : Color.white)
            .foregroundStyle(active ? Color.white : SWTheme.text)
            .clipShape(Capsule()).overlay(Capsule().stroke(SWTheme.borderSoft))
    }

    private func applyShotMode() {
        switch UserDefaults.standard.string(forKey: "SWShot") ?? "" {
        case "web-list": viewMode = .list
        case "web-cards": viewMode = .cards
        case "web-detail":
            viewMode = .list
            if let first = filtered.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { detailId = first.id }
            }
        default: break
        }
    }

    static func emptyChecklist() -> [String: SeoCheckItem] {
        var d: [String: SeoCheckItem] = [:]
        for item in WebsiteFieldConfig.seoChecklistTemplate {
            d[item.id] = SeoCheckItem(pass: false, priority: item.priority, note: "", updatedAt: nil)
        }
        return d
    }
}

struct WebsiteListRow: View {
    @EnvironmentObject var store: WorkspaceStore
    let project: WebsiteProject
    private var owner: Bot? {
        guard let id = project.ownerBotId, !id.isEmpty else { return nil }
        return store.data.bots.first { $0.id == id }
    }
    private var gradIndex: Int { abs(project.name.hashValue) % SWTheme.iconGradients.count }
    private var isOverdue: Bool {
        guard let d = project.deadline ?? project.serviceEndDate, d.count >= 10 else { return false }
        return String(d.prefix(10)) < String(ISO8601DateFormatter().string(from: Date()).prefix(10))
    }
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [SWTheme.iconGradients[gradIndex].0, SWTheme.iconGradients[gradIndex].1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(String(project.name.prefix(1))).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                }.frame(width: 28, height: 28)
                Text(project.name).font(.subheadline.weight(.semibold)).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading)
            StatusPill(status: project.status, category: project.category).frame(width: 88, alignment: .leading)
            Text(project.displayClient).font(.caption).foregroundStyle(SWTheme.textSecondary).lineLimit(1).frame(width: 130, alignment: .leading)
            Text(shortURL(project.url)).font(.caption.monospaced()).foregroundStyle(SWTheme.focus).lineLimit(1).frame(width: 140, alignment: .leading)
            Text(project.framework ?? "—").font(.caption2).frame(width: 72, alignment: .leading)
            Text((project.services ?? []).prefix(2).joined(separator: " · ")).font(.caption2).lineLimit(1).frame(width: 140, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                ProgressView(value: Double(project.displayProgress), total: 100).tint(SWTheme.websiteStatusColor(project.status))
                Text("\(project.displayProgress)%").font(.caption2).foregroundStyle(SWTheme.textMuted)
            }.frame(width: 100, alignment: .leading)
            Text(WebsiteFieldConfig.paymentLabel(project.paymentStatus)).font(.caption2).frame(width: 80, alignment: .leading)
            Text(project.displayDeadline).font(.caption.monospaced()).foregroundStyle(isOverdue ? Color.red : SWTheme.textSecondary).frame(width: 100, alignment: .leading)
            Group {
                if let owner {
                    BotAvatarView(url: owner.avatarURL, fallbackLetter: String(owner.name.prefix(1)), fontSize: 14)
                } else {
                    Image(systemName: "person.crop.circle").foregroundStyle(.secondary)
                }
            }.frame(width: 26, height: 26).clipShape(Circle()).frame(width: 72, alignment: .center)
            Text(relTime(project.updatedAt)).font(.caption2).foregroundStyle(SWTheme.textMuted).frame(width: 100, alignment: .leading).help(project.updatedAt ?? "")
        }
        .padding(.horizontal, 14).padding(.vertical, 10).contentShape(Rectangle()).background(SWTheme.card)
    }
    private func shortURL(_ u: String?) -> String {
        guard let u, !u.isEmpty else { return "—" }
        return u.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
    }
    private func relTime(_ iso: String?) -> String {
        guard let iso, !iso.isEmpty else { return "—" }
        return iso.count >= 10 ? String(iso.prefix(10)) : iso
    }
}

struct WebsiteProjectCard: View {
    let project: WebsiteProject
    @State private var hovering = false
    private var gradIndex: Int { abs(project.name.hashValue) % SWTheme.iconGradients.count }
    private var codeLabel: String { String((project.framework ?? "WEB").uppercased().prefix(4)) }
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            ZStack {
                Circle().fill(LinearGradient(colors: [SWTheme.iconGradients[gradIndex].0, SWTheme.iconGradients[gradIndex].1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: SWTheme.Website.iconSize, height: SWTheme.Website.iconSize)
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
                Text(String(project.name.prefix(1))).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
            }
            Text(codeLabel).font(.system(size: 13, weight: .medium)).foregroundStyle(SWTheme.textMuted).padding(.top, 10)
            HStack(spacing: 4) {
                Circle().fill(SWTheme.websiteStatusColor(project.status)).frame(width: 5, height: 5)
                Circle().fill(Color.black.opacity(0.12)).frame(width: 5, height: 5)
                Circle().fill(Color.black.opacity(0.12)).frame(width: 5, height: 5)
            }.padding(.top, 6)
            Spacer(minLength: 12)
            HStack {
                Text(codeLabel).font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(SWTheme.accent).clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.badge))
                Spacer()
                StatusPill(status: project.status, category: project.category, progress: project.displayProgress)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name).font(.system(size: 18, weight: .bold)).foregroundStyle(SWTheme.text).lineLimit(1)
                Text("\(project.displayClient) · \(project.framework ?? "—")").font(.system(size: 12)).foregroundStyle(SWTheme.textSecondary).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
        }
        .padding(.horizontal, 16).padding(.bottom, 16)
        .frame(maxWidth: .infinity).frame(minHeight: SWTheme.Website.cardMinHeight)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.card).stroke(SWTheme.borderSoft))
        .shadow(color: .black.opacity(hovering ? 0.12 : 0.06), radius: hovering ? 16 : 8, y: hovering ? 10 : 4)
        .scaleEffect(hovering ? 1.02 : 1).onHover { hovering = $0 }
    }
}

struct WebsiteDetailSheet: View {
    @EnvironmentObject var store: WorkspaceStore
    @State var project: WebsiteProject
    var onClose: () -> Void
    @State private var section = 0
    @State private var gateMessage = ""
    @State private var adminOverride = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [SWTheme.iconGradients[0].0, SWTheme.iconGradients[0].1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(String(project.name.prefix(1))).font(.title3.bold()).foregroundStyle(.white)
                }.frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(project.name).font(.title3.bold())
                        StatusPill(status: project.status, category: project.category, progress: project.displayProgress)
                        if project.dirty == true { TagChip(text: "待写回", color: .orange) }
                    }
                    Text(project.url?.isEmpty == false ? (project.url ?? "") : "未配置线上网址").font(.caption.monospaced()).foregroundStyle(SWTheme.focus)
                    if WebsiteFieldConfig.hasSeoService(project.services) {
                        let fail = WebsiteFieldConfig.p0FailedCount(project)
                        Text(fail == 0 ? "SEO P0 全部通过" : "SEO P0 未通过 \(fail) 项").font(.caption2).foregroundStyle(fail == 0 ? Color.green : Color.orange)
                    }
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").frame(width: SWTheme.Website.closeBtn, height: SWTheme.Website.closeBtn)
                }.buttonStyle(.bordered).keyboardShortcut(.cancelAction)
            }.padding(16).background(SWTheme.card)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(WebsiteFieldConfig.detailSections.enumerated()), id: \.offset) { i, s in
                        Button(s.title) { section = i }.buttonStyle(.plain)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(section == i ? SWTheme.accent : Color.white)
                            .foregroundStyle(section == i ? Color.white : SWTheme.text)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(SWTheme.borderSoft))
                    }
                }.padding(.horizontal, 16).padding(.vertical, 10)
            }.background(SWTheme.pageBg)

            ScrollView {
                Group {
                    switch section {
                    case 0: basicSection
                    case 1: clientSection
                    case 2: hostingSection
                    case 3: seoSection
                    case 4: progressSection
                    default: notesSection
                    }
                }.padding(20)
            }.background(SWTheme.pageBg)

            VStack(alignment: .leading, spacing: 8) {
                if !gateMessage.isEmpty { Text(gateMessage).font(.caption).foregroundStyle(.red) }
                HStack {
                    ForEach(WebsiteFieldConfig.statusOptions, id: \.status) { opt in
                        Button(opt.label) { trySetStatus(opt) }.buttonStyle(.bordered)
                    }
                    Toggle("管理员覆盖 P0", isOn: $adminOverride).toggleStyle(.checkbox)
                    Spacer()
                    Button("保存") {
                        project.dirty = true
                        store.upsertWebsiteProject(project)
                        onClose()
                    }.buttonStyle(.borderedProminent).tint(.black)
                }
            }.padding(16).background(SWTheme.card).overlay(alignment: .top) { Divider() }
        }
        .frame(width: SWTheme.Website.detailWidth, height: min(SWTheme.Website.detailMaxHeight, 780))
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.modal))
        .background(SWTheme.pageBg)
        .onAppear {
            if project.seoChecklist == nil, WebsiteFieldConfig.hasSeoService(project.services) {
                project.seoChecklist = ProjectsView.emptyChecklist()
            }
        }
    }

    private func trySetStatus(_ opt: (status: String, category: String, label: String, progress: Int)) {
        if let err = WebsiteFieldConfig.canTransition(from: project.status, to: opt.status, project: project, adminOverride: adminOverride) {
            gateMessage = err; return
        }
        gateMessage = ""
        project.status = opt.status
        project.category = opt.category
        project.progress = opt.progress
        project.dirty = true
    }

    private var basicSection: some View {
        panel("基本信息") {
            field("项目名称", $project.name)
            field("描述", Binding(get: { project.detail ?? "" }, set: { project.detail = $0 }))
            field("框架", Binding(get: { project.framework ?? "" }, set: { project.framework = $0 }))
            field("服务(逗号)", Binding(
                get: { (project.services ?? []).joined(separator: ", ") },
                set: { project.services = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
            ))
            Picker("负责人", selection: Binding(get: { project.ownerBotId ?? "" }, set: { project.ownerBotId = $0 })) {
                Text("未指定").tag("")
                ForEach(store.data.bots.filter { $0.belongs(to: "网站项目") }) { b in Text(b.name).tag(b.id) }
            }
            Text("ID \(project.id) · source \(project.source ?? "—")").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var clientSection: some View {
        panel("客户（不含电话/微信/邮箱）") {
            field("客户姓名", Binding(get: { project.clientName ?? "" }, set: { project.clientName = $0 }))
            field("客户公司", Binding(get: { project.clientCompany ?? "" }, set: { project.clientCompany = $0 }))
            num("合同总额", Binding(get: { project.totalAmount ?? 0 }, set: { project.totalAmount = $0 }))
            num("定金", Binding(get: { project.depositAmount ?? 0 }, set: { project.depositAmount = $0 }))
            num("已付", Binding(get: { project.paidAmount ?? 0 }, set: { project.paidAmount = $0 }))
            num("未付", Binding(get: { project.unpaidAmount ?? 0 }, set: { project.unpaidAmount = $0 }))
            Picker("付款", selection: Binding(get: { project.paymentStatus ?? "pending" }, set: { project.paymentStatus = $0 })) {
                Text("待付款").tag("pending"); Text("已付定金").tag("deposit_paid"); Text("已结清").tag("fully_paid")
            }
            field("服务开始", Binding(get: { project.serviceStartDate ?? "" }, set: { project.serviceStartDate = $0 }))
            field("服务截止", Binding(get: { project.deadline ?? project.serviceEndDate ?? "" }, set: { project.deadline = $0; project.serviceEndDate = $0 }))
        }
    }

    private var hostingSection: some View {
        panel("域名和主机（工作台侧，未改 SmartPlan 表）") {
            field("线上网址", Binding(get: { project.url ?? "" }, set: { project.url = $0 }))
            field("本地路径", Binding(get: { project.localPath ?? "" }, set: { project.localPath = $0 }))
            field("主域名", Binding(get: { project.primaryDomain ?? "" }, set: { project.primaryDomain = $0 }))
            field("主机商", Binding(get: { project.hostingProvider ?? "" }, set: { project.hostingProvider = $0 }))
            field("部署环境", Binding(get: { project.deployEnv ?? "" }, set: { project.deployEnv = $0 }))
            field("CDN", Binding(get: { project.cdnProvider ?? "" }, set: { project.cdnProvider = $0 }))
            field("SSL", Binding(get: { project.sslStatus ?? "" }, set: { project.sslStatus = $0 }))
            field("主机备注(禁密码)", Binding(get: { project.hostingNotes ?? "" }, set: { project.hostingNotes = $0 }))
        }
    }

    private var seoSection: some View {
        panel("SEO 状态 · P0 门禁") {
            HStack {
                Text("SEO \(project.seoScore.map(String.init) ?? "—")")
                Text("GEO \(project.geoScore.map(String.init) ?? "—")")
                Text("体检 \(project.seoLastAuditAt ?? "—")").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(WebsiteFieldConfig.seoChecklistTemplate, id: \.id) { item in
                Toggle(isOn: Binding(
                    get: { project.seoChecklist?[item.id]?.pass == true },
                    set: { v in
                        var map = project.seoChecklist ?? [:]
                        var cur = map[item.id] ?? SeoCheckItem(pass: false, priority: item.priority, note: "", updatedAt: nil)
                        cur.pass = v; cur.priority = item.priority
                        cur.updatedAt = ISO8601DateFormatter().string(from: Date())
                        map[item.id] = cur; project.seoChecklist = map
                    }
                )) {
                    HStack {
                        Text(item.priority).font(.caption2.bold())
                            .foregroundStyle(item.priority == "P0" ? Color.red : (item.priority == "P1" ? Color.orange : Color.secondary))
                        Text(item.name).font(.subheadline)
                        Text(item.track).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        panel("进度和里程碑") {
            Stepper("进度 \(project.progress ?? 0)%", value: Binding(get: { project.progress ?? 0 }, set: { project.progress = $0 }), in: 0...100, step: 5)
            ProgressView(value: Double(project.displayProgress), total: 100)
            Text("跟进记录请在 SmartPlan Hub 查看").font(.caption).foregroundStyle(.secondary)
        }
    }

    private var notesSection: some View {
        panel("备注和链接") {
            field("备注", Binding(get: { project.notes ?? project.detail ?? "" }, set: { project.notes = $0 }))
            field("设计稿", Binding(get: { project.designUrl ?? "" }, set: { project.designUrl = $0 }))
            field("仓库", Binding(get: { project.repoUrl ?? "" }, set: { project.repoUrl = $0 }))
            field("GSC 深链", Binding(get: { project.gscPropertyUrl ?? "" }, set: { project.gscPropertyUrl = $0 }))
            Text("同步不写回电话/微信/邮箱/凭证。").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func panel<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(SWTheme.textMuted)
            content()
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.panel))
        .overlay(RoundedRectangle(cornerRadius: SWTheme.Radius.panel).stroke(SWTheme.borderSoft))
    }

    private func field(_ label: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(label).frame(width: 100, alignment: .leading).font(.caption).foregroundStyle(.secondary)
            TextField(label, text: text).textFieldStyle(.roundedBorder)
        }
    }
    private func num(_ label: String, _ value: Binding<Double>) -> some View {
        HStack {
            Text(label).frame(width: 100, alignment: .leading).font(.caption).foregroundStyle(.secondary)
            TextField(label, value: value, format: .number).textFieldStyle(.roundedBorder)
        }
    }
}

struct WebsiteEditorSheet: View {
    @State var project: WebsiteProject
    var onSave: (WebsiteProject) -> Void
    var onCancel: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("新建网站项目").font(.title2.bold())
            TextField("名称", text: $project.name)
            TextField("客户", text: Binding(get: { project.clientName ?? "" }, set: { project.clientName = $0 }))
            TextField("URL", text: Binding(get: { project.url ?? "" }, set: { project.url = $0 }))
            HStack {
                Button("取消", action: onCancel); Spacer()
                Button("创建") { onSave(project) }.buttonStyle(.borderedProminent).tint(.black)
            }
        }.padding(24).frame(width: 420, height: 260)
    }
}
