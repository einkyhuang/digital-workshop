import SwiftUI
import AppKit

struct ProjectsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var tab: Int = 1 // default 网站项目 (user asked for list/management)
    @State private var selectedProductId: String?
    @State private var selectedWebId: String?
    @State private var categoryFilter: String = "全部"
    @State private var showEditor = false
    @State private var editing: WebsiteProject?

    private var products: [WorkbenchProject] { store.data.projects ?? [] }
    private var websites: [WebsiteProject] { store.data.websiteProjects ?? [] }

    private var categories: [String] {
        let cats = Array(Set(websites.map(\.category))).sorted()
        return ["全部"] + cats
    }

    private var filteredWebsites: [WebsiteProject] {
        let q = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return websites.filter { w in
            let catOK = categoryFilter == "全部" || w.category == categoryFilter
            guard catOK else { return false }
            guard !q.isEmpty else { return true }
            let blob = [w.name, w.clientName ?? "", w.clientCompany ?? "", w.url ?? "", w.status].joined(separator: " ").lowercased()
            return blob.contains(q)
        }
    }

    private var selectedProduct: WorkbenchProject? {
        products.first { $0.id == selectedProductId } ?? products.first
    }
    private var selectedWeb: WebsiteProject? {
        filteredWebsites.first { $0.id == selectedWebId } ?? filteredWebsites.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $tab) {
                Text("网站项目 (\(websites.count))").tag(1)
                Text("产品项目 (\(products.count))").tag(0)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 420)

            if let sync = store.data.smartplanSync {
                Text("SmartPlan 同步：\(sync.source ?? "?") · \(sync.count ?? 0) 条 · \(sync.lastSyncAt ?? "") · \(sync.direction ?? "")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if tab == 1 {
                webProjectsPane
            } else {
                productProjectsPane
            }
        }
        .sheet(isPresented: $showEditor) {
            if let editing {
                WebsiteEditorSheet(project: editing) { updated in
                    var u = updated
                    u.dirty = true
                    if u.localOnly != true { u.localOnly = updated.localOnly }
                    store.upsertWebsiteProject(u)
                    selectedWebId = u.id
                    showEditor = false
                } onCancel: { showEditor = false }
            }
        }
    }

    private var webProjectsPane: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("网站项目列表").font(.headline)
                    Spacer()
                    Button {
                        let id = UUID().uuidString.lowercased()
                        editing = WebsiteProject(
                            id: id, name: "新网站项目", category: "进行中", status: "in_progress",
                            localPath: "", url: "", framework: "React", detail: "",
                            clientName: "", clientCompany: "", totalAmount: 0, depositAmount: 0,
                            paidAmount: 0, unpaidAmount: 0, paymentStatus: "pending",
                            services: [], serviceStartDate: "", serviceEndDate: "", deadline: "",
                            progress: 10, ownerBotId: "seo", source: "workbench", dirty: true, localOnly: true
                        )
                        showEditor = true
                    } label: { Label("新建", systemImage: "plus") }
                    .buttonStyle(.borderedProminent).tint(.black)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.self) { c in
                            let count = c == "全部" ? websites.count : websites.filter { $0.category == c }.count
                            Button(c == "全部" ? "全部 \(count)" : "\(c) \(count)") { categoryFilter = c }
                                .buttonStyle(.bordered)
                                .tint(categoryFilter == c ? .black : .gray)
                        }
                    }
                }
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredWebsites) { w in
                            Button { selectedWebId = w.id } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(w.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                                        Text(w.displayClient).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        TagChip(text: w.category, color: categoryColor(w.category))
                                        Text("\(w.displayProgress)%").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(10)
                                .background(selectedWeb?.id == w.id ? Color.black.opacity(0.06) : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(width: 300)

            if let w = selectedWeb {
                WebsiteDetailPane(project: w, onEdit: {
                    editing = w
                    showEditor = true
                }, onStatus: { status, category in
                    store.markWebsiteDirty(w.id) { item in
                        item.status = status
                        item.category = category
                        item.progress = defaultProgress(status)
                    }
                })
            } else {
                Text("暂无网站项目 — 点「同步」从 SmartPlan 导入").foregroundStyle(.secondary)
            }
        }
    }

    private var productProjectsPane: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("产品项目").font(.headline)
                ForEach(products) { p in
                    Button { selectedProductId = p.id } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.subheadline.weight(.semibold))
                                Text(p.category).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            TagChip(text: p.status, color: .blue)
                        }
                        .padding(12)
                        .background(selectedProduct?.id == p.id ? Color.black.opacity(0.06) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(width: 260)
            if let p = selectedProduct {
                ProjectDetailPane(project: p)
            } else {
                Text("暂无产品项目").foregroundStyle(.secondary)
            }
        }
    }

    private func categoryColor(_ c: String) -> Color {
        switch c {
        case "进行中": return .blue
        case "已交付": return .green
        case "功能基础建设": return .purple
        case "已暂停/挂了", "挂了": return .orange
        default: return .gray
        }
    }

    private func defaultProgress(_ status: String) -> Int {
        switch status {
        case "delivered": return 100
        case "in_progress": return 55
        case "infrastructure": return 25
        case "inactive": return 0
        default: return 40
        }
    }
}

