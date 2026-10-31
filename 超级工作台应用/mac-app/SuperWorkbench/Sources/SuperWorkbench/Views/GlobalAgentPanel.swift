import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// P0 Global Agent: ⌘K panel — streaming chat + Codex/Qwen-style composer.
struct GlobalAgentPanel: View {
    @EnvironmentObject var store: WorkspaceStore
    @Binding var isPresented: Bool
    @StateObject private var vm = GlobalAgentViewModel()
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                header
                Divider()
                ScrollViewReader { proxy in
                    ScrollView {
                        AgentTranscriptView(messages: vm.messages, isStreaming: vm.isStreaming)
                            .padding(16)
                    }
                    .onChange(of: vm.messages.count) { _, _ in
                        scrollTranscript(proxy)
                    }
                    .onChange(of: vm.isStreaming) { _, _ in
                        scrollTranscript(proxy)
                    }
                }
                composerCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
            }
            .frame(maxWidth: 760, maxHeight: 680)
            .background(SWTheme.pageBg)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
            .padding(24)
        }
        .onAppear {
            vm.attach(store: store)
            inputFocused = true
        }
        .onExitCommand { isPresented = false }
        .alert("确认执行", isPresented: $vm.showConfirm) {
            Button("取消", role: .cancel) { vm.resolveConfirm(false) }
            Button("执行", role: .destructive) { vm.resolveConfirm(true) }
        } message: {
            Text(vm.confirmText)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                GlassOrbView(size: 26, isActive: vm.isStreaming)
                Text(vm.panelMode == .chief ? "大可可 · 总调度" : "全局对话").font(.headline)
                Text(vm.panelMode == .chief ? "委派员工并汇总" : "系统工具 · 客户统计/语义检索")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("设置") { vm.showSettings = true }
                    .buttonStyle(.borderless)
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            Picker("", selection: $vm.panelMode) {
                Text("全局对话").tag(GlobalAgentViewModel.PanelMode.global)
                Text("大可可").tag(GlobalAgentViewModel.PanelMode.chief)
            }
            .pickerStyle(.segmented)
            .onChange(of: vm.panelMode) { oldMode, newMode in
                vm.switchPanelMode(from: oldMode, to: newMode)
            }
        }
        .padding(14)
        .background(SWTheme.card)
        .sheet(isPresented: $vm.showSettings) {
            AgentSettingsSheet(vm: vm)
        }
    }

    // MARK: - Qwen / Codex-style composer card

    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !vm.selectedSkillIds.isEmpty {
                selectedSkillTags
            }
            if !vm.attachmentNames.isEmpty {
                attachmentTags
            }

            TextField("向 AI 提问", text: $vm.draft, axis: .vertical)
                .lineLimit(2...8)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($inputFocused)
                .onKeyPress(keys: [.return]) { press in
                    if press.modifiers.contains(.shift) {
                        return .ignored
                    }
                    Task { await vm.send() }
                    return .handled
                }

            HStack(spacing: 8) {
                attachButton
                modelPickerChip
                skillsChip
                moreMenu
                Spacer(minLength: 8)
                micButton
                sendButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }

    private var selectedSkillTags: some View {
        AgentSkillTagsBar(ids: vm.selectedSkillIds, labels: vm.skillLabelMap) { id in
            vm.toggleSkill(id)
        }
    }

    private var attachmentTags: some View {
        HStack(spacing: 6) {
            ForEach(Array(vm.attachmentNames.enumerated()), id: \.offset) { idx, name in
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 10))
                    Text(name)
                        .font(.system(size: 11))
                        .lineLimit(1)
                    Button {
                        vm.removeAttachment(at: idx)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.04))
                .clipShape(Capsule())
            }
        }
    }

    private var attachButton: some View {
        Button {
            vm.pickAttachments()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SWTheme.text)
                .frame(width: 30, height: 30)
                .background(Color.black.opacity(0.04))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help("添加文件或图片")
    }

    private var modelPickerChip: some View {
        Menu {
            if vm.modelGroups.isEmpty {
                Text("无已启用模型 — 请先在全局设置中开启网关")
            } else {
                ForEach(vm.modelGroups, id: \.providerId) { group in
                    Section(group.providerName) {
                        ForEach(group.models, id: \.id) { m in
                            Button {
                                vm.selectModel(providerId: m.providerId, modelId: m.modelId)
                            } label: {
                                HStack {
                                    Text(m.modelId)
                                    if vm.selectedProviderId == m.providerId && vm.model == m.modelId {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                Text(vm.modelChipTitle)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.04))
            .clipShape(Capsule())
            .foregroundStyle(SWTheme.text)
        }
        .menuStyle(.borderlessButton)
        .help("选择模型（按算力平台分组）")
    }

    private var skillsChip: some View {
        Menu {
            if vm.skillOptions.isEmpty {
                Text("暂无可用 Skills")
            } else {
                ForEach(vm.skillOptions) { sk in
                    Button {
                        vm.toggleSkill(sk.value)
                    } label: {
                        HStack {
                            Text(sk.label)
                            if vm.selectedSkillIds.contains(sk.value) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11))
                Text(vm.selectedSkillIds.isEmpty ? "技能" : "技能 \(vm.selectedSkillIds.count)")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(vm.selectedSkillIds.isEmpty ? Color.black.opacity(0.04) : Color.accentColor.opacity(0.12))
            .clipShape(Capsule())
            .foregroundStyle(SWTheme.text)
        }
        .menuStyle(.borderlessButton)
        .help("多选 Skills；选中后会注入 SKILL.md 上下文")
    }

    private var moreMenu: some View {
        Menu {
            Button("清空对话") { vm.clearChat() }
            Button("重新载入模型 / Skills") { vm.reloadGlobalProviders(); vm.reloadSkills() }
            Divider()
            Button("打开全局设置…") { vm.showSettings = true }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .medium))
                Text("更多")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.04))
            .clipShape(Capsule())
            .foregroundStyle(SWTheme.text)
        }
        .menuStyle(.borderlessButton)
    }

    private var micButton: some View {
        Button {
            // Speech input not wired — keep disabled UX with tooltip.
        } label: {
            Image(systemName: "mic")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SWTheme.text.opacity(0.35))
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.04))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(true)
        .help("语音输入暂未启用")
    }

    private var sendButton: some View {
        let canSend = !vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isStreaming
        return Button {
            Task { await vm.send() }
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(canSend ? Color.black : Color.black.opacity(0.18))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!canSend)
        .help("发送（Enter；Shift+Enter 换行）")
    }

    private func scrollTranscript(_ proxy: ScrollViewProxy) {
        if vm.isStreaming {
            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
            return
        }
        if let last = AgentTranscriptBuilder.items(from: vm.messages).last {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class GlobalAgentViewModel: ObservableObject {
    struct ProviderItem: Identifiable, Equatable {
        var id: String
        var name: String
        var baseURL: String
        var model: String
        var availableModels: [String]
        var enabled: Bool
    }

    struct ModelPick: Identifiable, Hashable {
        var id: String { providerId + "::" + modelId }
        var providerId: String
        var providerName: String
        var modelId: String
    }

    struct ModelGroup: Hashable {
        var providerId: String
        var providerName: String
        var models: [ModelPick]
    }

    enum PanelMode: String, CaseIterable, Identifiable {
        case global
        case chief
        var id: String { rawValue }
    }

    struct TabSession {
        var messages: [AgentChatMessage] = []
        var selectedProviderId: String = ""
        var model: String = ""
        var baseURL: String = ""
        var selectedSkillIds: [String] = []
    }

    @Published var panelMode: PanelMode = {
        let raw = UserDefaults.standard.string(forKey: "sw.agent.panelMode") ?? "global"
        return PanelMode(rawValue: raw) ?? .global
    }()
    private var sessions: [PanelMode: TabSession] = [:]
    private var chiefSessionURL: URL?

    @Published var messages: [AgentChatMessage] = []
    @Published var steps: [AgentStepEvent] = []
    @Published var draft: String = ""
    @Published var isStreaming = false
    @Published var showSettings = false
    @Published var baseURL: String = UserDefaults.standard.string(forKey: "sw.agent.baseURL") ?? "https://api.deepseek.com"
    @Published var model: String = UserDefaults.standard.string(forKey: "sw.agent.model") ?? "deepseek-chat"
    @Published var keyDraft: String = ""
    @Published var status: String = ""
    @Published var providerList: [ProviderItem] = []
    @Published var selectedProviderId: String = UserDefaults.standard.string(forKey: "sw.agent.selectedProviderId") ?? ""
    @Published var skillOptions: [AgentSkillCatalog.Option] = []
    @Published var selectedSkillIds: [String] = UserDefaults.standard.stringArray(forKey: "sw.agent.selectedSkills") ?? []
    @Published var attachmentPaths: [String] = []
    @Published var confirmText: String = ""
    @Published var showConfirm = false

    private var store: WorkspaceStore?
    private let executor = AgentExecutor()
    private let llm = AgentLLMClient()
    private var confirmContinuation: CheckedContinuation<Bool, Never>?

    var attachmentNames: [String] {
        attachmentPaths.map { URL(fileURLWithPath: $0).lastPathComponent }
    }

    var skillLabelMap: [String: String] {
        Dictionary(uniqueKeysWithValues: skillOptions.map { ($0.value, $0.label) })
    }

    var modelGroups: [ModelGroup] {
        providerList.filter(\.enabled).map { p in
            let ids: [String]
            if p.availableModels.isEmpty {
                ids = p.model.isEmpty ? [] : [p.model]
            } else {
                ids = p.availableModels
            }
            let models = ids.map { mid in
                ModelPick(providerId: p.id, providerName: p.name, modelId: mid)
            }
            return ModelGroup(providerId: p.id, providerName: p.name, models: models)
        }.filter { !$0.models.isEmpty }
    }

    var modelChipTitle: String {
        if model.isEmpty { return "选择模型" }
        let short = model.split(separator: "/").last.map(String.init) ?? model
        if short.count > 18 { return String(short.prefix(16)) + "…" }
        return short
    }

    func attach(store: WorkspaceStore) {
        self.store = store
        executor.store = store
        executor.audit = AgentAuditLog(repoRoot: store.repoRoot)
        executor.confirmHandler = { [weak self] name, summary, _ in
            guard let self else { return false }
            return await self.askConfirm(name: name, summary: summary)
        }
        // Restore last tab session or seed welcome.
        if sessions[panelMode] == nil {
            var seed = TabSession()
            seed.messages = [welcomeMessage(for: panelMode)]
            seed.selectedProviderId = selectedProviderId
            seed.model = model
            seed.baseURL = baseURL
            seed.selectedSkillIds = selectedSkillIds
            sessions[panelMode] = seed
        }
        applySession(sessions[panelMode] ?? TabSession())
        if panelMode == .chief {
            ensureChiefSession()
        }
        reloadGlobalProviders()
        reloadSkills()
    }

    private func welcomeMessage(for mode: PanelMode) -> AgentChatMessage {
        switch mode {
        case .global:
            return AgentChatMessage(
                role: .assistant,
                content: "我是 **全局助手**。可直接查客户统计、语义搜客户、任务与导航；不委派员工。问数量先看快照 / `crm_stats`；找客户优先 `semantic_search_customers`。"
            )
        case .chief:
            return AgentChatMessage(
                role: .assistant,
                content: "我是 **大可可（总调度）**。需要时会 `list_employees` / `delegate_to_employee` 派给数字员工并汇总。会话写入 chief 私有目录。浏览器/发信请走 Grok Bot App。"
            )
        }
    }

    func switchPanelMode(from old: PanelMode, to mode: PanelMode) {
        guard old != mode else { return }
        // Save the tab we left (binding already flipped panelMode to `mode`).
        sessions[old] = TabSession(
            messages: messages,
            selectedProviderId: selectedProviderId,
            model: model,
            baseURL: baseURL,
            selectedSkillIds: selectedSkillIds
        )
        panelMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "sw.agent.panelMode")
        if sessions[mode] == nil {
            var seed = TabSession()
            seed.messages = [welcomeMessage(for: mode)]
            seed.selectedProviderId = selectedProviderId
            seed.model = model
            seed.baseURL = baseURL
            seed.selectedSkillIds = selectedSkillIds
            sessions[mode] = seed
        }
        applySession(sessions[mode]!)
        if mode == .chief {
            ensureChiefSession()
        }
        persistComposerPrefs()
    }

    private func applySession(_ s: TabSession) {
        messages = s.messages
        if !s.selectedProviderId.isEmpty { selectedProviderId = s.selectedProviderId }
        if !s.model.isEmpty { model = s.model }
        if !s.baseURL.isEmpty { baseURL = s.baseURL }
        selectedSkillIds = s.selectedSkillIds
    }

    private func ensureChiefSession() {
        if chiefSessionURL == nil {
            chiefSessionURL = EmployeeChatStore.createSessionFile(botId: ChiefDispatchService.chiefBotId)
        }
    }

    private func persistChiefMessage(_ msg: AgentChatMessage) {
        guard panelMode == .chief, let url = chiefSessionURL else { return }
        EmployeeChatStore.appendMessage(msg, to: url)
    }

    func reloadSkills() {
        skillOptions = AgentSkillCatalog.allOptions(repoRoot: store?.repoRoot)
        // Drop selections that no longer exist
        let valid = Set(skillOptions.map(\.value))
        selectedSkillIds = selectedSkillIds.filter { valid.contains($0) }
        persistSkills()
    }

    func reloadGlobalProviders() {
        guard let store else { return }
        let providers = SharedModelStore.loadProviders(repoRoot: store.repoRoot)
        let doc = SharedModelStore.loadDocument(repoRoot: store.repoRoot)
        var items: [ProviderItem] = []
        for (i, p) in providers.enumerated() {
            let base = (p["baseURL"] as? String) ?? (p["baseUrl"] as? String) ?? ""
            let modelName = (p["model"] as? String) ?? (p["defaultModel"] as? String) ?? ""
            let name = (p["name"] as? String) ?? "provider-\(i)"
            let id = (p["id"] as? String) ?? "p\(i)"
            let enabled: Bool = {
                if let b = p["status"] as? Bool { return b }
                if let n = p["status"] as? NSNumber { return n.boolValue }
                return true
            }()
            let available = (p["availableModels"] as? [String]) ?? []
            if !base.isEmpty {
                items.append(ProviderItem(
                    id: id,
                    name: name,
                    baseURL: base,
                    model: modelName.isEmpty ? self.model : modelName,
                    availableModels: available,
                    enabled: enabled
                ))
            }
        }
        providerList = items
        let enabledItems = items.filter(\.enabled)
        if !doc.activeProviderId.isEmpty, enabledItems.contains(where: { $0.id == doc.activeProviderId }) {
            selectedProviderId = doc.activeProviderId
        } else if !selectedProviderId.isEmpty, enabledItems.contains(where: { $0.id == selectedProviderId }) {
            // keep
        } else if let first = enabledItems.first {
            selectedProviderId = first.id
        }
        applySelectedProvider()
        persistSelection()
        status = enabledItems.isEmpty ? "无已启用全局模型" : "已载入 \(enabledItems.count) 个启用网关"
    }

    func askConfirm(name: String, summary: String) async -> Bool {
        await withCheckedContinuation { cont in
            self.confirmText = "\(name)\n\(summary)"
            self.confirmContinuation = cont
            self.showConfirm = true
        }
    }

    func resolveConfirm(_ ok: Bool) {
        showConfirm = false
        confirmContinuation?.resume(returning: ok)
        confirmContinuation = nil
    }

    func saveSettings() {
        UserDefaults.standard.set(baseURL, forKey: "sw.agent.baseURL")
        UserDefaults.standard.set(model, forKey: "sw.agent.model")
        let k = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let store else {
            if !k.isEmpty {
                AgentKeychain.saveKey(k)
                keyDraft = ""
            }
            status = "已保存本地（无 store）"
            return
        }
        var providers = SharedModelStore.loadProviders(repoRoot: store.repoRoot)
        let pid = selectedProviderId.isEmpty ? "deepseek" : selectedProviderId
        if let idx = providers.firstIndex(where: { ($0["id"] as? String) == pid }) {
            providers[idx]["baseUrl"] = baseURL
            providers[idx]["model"] = model
            if !k.isEmpty {
                providers[idx]["apiKey"] = k
                SharedModelStore.saveKey(providerId: pid, key: k)
                AgentKeychain.saveKey(k)
            }
        } else {
            var row: [String: Any] = [
                "id": pid,
                "name": "超级工作台 Agent",
                "type": "openai-compatible",
                "status": true,
                "baseUrl": baseURL,
                "model": model,
                "modelGroup": "custom",
                "apiKey": k,
                "previewUrl": baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions",
                "availableModels": [] as [String]
            ]
            if !k.isEmpty {
                SharedModelStore.saveKey(providerId: pid, key: k)
                AgentKeychain.saveKey(k)
            }
            providers.insert(row, at: 0)
        }
        let (ok, err) = SharedModelStore.saveProviders(providers, activeProviderId: pid, repoRoot: store.repoRoot)
        keyDraft = ""
        reloadGlobalProviders()
        status = ok ? "已保存到全局模型配置（与外贸工作台共用）" : ("保存失败: " + (err ?? ""))
    }

    func importMagicHubProviders() {
        reloadGlobalProviders()
        status = providerList.isEmpty ? "全局列表为空" : "已从全局配置载入 \(providerList.count) 个网关"
    }

    func applySelectedProvider() {
        guard let p = providerList.first(where: { $0.id == selectedProviderId }) else { return }
        baseURL = p.baseURL
        if model.isEmpty || (!p.availableModels.isEmpty && !p.availableModels.contains(model) && !p.model.isEmpty) {
            model = p.model
        } else if model.isEmpty {
            model = p.model
        }
        persistSelection()
    }

    func selectModel(providerId: String, modelId: String) {
        selectedProviderId = providerId
        model = modelId
        if let p = providerList.first(where: { $0.id == providerId }) {
            baseURL = p.baseURL
        }
        persistSelection()
        // Mirror active model into shared store (best-effort).
        guard let store else { return }
        var providers = SharedModelStore.loadProviders(repoRoot: store.repoRoot)
        if let idx = providers.firstIndex(where: { ($0["id"] as? String) == providerId }) {
            providers[idx]["model"] = modelId
            _ = SharedModelStore.saveProviders(providers, activeProviderId: providerId, repoRoot: store.repoRoot)
        }
    }

    func toggleSkill(_ id: String) {
        if let i = selectedSkillIds.firstIndex(of: id) {
            selectedSkillIds.remove(at: i)
        } else {
            selectedSkillIds.append(id)
        }
        persistSkills()
    }

    func clearChat() {
        messages = [welcomeMessage(for: panelMode)]
        steps = []
        snapshotCurrentSession()
        if panelMode == .chief {
            chiefSessionURL = EmployeeChatStore.createSessionFile(botId: ChiefDispatchService.chiefBotId)
        }
    }

    func pickAttachments() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item, .image, .pdf, .plainText, .commaSeparatedText]
        panel.message = "选择要附带的文件或图片（仅把文件名注入上下文；不上传二进制）"
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            let path = url.path
            if !attachmentPaths.contains(path) {
                attachmentPaths.append(path)
            }
        }
    }

    func removeAttachment(at index: Int) {
        guard index >= 0, index < attachmentPaths.count else { return }
        attachmentPaths.remove(at: index)
    }

    private func persistSelection() {
        UserDefaults.standard.set(selectedProviderId, forKey: "sw.agent.selectedProviderId")
        UserDefaults.standard.set(model, forKey: "sw.agent.model")
        UserDefaults.standard.set(baseURL, forKey: "sw.agent.baseURL")
        snapshotCurrentSession()
    }

    private func persistSkills() {
        UserDefaults.standard.set(selectedSkillIds, forKey: "sw.agent.selectedSkills")
        snapshotCurrentSession()
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !isStreaming else { return }
        draft = ""
        var display = text
        if !attachmentNames.isEmpty {
            display += "\n\n（附件：\(attachmentNames.joined(separator: ", "))）"
        }
        let userMsg = AgentChatMessage(role: .user, content: display)
        messages.append(userMsg)
        persistChiefMessage(userMsg)
        isStreaming = true
        defer {
            isStreaming = false
            snapshotCurrentSession()
        }

        let pid = selectedProviderId.isEmpty ? "deepseek" : selectedProviderId
        let key = SharedModelStore.loadKey(providerId: pid)
            ?? AgentKeychain.loadKey()
            ?? ""
        if !key.isEmpty {
            await runLLM(userText: text, apiKey: key)
        } else {
            await runLocal(userText: text)
        }
        attachmentPaths = []
        if panelMode == .chief, let last = messages.last(where: { $0.role == .assistant }) {
            persistChiefMessage(last)
            if let url = chiefSessionURL {
                let summary = String(last.content.prefix(160))
                EmployeeChatStore.appendSummary(
                    botId: ChiefDispatchService.chiefBotId,
                    sessionFileName: url.lastPathComponent,
                    summary: summary
                )
            }
        }
    }

    private func runLocal(userText: String) async {
        let q = userText
        let ql = q.lowercased()
        var actions: [(String, [String: Any])] = []
        if q.contains("撤销") { actions.append(("agent.undo_last", [:])) }
        if q.contains("快照") || q.contains("状态") {
            actions.append(("context.get_snapshot", ["scope": "brief"]))
        }
        if q.contains("外贸") { actions.append(("nav.switch_workbench", ["workbenchId": "trade"])) }
        if q.contains("超级") || q.contains("综合") { actions.append(("nav.switch_workbench", ["workbenchId": "general"])) }
        if q.contains("日报") || q.contains("每日总结") { actions.append(("nav.open_section", ["sectionId": "dailySummary"])) }
        if q.contains("看板") { actions.append(("nav.open_section", ["sectionId": "tasks"])) }
        if q.contains("日程") { actions.append(("nav.open_section", ["sectionId": "scheduleCenter"])) }
        if q.contains("员工") { actions.append(("nav.open_section", ["sectionId": "roster"])) }
        if q.contains("总览") { actions.append(("nav.open_section", ["sectionId": "overview"])) }
        if ql.contains("seo") { actions.append(("nav.open_section", ["sectionId": "dailySeo"])) }
        if q.hasPrefix("建任务") || q.hasPrefix("创建任务") || q.contains("新建任务") {
            let title = q.replacingOccurrences(of: "建任务", with: "")
                .replacingOccurrences(of: "创建任务", with: "")
                .replacingOccurrences(of: "新建任务", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty { actions.append(("task.create", ["title": title])) }
        }
        if q.hasPrefix("完成任务") || q.contains("标为完成") {
            if let id = store?.scopedTasks.first?.id {
                actions.append(("task.set_status", ["id": id, "status": "完成"]))
            }
        }
        if actions.isEmpty {
            actions.append(("context.get_snapshot", ["scope": "brief"]))
        }
        var skillNote = ""
        if !selectedSkillIds.isEmpty {
            skillNote = "\n已选 Skills：\(selectedSkillIds.joined(separator: ", "))（本地模式未注入全文）"
        }
        var toolMsgs: [AgentChatMessage] = []
        for (name, params) in actions {
            let step = await executor.execute(name: name, params: params)
            steps.append(step)
            let tm = AgentChatMessage(role: .tool, content: step.detail, toolName: name, toolArgsSummary: step.argsSummary, ok: step.ok, ms: step.ms)
            messages.append(tm)
            toolMsgs.append(tm)
        }
        var lines: [String] = ["（本地模式 · 未配置 API Key）\(skillNote)"]
        for tm in toolMsgs {
            let n = tm.toolName ?? "tool"
            lines.append("• " + AgentToolPresentation.summary(tool: n, detail: tm.content, argsSummary: tm.toolArgsSummary))
        }
        messages.append(AgentChatMessage(role: .assistant, content: lines.joined(separator: "\n")))
    }

    private func runLLM(userText: String, apiKey: String) async {
        guard let store else {
            messages.append(AgentChatMessage(role: .assistant, content: "内部错误：未绑定 WorkspaceStore。"))
            return
        }
        let snap = await executor.execute(name: "context.get_snapshot", params: ["scope": "brief"])
        steps.append(snap)
        messages.append(AgentChatMessage(
            role: .tool,
            content: snap.detail,
            toolName: "context.get_snapshot",
            toolArgsSummary: snap.argsSummary,
            ok: snap.ok,
            ms: snap.ms
        ))
        let skillBlock = AgentSkillCatalog.systemContext(
            selectedIds: selectedSkillIds,
            repoRoot: store.repoRoot
        )
        var attachNote = ""
        if !attachmentNames.isEmpty {
            attachNote = "\n用户附带文件（仅文件名，未上传内容）：\(attachmentNames.joined(separator: ", "))"
        }
        let projects = (store.data.websiteProjects ?? []).count
        let liveLine = AgentCRM.liveSnapshotLine(
            repoRoot: store.repoRoot,
            bots: store.data.bots.count,
            tasks: store.data.tasks.count,
            projects: projects
        )
        let snapshotBlob = liveLine + "\n" + snap.detail
        let system: String
        if panelMode == .chief {
            system = ChiefDispatchService.chiefSystemPrompt(
                store: store,
                skillBlock: skillBlock + attachNote,
                snapshot: snapshotBlob
            )
        } else {
            system = ChiefDispatchService.globalSystemPrompt(
                store: store,
                skillBlock: skillBlock + attachNote,
                snapshot: snapshotBlob
            )
        }
        var apiMessages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": userText]
        ]
        let toolsSchema = AgentLLMClient.openAIToolsFromSchema(includeDelegation: panelMode == .chief)
        let cfg = AgentLLMClient.Config(baseURL: baseURL, model: model, apiKey: apiKey)
        let maxLoops = 6
        var loops = 0
        var emptySearchStreak = 0
        var forceTextOnly = false
        var delegationRounds = 0
        var assistantId = UUID()
        messages.append(AgentChatMessage(id: assistantId, role: .assistant, content: ""))

        while loops < maxLoops {
            loops += 1
            let allowTools = !forceTextOnly && loops <= maxLoops && delegationRounds < maxLoops
            do {
                let toolsPayload: [[String: Any]] = allowTools ? toolsSchema : []
                let result = try await llm.streamChat(config: cfg, messages: apiMessages, tools: toolsPayload) { delta in
                    Task { @MainActor in
                        if let idx = self.messages.firstIndex(where: { $0.id == assistantId }) {
                            self.messages[idx].content += delta
                        }
                    }
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }),
                   messages[idx].content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   !result.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    messages[idx].content = result.content
                }

                if result.toolCalls.isEmpty || forceTextOnly {
                    pruneEmptyAssistant(id: assistantId)
                    break
                }

                apiMessages.append([
                    "role": "assistant",
                    "content": result.content,
                    "tool_calls": result.toolCalls
                ])

                if let idx = messages.firstIndex(where: { $0.id == assistantId }),
                   messages[idx].content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    messages.remove(at: idx)
                }

                struct PendingDelegate {
                    var callId: String
                    var botId: String
                    var task: String
                }
                var pendingDelegates: [PendingDelegate] = []
                var roundHadEmptySearch = false
                var roundHadDelegate = false

                for tc in result.toolCalls {
                    guard let fn = tc["function"] as? [String: Any] else { continue }
                    guard let name = fn["name"] as? String else { continue }
                    let callId = (tc["id"] as? String) ?? name
                    let argStr = fn["arguments"] as? String ?? "{}"
                    let params = (try? JSONSerialization.jsonObject(with: Data(argStr.utf8))) as? [String: Any] ?? [:]

                    if name == "list_employees" {
                        if panelMode != .chief {
                            let detail = #"{"ok":false,"error":"全局对话模式不支持 list_employees，请切换到「大可可」选项卡"}"#
                            messages.append(AgentChatMessage(role: .tool, content: detail, toolName: name, toolArgsSummary: "blocked", ok: false, ms: 0))
                            apiMessages.append(["role": "tool", "tool_call_id": callId, "content": detail])
                            continue
                        }
                        let detail = ChiefDispatchService.listEmployeesJSON(store: store)
                        let toolMsg = AgentChatMessage(
                            role: .tool,
                            content: detail,
                            toolName: name,
                            toolArgsSummary: "count",
                            ok: true,
                            ms: 0
                        )
                        messages.append(toolMsg)
                        steps.append(AgentStepEvent(name: name, argsSummary: "all", ok: true, detail: detail, ms: 0))
                        apiMessages.append([
                            "role": "tool",
                            "tool_call_id": callId,
                            "content": detail
                        ])
                        continue
                    }

                    if name == "delegate_to_employee" {
                        if panelMode != .chief {
                            let detail = #"{"ok":false,"status":"失败","error":"全局对话模式不支持派工，请切换到「大可可」"}"#
                            messages.append(AgentChatMessage(role: .tool, content: detail, toolName: name, toolArgsSummary: "blocked", ok: false, ms: 0))
                            apiMessages.append(["role": "tool", "tool_call_id": callId, "content": detail])
                            continue
                        }
                        let botId = (params["botId"] as? String) ?? ""
                        let task = (params["task"] as? String) ?? ""
                        if botId.isEmpty || task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let detail = "{\"ok\":false,\"status\":\"失败\",\"error\":\"缺少 botId 或 task\"}"
                            let toolMsg = AgentChatMessage(
                                role: .tool,
                                content: detail,
                                toolName: name,
                                toolArgsSummary: "botId=\(botId)",
                                ok: false,
                                ms: 0
                            )
                            messages.append(toolMsg)
                            apiMessages.append([
                                "role": "tool",
                                "tool_call_id": callId,
                                "content": detail
                            ])
                            continue
                        }
                        pendingDelegates.append(PendingDelegate(callId: callId, botId: botId, task: task))
                        roundHadDelegate = true
                        continue
                    }

                    let step = await executor.execute(name: name, params: params)
                    steps.append(step)
                    let toolMsg = AgentChatMessage(
                        role: .tool,
                        content: step.detail,
                        toolName: name,
                        toolArgsSummary: step.argsSummary,
                        ok: step.ok,
                        ms: step.ms
                    )
                    messages.append(toolMsg)
                    apiMessages.append([
                        "role": "tool",
                        "tool_call_id": callId,
                        "content": step.detail
                    ])
                    if AgentToolPresentation.isEmptySearchResult(tool: name, detail: step.detail) {
                        roundHadEmptySearch = true
                    }
                }

                // Parallel delegation, max 3 at a time.
                if !pendingDelegates.isEmpty {
                    var i = 0
                    while i < pendingDelegates.count {
                        let end = min(i + ChiefDispatchService.maxParallelDelegations, pendingDelegates.count)
                        let batch = Array(pendingDelegates[i..<end])
                        i = end

                        var prepared: [(PendingDelegate, ChiefDispatchService.PreparedEmployee?)] = []
                        for job in batch {
                            prepared.append((job, ChiefDispatchService.prepareEmployee(botId: job.botId, store: store)))
                        }

                        var llmResults: [(PendingDelegate, Bool, String, Int, String)] = []
                        // name fallback when prepare fails
                        await withTaskGroup(of: (Int, Bool, String, Int, String).self) { group in
                            for (idx, pair) in prepared.enumerated() {
                                let job = pair.0
                                guard let prep = pair.1 else {
                                    llmResults.append((job, false, "无法准备员工 \(job.botId)：未找到员工或缺少 API Key / 模型。", 0, job.botId))
                                    continue
                                }
                                let botName = prep.botName
                                group.addTask {
                                    let r = await ChiefDispatchService.runEmployeeLLM(
                                        prepared: prep,
                                        task: job.task,
                                        llm: self.llm
                                    )
                                    return (idx, r.ok, r.output, r.ms, botName)
                                }
                            }
                            for await item in group {
                                let job = prepared[item.0].0
                                llmResults.append((job, item.1, item.2, item.3, item.4))
                            }
                        }

                        // Stable order by original batch index
                        llmResults.sort { a, b in
                            let ia = batch.firstIndex(where: { $0.callId == a.0.callId }) ?? 0
                            let ib = batch.firstIndex(where: { $0.callId == b.0.callId }) ?? 0
                            return ia < ib
                        }

                        for (job, ok, output, ms, botName) in llmResults {
                            let displayName: String
                            if let bot = store.bot(id: job.botId) {
                                displayName = bot.name
                            } else {
                                displayName = botName
                            }
                            let persisted: ChiefDispatchService.DelegationResult
                            if ok || !output.isEmpty {
                                persisted = ChiefDispatchService.persistDelegation(
                                    botId: job.botId,
                                    botName: displayName,
                                    task: job.task,
                                    output: output,
                                    ok: ok,
                                    ms: ms
                                )
                            } else {
                                persisted = ChiefDispatchService.DelegationResult(
                                    botId: job.botId,
                                    botName: displayName,
                                    task: job.task,
                                    ok: false,
                                    output: output,
                                    summary: output,
                                    ms: ms,
                                    sessionFileName: ""
                                )
                            }
                            let detail = ChiefDispatchService.delegationToolContent(persisted)
                            let toolMsg = AgentChatMessage(
                                role: .tool,
                                content: detail,
                                toolName: "delegate_to_employee",
                                toolArgsSummary: "botId=\(job.botId), task=\(job.task)",
                                ok: persisted.ok,
                                ms: ms
                            )
                            messages.append(toolMsg)
                            steps.append(AgentStepEvent(
                                name: "delegate_to_employee",
                                argsSummary: toolMsg.toolArgsSummary ?? "",
                                ok: persisted.ok,
                                detail: detail,
                                ms: ms
                            ))
                            apiMessages.append([
                                "role": "tool",
                                "tool_call_id": job.callId,
                                "content": detail
                            ])
                        }
                    }
                }

                if roundHadDelegate {
                    delegationRounds += 1
                }
                if roundHadEmptySearch {
                    emptySearchStreak += 1
                } else {
                    emptySearchStreak = 0
                }

                if emptySearchStreak >= 2 || loops >= maxLoops || delegationRounds >= maxLoops {
                    forceTextOnly = true
                    let wrap: String
                    if panelMode == .chief {
                        wrap = "请停止继续调用 tools，用中文写最终回答：汇总已派工结果、结论与下一步。浏览器/发信/发帖提醒用户去 Grok Bot App 的大可可处理。"
                    } else {
                        wrap = "请停止继续调用 tools，用中文写最终回答：基于已有工具结果给出结论与下一步。勿再翻页搜客户。"
                    }
                    apiMessages.append([
                        "role": "user",
                        "content": wrap
                    ])
                }

                assistantId = UUID()
                messages.append(AgentChatMessage(id: assistantId, role: .assistant, content: ""))
            } catch {
                pruneEmptyAssistant(id: assistantId)
                messages.append(AgentChatMessage(role: .assistant, content: "调用失败：\(error.localizedDescription)"))
                return
            }
        }

        let hasAssistantText = messages.contains {
            $0.role == .assistant && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if !hasAssistantText {
            pruneEmptyAssistant(id: assistantId)
            let fromUser = messages.lastIndex(where: { $0.role == .user }) ?? 0
            let toolsOnly = Array(messages.suffix(from: fromUser).filter { $0.role == .tool })
            let fallback = AgentToolPresentation.fallbackAnswer(fromToolMessages: toolsOnly, userText: userText)
            messages.append(AgentChatMessage(role: .assistant, content: fallback))
        } else {
            pruneEmptyAssistant(id: assistantId)
        }
    }

    private func snapshotCurrentSession() {
        sessions[panelMode] = TabSession(
            messages: messages,
            selectedProviderId: selectedProviderId,
            model: model,
            baseURL: baseURL,
            selectedSkillIds: selectedSkillIds
        )
    }

    private func persistComposerPrefs() {
        UserDefaults.standard.set(selectedProviderId, forKey: "sw.agent.selectedProviderId")
        UserDefaults.standard.set(model, forKey: "sw.agent.model")
        UserDefaults.standard.set(baseURL, forKey: "sw.agent.baseURL")
        UserDefaults.standard.set(selectedSkillIds, forKey: "sw.agent.selectedSkills")
        UserDefaults.standard.set(panelMode.rawValue, forKey: "sw.agent.panelMode")
        snapshotCurrentSession()
    }

    private func pruneEmptyAssistant(id: UUID) {
        guard let idx = messages.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = messages[idx].content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            messages.remove(at: idx)
        }
    }
}

