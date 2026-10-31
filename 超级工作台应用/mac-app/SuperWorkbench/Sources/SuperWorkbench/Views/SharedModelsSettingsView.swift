import SwiftUI
import AppKit

/// Full global settings window — ports MagicHub SystemSettings into native UI.
struct SharedModelsSettingsView: View {
    @ObservedObject private var vectorCtrl = AgentVectorIndexController.shared
    @EnvironmentObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SharedModelsSettingsVM()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Picker("", selection: $vm.tab) {
                Text("AI 模型").tag(SharedModelsSettingsVM.Tab.api)
                Text("智能体 / Skills").tag(SharedModelsSettingsVM.Tab.skills)
                Text("本地存储").tag(SharedModelsSettingsVM.Tab.storage)
                Text("更新日志").tag(SharedModelsSettingsVM.Tab.changelog)
                Text("使用说明").tag(SharedModelsSettingsVM.Tab.manual)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Group {
                switch vm.tab {
                case .api: apiTab
                case .skills: skillsTab
                case .storage: storageTab
                case .changelog: changelogTab
                case .manual: manualTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 860, minHeight: 560)
        .onAppear { vm.bootstrap(repoRoot: store.repoRoot) }
        .sheet(isPresented: $vm.showAddProvider) { addProviderSheet }
        .sheet(isPresented: $vm.showAddModel) { addModelSheet }
        .alert("提示", isPresented: $vm.showAlert) {
            Button("好") {}
        } message: {
            Text(vm.alertText)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("全局设置").font(.title2.bold())
                Text("超级工作台 ∪ 外贸工作台共用 · Application Support/超级工作台/")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("完成") { dismiss() }.keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    // MARK: - API tab

    private var apiTab: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("搜索模型平台…", text: $vm.providerQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 12)
                List(selection: $vm.selectedId) {
                    ForEach(vm.filteredProviders) { p in
                        HStack {
                            Circle().fill(p.enabled ? Color.green : Color.gray.opacity(0.35)).frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.system(size: 13, weight: .semibold))
                                Text(p.id).font(.caption2.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if p.hasKey { Image(systemName: "key.fill").font(.caption2).foregroundStyle(.secondary) }
                        }
                        .tag(p.id)
                        .contextMenu {
                            if p.isCustom {
                                Button("删除自定义平台", role: .destructive) { vm.deleteSelectedCustom() }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                Button {
                    vm.showAddProvider = true
                } label: {
                    Label("添加自定义平台", systemImage: "plus")
                }
                .padding(12)
            }
            .frame(width: 260)
            .background(Color.primary.opacity(0.04))

            Divider()

            if let p = vm.selectedProvider {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(p.name).font(.title3.bold())
                            Spacer()
                            Toggle("启用", isOn: vm.bindingEnabled)
                        }
                        labeled("API Key") {
                            HStack {
                                SecureField("请输入密钥…", text: $vm.keyDraft)
                                    .textFieldStyle(.roundedBorder)
                                Button(vm.testing ? "检测中…" : "检测") { Task { await vm.testConnection() } }
                                    .disabled(vm.testing || vm.syncing)
                            }
                        }
                        Text("多个密钥请用逗号分隔（当前取第一个做检测/拉取）").font(.caption2).foregroundStyle(.secondary)

                        labeled("API 地址 (Base URL)") {
                            HStack {
                                TextField("https://…/v1", text: vm.bindingBaseURL)
                                    .textFieldStyle(.roundedBorder)
                                Button("重置") { vm.resetBaseURL() }
                            }
                        }
                        Text("预览：\(vm.previewCompletionsURL)").font(.caption2.monospaced()).foregroundStyle(.secondary)

                        HStack {
                            Text("模型").font(.headline)
                            Text("\(vm.selectedProvider?.availableModels.count ?? 0)")
                                .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.black.opacity(0.06)).clipShape(Capsule())
                            Spacer()
                            Button(vm.syncing ? "拉取中…" : "获取模型列表") { Task { await vm.syncModels() } }
                                .disabled(vm.testing || vm.syncing)
                            Button { vm.showAddModel = true } label: { Image(systemName: "plus") }
                        }
                        if !vm.modelsError.isEmpty {
                            Text(vm.modelsError)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        let models = (vm.selectedProvider?.availableModels.isEmpty == false)
                            ? (vm.selectedProvider?.availableModels ?? [])
                            : [vm.selectedProvider?.model ?? ""]
                        VStack(spacing: 6) {
                            ForEach(models.filter { !$0.isEmpty }, id: \.self) { mid in
                                HStack {
                                    Image(systemName: mid == p.model ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(mid == p.model ? Color.accentColor : .secondary)
                                    Text(mid).font(.system(.body, design: .monospaced))
                                    Spacer()
                                    if mid == p.model {
                                        Button(role: .destructive) { vm.clearCurrentModel() } label: { Image(systemName: "minus") }
                                            .buttonStyle(.borderless)
                                    }
                                }
                                .padding(8)
                                .background(mid == p.model ? Color.accentColor.opacity(0.08) : Color.black.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .contentShape(Rectangle())
                                .onTapGesture { vm.selectModel(mid) }
                            }
                        }

                        if !vm.statusLine.isEmpty {
                            Text(vm.statusLine).font(.caption).foregroundStyle(.secondary)
                        }

                        HStack {
                            Spacer()
                            Button("保存并应用网关") { vm.saveAll() }
                                .buttonStyle(.borderedProminent)
                        }
                        Text("密钥写入 Keychain / Application Support（不进 git）。")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(18)
                }
            } else {
                Text("选择左侧平台").foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }

    // MARK: - Skills

    private var skillsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox("智能体应用与工具箱") {
                    Text("深度客户分析、SEO 诊断等交互式工具仍在「外贸工作台」内使用（Vue 组件无法整页迁入原生窗口）。请在外贸工作台侧栏打开对应模块。")
                        .font(.callout).foregroundStyle(.secondary)
                        .padding(8)
                }
                GroupBox("高级开关") {
                    Toggle("物理断网隔绝模式（Secret Mode）", isOn: $vm.prefs.secretMode)
                    Toggle("外部报告自动侦测", isOn: $vm.prefs.autoScan)
                    Toggle("跨组件双向数据同步", isOn: $vm.prefs.doubleLinkage)
                    HStack {
                        Text("向量召回上限（semantic top-K）")
                        Spacer()
                        Stepper(value: $vm.prefs.vectorLimit, in: 1...10) { Text("\(vm.prefs.vectorLimit) 条") }
                    }
                }
                GroupBox("客户向量索引") {
                    Text("本地索引路径：\(AgentVectorIndex.vectorsDir.path)")
                        .font(.caption2).foregroundStyle(.secondary).textSelection(.enabled)
                    Picker("向量模型", selection: $vm.prefs.embeddingModel) {
                        ForEach(SharedModelsSettingsVM.embeddingModelChoices, id: \.self) { m in
                            Text(m).tag(m)
                        }
                    }
                    .onChange(of: vm.prefs.embeddingModel) { _, _ in
                        vm.savePrefs()
                    }
                    Text("通义/DashScope 推荐 text-embedding-v4（失败自动回退 v3）。索引仅存本机 Application Support，不进仓库。")
                        .font(.caption2).foregroundStyle(.secondary)
                    HStack {
                        Button(vectorCtrl.progress.isRunning ? "索引中…" : "重建索引") {
                            Task { await vm.rebuildVectorIndex(forceAll: false) }
                        }
                        .disabled(vectorCtrl.progress.isRunning)
                        Button("全量重建") {
                            Task { await vm.rebuildVectorIndex(forceAll: true) }
                        }
                        .disabled(vectorCtrl.progress.isRunning)
                        Spacer()
                        Text(AgentVectorIndex.statusSummary()).font(.caption).foregroundStyle(.secondary)
                    }
                    if vectorCtrl.progress.isRunning || !vectorCtrl.progress.message.isEmpty {
                        ProgressView(value: Double(vectorCtrl.progress.done), total: Double(max(1, vectorCtrl.progress.total))) {
                            Text(vectorCtrl.progress.message).font(.caption)
                        }
                    }
                    if let err = vectorCtrl.progress.lastError, !err.isEmpty {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
                GroupBox("创造力参数 (Temperature)") {
                    HStack {
                        Slider(value: $vm.prefs.temperature, in: 0...1.2, step: 0.1)
                        Text(String(format: "%.1f", vm.prefs.temperature)).monospacedDigit().frame(width: 36)
                    }
                    Text("起草开发信偏高（≈0.8）；图纸/合规诊断偏低（≈0.2）。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                GroupBox("标准 IDE 技能导入") {
                    ForEach(SharedWorkbenchPrefs.catalog) { sk in
                        let imported = vm.prefs.importedSkills.contains(where: { $0.value == sk.value })
                        let selected = vm.selectedSkillIds.contains(sk.value)
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sk.value).font(.caption.monospaced()).bold()
                                Text("\(sk.label) · \(sk.desc)").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(imported ? "已激活" : (selected ? "待导入" : "可选"))
                                .font(.caption2)
                                .foregroundStyle(imported ? .green : .secondary)
                        }
                        .padding(6)
                        .background(selected || imported ? Color.accentColor.opacity(0.06) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onTapGesture {
                            guard !imported else { return }
                            if selected { vm.selectedSkillIds.remove(sk.value) }
                            else { vm.selectedSkillIds.insert(sk.value) }
                        }
                    }
                    Button(vm.importingSkills ? "导入中…" : "一键导入选中技能") {
                        vm.importSelectedSkills()
                    }
                    .disabled(vm.selectedSkillIds.isEmpty || vm.importingSkills)
                    if !vm.skillTerminal.isEmpty {
                        ScrollView {
                            Text(vm.skillTerminal.joined(separator: "\n"))
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 120)
                        .padding(8)
                        .background(Color.black.opacity(0.85))
                        .foregroundStyle(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                Button("保存智能体偏好") { vm.savePrefs(); vm.alert("已保存智能体 / Skills 偏好") }
                    .buttonStyle(.borderedProminent)
            }
            .padding(18)
        }
    }

    // MARK: - Storage

    private var storageTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("本地物理存储与文件管理").font(.headline)
                    Spacer()
                    Button("清理临时缓存") { vm.clearCaches() }
                }
                storageRow(title: "全局模型配置", path: SharedModelStore.modelsFile.path, note: "models.json · 含平台列表；密钥同步 Keychain")
                storageRow(title: "工作台偏好", path: SharedWorkbenchPrefs.fileURL.path, note: "Skills / Temperature / Secret Mode / 向量模型")
                storageRow(title: "客户向量索引", path: AgentVectorIndex.vectorsDir.path, note: "customers-index.json · 仅本机")
                storageRow(title: "CRM 私有设置目录", path: store.repoRoot.appendingPathComponent("超级工作台应用/data/private/crm/settings").path, note: "gitignored · Magichub 镜像")
                storageRow(title: "CRM 私有数据根", path: store.repoRoot.appendingPathComponent("超级工作台应用/data/private/crm").path, note: "leads / products / pdfs")
                Text("原 MagicHub Electron 路径（SQLite / ChromaDB / Caches）仅在独立 MagicHub.app 存在；工作台内嵌模式改用以上目录。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(18)
        }
    }

    private func storageRow(title: String, path: String, note: String) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.bold())
                Text(note).font(.caption2).foregroundStyle(.secondary)
                Text(path).font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
            }
            Spacer()
            Button("打开") { vm.openFolder(path) }
        }
        .padding(12)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Changelog / Manual

    private var changelogTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("系统更新说明").font(.headline)
                Text("工作台内嵌模式不支持 ZIP 热更新。请 git pull 后重建 Mac 应用。")
                    .font(.callout).foregroundStyle(.secondary)
                ForEach(SharedModelsSettingsVM.changelogEntries, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.0).font(.subheadline.bold())
                        Text(item.1).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(18)
        }
    }

    private var manualTab: some View {
        HStack(alignment: .top, spacing: 0) {
            List(selection: $vm.manualIndex) {
                ForEach(Array(SharedModelsSettingsVM.manualChapters.enumerated()), id: \.offset) { idx, ch in
                    Text("\(ch.0) \(ch.1)").tag(idx)
                }
            }
            .frame(width: 240)
            Divider()
            ScrollView {
                let ch = SharedModelsSettingsVM.manualChapters[safe: vm.manualIndex]
                    ?? SharedModelsSettingsVM.manualChapters[0]
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(ch.0) \(ch.1)").font(.title3.bold())
                    Text(ch.2).font(.body).textSelection(.enabled)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var addProviderSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("添加自定义模型平台").font(.headline)
            TextField("名称", text: $vm.newProviderName)
            TextField("Base URL", text: $vm.newProviderBase)
            SecureField("API Key（可选）", text: $vm.newProviderKey)
            TextField("默认模型", text: $vm.newProviderModel)
            HStack {
                Button("取消") { vm.showAddProvider = false }
                Spacer()
                Button("添加") { vm.addCustomProvider() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private var addModelSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("添加 / 切换模型 ID").font(.headline)
            TextField("model id", text: $vm.newModelName)
            HStack {
                Button("取消") { vm.showAddModel = false }
                Spacer()
                Button("确定") { vm.submitNewModel() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

// MARK: - ViewModel

@MainActor
final class SharedModelsSettingsVM: ObservableObject {
    enum Tab: String, CaseIterable { case api, skills, storage, changelog, manual }

    struct ProviderRow: Identifiable, Equatable {
        var id: String
        var name: String
        var baseURL: String
        var model: String
        var modelGroup: String
        var enabled: Bool
        var hasKey: Bool
        var isCustom: Bool
        var availableModels: [String]
        var typeName: String
    }

    @Published var tab: Tab = .api
    @Published var providers: [ProviderRow] = []
    @Published var selectedId: String = ""
    @Published var providerQuery: String = ""
    @Published var keyDraft: String = ""
    @Published var statusLine: String = ""
    @Published var modelsError: String = ""
    @Published var testing = false
    @Published var syncing = false
    @Published var showAddProvider = false
    @Published var showAddModel = false
    @Published var newProviderName = ""
    @Published var newProviderBase = ""
    @Published var newProviderKey = ""
    @Published var newProviderModel = "deepseek-chat"
    @Published var newModelName = ""
    @Published var prefs = SharedWorkbenchPrefs.Prefs()
    @Published var selectedSkillIds: Set<String> = []
    @Published var importingSkills = false
    @Published var skillTerminal: [String] = []
    @Published var showAlert = false
    @Published var alertText = ""
    @Published var manualIndex: Int = 0

    private var repoRoot: URL?

    var filteredProviders: [ProviderRow] {
        let q = providerQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let list = providers.sorted { ($0.enabled ? 1 : 0) > ($1.enabled ? 1 : 0) }
        guard !q.isEmpty else { return list }
        return list.filter { $0.name.lowercased().contains(q) || $0.id.lowercased().contains(q) }
    }

    var selectedProvider: ProviderRow? {
        providers.first(where: { $0.id == selectedId })
    }

    var previewCompletionsURL: String {
        let b = SharedModelsAPI.normalizeBase(selectedProvider?.baseURL ?? "")
        guard !b.isEmpty else { return "—" }
        return b + "/chat/completions"
    }

    var bindingEnabled: Binding<Bool> {
        Binding(
            get: { self.selectedProvider?.enabled ?? false },
            set: { val in self.updateSelected { $0.enabled = val } }
        )
    }

    var bindingBaseURL: Binding<String> {
        Binding(
            get: { self.selectedProvider?.baseURL ?? "" },
            set: { val in self.updateSelected { $0.baseURL = val } }
        )
    }

    static let embeddingModelChoices = [
        "text-embedding-v4",
        "text-embedding-v3",
        "text-embedding-v2",
        "text-embedding-3-small",
        "text-embedding-3-large"
    ]

    let vectorCtrl = AgentVectorIndexController.shared

    func rebuildVectorIndex(forceAll: Bool) async {
        guard let repoRoot else {
            alert("未绑定仓库根目录")
            return
        }
        savePrefs()
        await vectorCtrl.rebuild(repoRoot: repoRoot, forceAll: forceAll)
        if let err = vectorCtrl.progress.lastError, !err.isEmpty {
            alert("索引失败：\(err)")
        } else if !vectorCtrl.progress.message.isEmpty {
            alert(vectorCtrl.progress.message)
        }
    }

    func bootstrap(repoRoot: URL) {
        self.repoRoot = repoRoot
        reloadProviders()
        prefs = SharedWorkbenchPrefs.load()
    }

    func reloadProviders() {
        let raw = SharedModelStore.loadProviders(repoRoot: repoRoot)
        let doc = SharedModelStore.loadDocument(repoRoot: repoRoot)
        var rows: [ProviderRow] = []
        for p in raw {
            guard let id = p["id"] as? String else { continue }
            let name = (p["name"] as? String) ?? id
            let base = (p["baseUrl"] as? String) ?? (p["baseURL"] as? String) ?? ""
            let model = (p["model"] as? String) ?? ""
            let group = (p["modelGroup"] as? String) ?? "custom"
            let enabled = (p["status"] as? Bool) ?? false
            let key = (p["apiKey"] as? String) ?? ""
            let has = !key.isEmpty || !(SharedModelStore.loadKey(providerId: id) ?? "").isEmpty
            let models = (p["availableModels"] as? [String]) ?? []
            let typeName = (p["type"] as? String) ?? "openai-compatible"
            let isCustom = id.hasPrefix("custom_")
            rows.append(ProviderRow(id: id, name: name, baseURL: base, model: model, modelGroup: group, enabled: enabled, hasKey: has, isCustom: isCustom, availableModels: models, typeName: typeName))
        }
        providers = rows
        if selectedId.isEmpty || !rows.contains(where: { $0.id == selectedId }) {
            selectedId = doc.activeProviderId.isEmpty ? (rows.first?.id ?? "") : doc.activeProviderId
        }
        keyDraft = ""
        modelsError = ""
        statusLine = "已载入 \(rows.count) 个平台"
    }

    private func updateSelected(_ mutate: (inout ProviderRow) -> Void) {
        guard let idx = providers.firstIndex(where: { $0.id == selectedId }) else { return }
        mutate(&providers[idx])
    }

    private func firstKey() -> String {
        let raw = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.first { !$0.isEmpty } ?? raw }
        if let id = selectedProvider?.id, let k = SharedModelStore.loadKey(providerId: id), !k.isEmpty { return k }
        let rawProviders = SharedModelStore.loadProviders(repoRoot: repoRoot)
        if let id = selectedProvider?.id,
           let p = rawProviders.first(where: { ($0["id"] as? String) == id }),
           let k = p["apiKey"] as? String, !k.isEmpty {
            return k.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.first { !$0.isEmpty } ?? k
        }
        return ""
    }

    func testConnection() async {
        guard let p = selectedProvider else { return }
        testing = true
        defer { testing = false }
        let key = firstKey()
        let r = await SharedModelsAPI.fetchModels(providerId: p.id, baseURL: p.baseURL, apiKey: key)
        if r.ok {
            alert("「\(p.name) 连接检测成功」\n延迟：\(r.latencyMs)ms\n探测：\(r.url)")
        } else {
            alert("「\(p.name) 检测失败」\n\(r.message)")
        }
    }

    func syncModels() async {
        guard let p = selectedProvider else { return }
        syncing = true
        modelsError = ""
        defer { syncing = false }
        let key = firstKey()
        let r = await SharedModelsAPI.fetchModels(providerId: p.id, baseURL: p.baseURL, apiKey: key)
        if !r.ok {
            modelsError = r.message
            alert("拉取模型失败\n\(r.message)")
            return
        }
        updateSelected {
            $0.availableModels = r.modelIds
            if !$0.availableModels.contains($0.model) {
                $0.model = r.modelIds[0]
            }
            if $0.model.contains("/") {
                $0.modelGroup = String($0.model.split(separator: "/").first ?? Substring($0.modelGroup))
            }
            $0.hasKey = true
        }
        if !keyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // keep draft for save
        }
        saveAll(silent: true)
        statusLine = r.message + " · \(r.latencyMs)ms"
        alert("「\(p.name)」已拉取 \(r.modelIds.count) 个模型\n当前：\(selectedProvider?.model ?? "")")
    }

    func selectModel(_ mid: String) {
        updateSelected { $0.model = mid }
    }

    func clearCurrentModel() {
        updateSelected { $0.model = ($0.modelGroup.isEmpty ? "custom" : $0.modelGroup) + "/none" }
    }

    func resetBaseURL() {
        guard let id = selectedProvider?.id else { return }
        let defaults = SharedModelStore.defaultPresets()
        if let p = defaults.first(where: { ($0["id"] as? String) == id }),
           let base = p["baseUrl"] as? String {
            updateSelected { $0.baseURL = base }
        }
    }

    func saveAll(silent: Bool = false) {
        var raw = SharedModelStore.loadProviders(repoRoot: repoRoot)
        for row in providers {
            if let idx = raw.firstIndex(where: { ($0["id"] as? String) == row.id }) {
                raw[idx]["baseUrl"] = row.baseURL
                raw[idx]["model"] = row.model
                raw[idx]["modelGroup"] = row.modelGroup
                raw[idx]["status"] = row.enabled
                raw[idx]["availableModels"] = row.availableModels
                raw[idx]["type"] = row.typeName
                raw[idx]["previewUrl"] = SharedModelsAPI.normalizeBase(row.baseURL) + "/chat/completions"
                if row.id == selectedId {
                    let k = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !k.isEmpty {
                        raw[idx]["apiKey"] = k
                        SharedModelStore.saveKey(providerId: row.id, key: k)
                        AgentKeychain.saveKey(k)
                    }
                }
            } else if row.isCustom {
                var dict: [String: Any] = [
                    "id": row.id,
                    "name": row.name,
                    "type": row.typeName,
                    "status": row.enabled,
                    "baseUrl": row.baseURL,
                    "model": row.model,
                    "modelGroup": row.modelGroup,
                    "apiKey": "",
                    "previewUrl": SharedModelsAPI.normalizeBase(row.baseURL) + "/chat/completions",
                    "availableModels": row.availableModels,
                    "icon": "C",
                    "iconColor": "bg-slate-600"
                ]
                if row.id == selectedId {
                    let k = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !k.isEmpty {
                        dict["apiKey"] = k
                        SharedModelStore.saveKey(providerId: row.id, key: k)
                    }
                }
                raw.append(dict)
            }
        }
        let (ok, err) = SharedModelStore.saveProviders(raw, activeProviderId: selectedId, repoRoot: repoRoot)
        savePrefs()
        reloadProviders()
        if !silent {
            if ok { alert("网关配置已保存并应用到全局") }
            else { alert("保存失败：\(err ?? "unknown")") }
        }
    }

    func savePrefs() {
        _ = SharedWorkbenchPrefs.save(prefs)
    }

    func addCustomProvider() {
        let name = newProviderName.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = newProviderBase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !base.isEmpty else {
            alert("请填写名称和 Base URL")
            return
        }
        let id = "custom_\(Int(Date().timeIntervalSince1970))"
        let model = newProviderModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "custom-model" : newProviderModel
        var raw = SharedModelStore.loadProviders(repoRoot: repoRoot)
        var dict: [String: Any] = [
            "id": id,
            "name": name,
            "type": "openai-compatible",
            "status": true,
            "baseUrl": base,
            "model": model,
            "modelGroup": "custom",
            "apiKey": newProviderKey,
            "previewUrl": SharedModelsAPI.normalizeBase(base) + "/chat/completions",
            "availableModels": [] as [String],
            "icon": "C",
            "iconColor": "bg-slate-600"
        ]
        if !newProviderKey.isEmpty {
            SharedModelStore.saveKey(providerId: id, key: newProviderKey)
        }
        raw.append(dict)
        _ = SharedModelStore.saveProviders(raw, activeProviderId: id, repoRoot: repoRoot)
        showAddProvider = false
        newProviderName = ""; newProviderBase = ""; newProviderKey = ""; newProviderModel = "deepseek-chat"
        reloadProviders()
        selectedId = id
        alert("已添加自定义平台")
    }

    func deleteSelectedCustom() {
        guard let p = selectedProvider, p.isCustom else { return }
        var raw = SharedModelStore.loadProviders(repoRoot: repoRoot)
        raw.removeAll { ($0["id"] as? String) == p.id }
        SharedModelStore.deleteKey(providerId: p.id)
        _ = SharedModelStore.saveProviders(raw, repoRoot: repoRoot)
        selectedId = ""
        reloadProviders()
    }

    func submitNewModel() {
        let mid = newModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mid.isEmpty else { alert("请输入模型名称"); return }
        updateSelected {
            $0.model = mid
            if !$0.availableModels.contains(mid) { $0.availableModels.insert(mid, at: 0) }
            if mid.contains("/") {
                $0.modelGroup = String(mid.split(separator: "/").first ?? "custom")
            }
        }
        showAddModel = false
        newModelName = ""
        saveAll(silent: true)
    }

    func importSelectedSkills() {
        guard !selectedSkillIds.isEmpty else { return }
        importingSkills = true
        skillTerminal = ["$ crm-cli import --skills=\(selectedSkillIds.sorted().joined(separator: ","))"]
        for val in selectedSkillIds.sorted() {
            skillTerminal.append("[System] Loading schema for '\(val)'… OK")
            if let sk = SharedWorkbenchPrefs.catalog.first(where: { $0.value == val }),
               !prefs.importedSkills.contains(where: { $0.value == val }) {
                prefs.importedSkills.append(.init(value: sk.value, label: sk.label, desc: sk.desc, source: "imported"))
            }
        }
        skillTerminal.append("[Success] \(selectedSkillIds.count) skills imported")
        selectedSkillIds.removeAll()
        importingSkills = false
        savePrefs()
        alert("技能已导入并写入全局偏好")
    }

    func openFolder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        let dir = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(dir)
    }

    func clearCaches() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("com.ky.superworkbench", isDirectory: true)
        if let caches {
            try? FileManager.default.removeItem(at: caches)
            try? FileManager.default.createDirectory(at: caches, withIntermediateDirectories: true)
        }
        alert("已清理工作台临时缓存目录（若存在）")
    }

    func alert(_ text: String) {
        alertText = text
        showAlert = true
    }

    static let changelogEntries: [(String, String)] = [
        ("v1.10+ 全局设置", "AI 模型配置迁移至超级工作台全局设置，与外贸工作台共用 Application Support 存储。"),
        ("模型列表拉取", "支持 OpenAI 兼容 GET /models（Bearer）与 Gemini 原生 models?key=。"),
        ("更新方式", "工作台内嵌不支持 ZIP 热更新；请 git pull 后重建 .app。")
    ]

    static let manualChapters: [(String, String, String)] = [
        ("📊", "智能营销中心", "在外贸工作台「智能营销」模块连接邮箱、起草开发信与群发。全局设置负责算力网关与模型。"),
        ("🔍", "客户公海与跟进", "客户管理、Timeline 跟进仍在外贸工作台；AI 整理纪要依赖此处配置的模型。"),
        ("🌐", "AI 算力网关", "在「AI 模型」页启用平台、填写 Key、拉取模型列表并设默认模型。自定义平台点「添加自定义平台」。"),
        ("🛡️", "极密模式", "在「智能体 / Skills」开启物理断网隔绝后，云端请求应被拦截（业务侧仍以外贸台实现为准）。")
    ]
}