struct WebsiteDetailPane: View {
    @EnvironmentObject var store: WorkspaceStore
    let project: WebsiteProject
    var onEdit: () -> Void
    var onStatus: (String, String) -> Void

    private var owner: Bot? {
        guard let id = project.ownerBotId, !id.isEmpty else { return nil }
        return store.data.bots.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name).font(.system(size: 24, weight: .bold))
                        Text(project.displayClient).foregroundStyle(.secondary)
                        HStack {
                            TagChip(text: project.category, color: .blue)
                            TagChip(text: project.status, color: .gray)
                            if project.dirty == true { TagChip(text: "待写回", color: .orange) }
                        }
                    }
                    Spacer()
                    Button("编辑", action: onEdit).buttonStyle(.borderedProminent).tint(.black)
                }

                ProgressView(value: Double(project.displayProgress), total: 100) {
                    Text("进度 \(project.displayProgress)%")
                }

                groupBox("客户与商务") {
                    gridRow("客户", project.clientName ?? "—")
                    gridRow("公司", project.clientCompany ?? "—")
                    gridRow("付款", project.paymentStatus ?? "—")
                    gridRow("金额", amountLine)
                    gridRow("服务期", "\(project.serviceStartDate ?? "—") → \(project.deadline ?? project.serviceEndDate ?? "—")")
                }
                groupBox("技术") {
                    gridRow("框架", project.framework ?? "—")
                    gridRow("URL", project.url?.isEmpty == false ? (project.url ?? "") : "—")
                    gridRow("本地路径", project.localPath ?? "—")
                    gridRow("服务", (project.services ?? []).joined(separator: " · ").ifEmpty("—"))
                    Text(project.detail ?? "").font(.body).padding(.top, 4)
                }
                groupBox("负责人") {
                    if let owner {
                        Text("\(owner.name)").font(.subheadline.weight(.semibold))
                    } else {
                        Text("未指定（可在编辑里选员工）").foregroundStyle(.secondary)
                    }
                }
                groupBox("快捷改状态") {
                    HStack {
                        statusBtn("进行中", "in_progress", "进行中")
                        statusBtn("已交付", "delivered", "已交付")
                        statusBtn("基建中", "infrastructure", "功能基础建设")
                        statusBtn("挂起", "inactive", "已暂停/挂了")
                    }
                }
                Text("写回说明：点顶部「同步」会先跑 sync-smartplan --push（API PUT 更新；新建走 SQLite）。不写回电话/微信/邮箱/凭证。")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer(minLength: 60)
            }
        }
    }

    private var amountLine: String {
        let t = project.totalAmount ?? 0
        let p = project.paidAmount ?? 0
        let u = project.unpaidAmount ?? 0
        return String(format: "总额 %.0f · 已付 %.0f · 未付 %.0f", t, p, u)
    }

    private func statusBtn(_ title: String, _ status: String, _ category: String) -> some View {
        Button(title) { onStatus(status, category) }.buttonStyle(.bordered)
    }

    private func gridRow(_ k: String, _ v: String) -> some View {
        HStack(alignment: .top) {
            Text(k).font(.caption).foregroundStyle(.secondary).frame(width: 72, alignment: .leading)
            Text(v).font(.subheadline).textSelection(.enabled)
            Spacer()
        }
    }

    private func groupBox<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06)))
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}

struct WebsiteEditorSheet: View {
    @State var project: WebsiteProject
    var onSave: (WebsiteProject) -> Void
    var onCancel: () -> Void
    @EnvironmentObject var store: WorkspaceStore