struct AgentSettingsSheet: View {
    @ObservedObject var vm: GlobalAgentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("全局 Agent · 模型").font(.title3.bold())
            Text("与外贸工作台共用全局配置 · Key 在 Keychain / Application Support（不进 git）")
                .font(.caption).foregroundStyle(.secondary)
            TextField("Base URL", text: $vm.baseURL)
            TextField("Model", text: $vm.model)
            SecureField("API Key（留空则保留原 Key）", text: $vm.keyDraft)
            if !vm.status.isEmpty {
                Text(vm.status).font(.caption).foregroundStyle(.green)
            }
            HStack {
                Button("清除 Key") {
                    AgentKeychain.deleteKey()
                    vm.status = "Key 已清除"
                }
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") {
                    vm.saveSettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            Divider().padding(.vertical, 4)
            Button("重新载入全局模型列表") { vm.importMagicHubProviders() }
                .buttonStyle(.bordered)
            if !vm.providerList.isEmpty {
                Text("已载入 \(vm.providerList.count) 个全局网关（与外贸工作台同一份 models.json）")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("选用", selection: $vm.selectedProviderId) {
                    ForEach(vm.providerList, id: \.id) { p in
                        Text(p.enabled ? p.name : "\(p.name)（未启用）").tag(p.id)
                    }
                }
                .onChange(of: vm.selectedProviderId) { _, _ in
                    vm.applySelectedProvider()
                }
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