    private let statusOptions: [(String, String)] = [
        ("in_progress", "进行中"),
        ("delivered", "已交付"),
        ("infrastructure", "功能基础建设"),
        ("inactive", "已暂停/挂了")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(project.localOnly == true ? "新建网站项目" : "编辑网站项目").font(.title2.bold())
            Form {
                TextField("名称", text: Binding(get: { project.name }, set: { project.name = $0 }))
                TextField("客户名", text: Binding(get: { project.clientName ?? "" }, set: { project.clientName = $0 }))
                TextField("客户公司", text: Binding(get: { project.clientCompany ?? "" }, set: { project.clientCompany = $0 }))
                TextField("URL", text: Binding(get: { project.url ?? "" }, set: { project.url = $0 }))
                TextField("框架", text: Binding(get: { project.framework ?? "" }, set: { project.framework = $0 }))
                TextField("截止日期 (YYYY-MM-DD)", text: Binding(get: { project.deadline ?? project.serviceEndDate ?? "" }, set: { project.deadline = $0; project.serviceEndDate = $0 }))
                TextField("描述", text: Binding(get: { project.detail ?? "" }, set: { project.detail = $0 }))
                Picker("状态", selection: Binding(get: { project.status }, set: { new in
                    project.status = new
                    if let cat = statusOptions.first(where: { $0.0 == new })?.1 { project.category = cat }
                })) {
                    ForEach(statusOptions, id: \.0) { Text($0.1).tag($0.0) }
                }
                Stepper("进度 \(project.progress ?? 0)%", value: Binding(get: { project.progress ?? 0 }, set: { project.progress = $0 }), in: 0...100, step: 5)
                Picker("负责人", selection: Binding(get: { project.ownerBotId ?? "" }, set: { project.ownerBotId = $0 })) {
                    Text("未指定").tag("")
                    ForEach(store.data.bots.filter { $0.belongs(to: "网站项目") || $0.id == "seo" || $0.id == "coo" }) { b in
                        Text(b.name).tag(b.id)
                    }
                }
            }
            HStack {
                Button("取消", action: onCancel)
                Spacer()
                Button("保存") {
                    project.dirty = true
                    onSave(project)
                }
                .buttonStyle(.borderedProminent).tint(.black)
            }
        }
        .padding(24)
        .frame(width: 520, height: 560)
    }
}

struct ProjectDetailPane: View {
    @EnvironmentObject var store: WorkspaceStore
    let project: WorkbenchProject

    private var owner: Bot? { store.data.bots.first { $0.id == project.ownerBotId } }
    private var collabs: [Bot] {
        project.collabBotIds.compactMap { id in store.data.bots.first { $0.id == id } }
    }
    private var relatedTasks: [WorkbenchTask] {
        store.data.tasks.filter { $0.note.contains(project.id) || $0.note.contains("smart-plan") || $0.title.contains(project.name) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name).font(.system(size: 26, weight: .bold))
                        Text(project.shortName ?? "").foregroundStyle(.secondary)
                        HStack {
                            TagChip(text: project.category, color: .indigo)
                            TagChip(text: project.status, color: .blue)
                        }
                    }
                    Spacer()
                    Button { store.revealProject(project) } label: { Label("在 Finder 中显示", systemImage: "folder") }
                        .buttonStyle(.bordered)
                    if project.run?.url != nil {
                        Button { store.openProjectURL(project) } label: { Label("打开本地网址", systemImage: "safari") }
                            .buttonStyle(.borderedProminent).tint(.black)
                    }
                }
                Text(project.summary).font(.body)
                groupBox("技术栈") { FlowTech(tags: project.techStack) }
                groupBox("路径") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("相对：\(project.localPath)").font(.caption.monospaced())
                        Text(project.absolutePathHint ?? "").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                groupBox("匹配员工") {
                    VStack(alignment: .leading, spacing: 10) {
                        if let owner { staffRow(owner, tag: "负责人") }
                        ForEach(collabs) { b in staffRow(b, tag: "协作") }
                    }
                }
                groupBox("相关任务") {
                    if relatedTasks.isEmpty {
                        Text("暂无关联任务").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(relatedTasks) { t in
                            HStack { Text(t.title); Spacer(); TagChip(text: t.status, color: .gray) }
                        }
                    }
                }
                Spacer(minLength: 80)
            }
        }
    }

    private func staffRow(_ b: Bot, tag: String) -> some View {
        HStack(spacing: 10) {
            if let img = NSImage(contentsOf: b.avatarURL) {
                Image(nsImage: img).resizable().scaledToFill()
                    .frame(width: 36, height: 36).clipShape(Circle())
            }
            VStack(alignment: .leading) {
                Text(b.name.components(separatedBy: "-").first ?? b.name).font(.subheadline.weight(.semibold))
                Text(b.role).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            TagChip(text: tag, color: .primary)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func groupBox<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06)))
    }
}

struct FlowTech: View {
    let tags: [String]
    var body: some View {
        HStack(spacing: 8) { ForEach(tags, id: \.self) { TagChip(text: $0, color: .blue) } }
    }
}
