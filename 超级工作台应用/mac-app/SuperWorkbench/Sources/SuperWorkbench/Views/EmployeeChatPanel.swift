import SwiftUI
import AppKit

/// Per-employee real-time chat — reuses AgentTranscriptView + Qwen-style composer.
struct EmployeeChatPanel: View {
    @EnvironmentObject var store: WorkspaceStore
    let bot: Bot
    @Binding var isPresented: Bool
    @StateObject private var vm: EmployeeChatViewModel
    @FocusState private var inputFocused: Bool
    @State private var tab: Tab = .chat

    enum Tab: String, CaseIterable { case chat = "对话"; case summary = "工作摘要" }

    init(bot: Bot, isPresented: Binding<Bool>) {
        self.bot = bot
        self._isPresented = isPresented
        self._vm = StateObject(wrappedValue: EmployeeChatViewModel(bot: bot))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                header
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(SWTheme.card)

                if tab == .chat {
                    chatBody
                } else {
                    summaryBody
                }
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
        .onDisappear {
            Task { await vm.endAndSummarize(reason: "window_closed") }
        }
        .onExitCommand { close() }
    }

    private func close() {
        Task {
            await vm.endAndSummarize(reason: "dismiss")
            await MainActor.run { isPresented = false }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            BotAvatarView(url: bot.avatarURL, fallbackLetter: String(bot.name.prefix(1)), fontSize: 18)
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(bot.name).font(.headline)
                Text(vm.modelChipTitle + " · " + bot.role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("结束并总结") {
                Task {
                    await vm.endAndSummarize(reason: "manual")
                    isPresented = false
                }
            }
            .buttonStyle(.bordered)
            Button {
                close()
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(14)
        .background(SWTheme.card)
    }

    private var chatBody: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    AgentTranscriptView(messages: vm.messages, isStreaming: vm.isStreaming)
                        .padding(16)
                }
                .onChange(of: vm.messages.count) { _, _ in
                    scroll(proxy)
                }
                .onChange(of: vm.isStreaming) { _, _ in
                    scroll(proxy)
                }
            }
            composer
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
        }
    }

    private var summaryBody: some View {
        ScrollView {
            Text(vm.summaryMarkdown.isEmpty ? "暂无工作摘要。结束对话后会自动写入。" : vm.summaryMarkdown)
                .font(.system(size: 13))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        if vm.isStreaming {
            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
            return
        }
        if let last = AgentTranscriptBuilder.items(from: vm.messages).last {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !vm.selectedSkillIds.isEmpty {
                AgentSkillTagsBar(ids: vm.selectedSkillIds, labels: vm.skillLabelMap) { id in
                    vm.toggleSkill(id)
                }
            }
            TextField("向 \(shortName) 提问", text: $vm.draft, axis: .vertical)
                .lineLimit(2...8)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($inputFocused)
                .onKeyPress(keys: [.return]) { press in
                    if press.modifiers.contains(.shift) { return .ignored }
                    Task { await vm.send() }
                    return .handled
                }
                .onChange(of: vm.draft) { _, _ in vm.touchActivity() }

            HStack(spacing: 8) {
                modelMenu
                skillsMenu
                moreMenu
                Spacer(minLength: 8)
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

    private var shortName: String {
        if let idx = bot.name.firstIndex(of: "-") { return String(bot.name[..<idx]) }
        return bot.name
    }

    private var modelMenu: some View {
        Menu {
            if vm.modelGroups.isEmpty {
                Text("无已启用模型")
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
                Image(systemName: "bolt.fill").font(.system(size: 11)).foregroundStyle(.orange)
                Text(vm.modelChipTitle).font(.system(size: 12, weight: .medium)).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.black.opacity(0.04)).clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
    }

    private var skillsMenu: some View {
        Menu {
            ForEach(vm.skillOptions) { sk in
                Button {
                    vm.toggleSkill(sk.value)
                } label: {
                    HStack {
                        Text(sk.label)
                        if vm.selectedSkillIds.contains(sk.value) { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkle").font(.system(size: 11))
                Text(vm.selectedSkillIds.isEmpty ? "技能" : "技能 \(vm.selectedSkillIds.count)")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(vm.selectedSkillIds.isEmpty ? Color.black.opacity(0.04) : Color.accentColor.opacity(0.12))
            .clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
    }

    private var moreMenu: some View {
        Menu {
            Button("保存为该员工默认模型 / 技能") { vm.persistPrefsAsDefault() }
            Button("刷新工作摘要") { vm.reloadSummary() }
            Button("在 Finder 显示会话目录") { vm.revealConversationsDir() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal").font(.system(size: 12, weight: .medium))
                Text("更多").font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.black.opacity(0.04)).clipShape(Capsule())
        }
        .menuStyle(.borderlessButton)
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
    }
}

// MARK: - ViewModel

@MainActor
final class EmployeeChatViewModel: ObservableObject {
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

    let bot: Bot
    @Published var messages: [AgentChatMessage] = []
    @Published var draft: String = ""
    @Published var isStreaming = false
    @Published var selectedProviderId: String = ""
    @Published var model: String = ""
    @Published var baseURL: String = ""
    @Published var skillOptions: [AgentSkillCatalog.Option] = []
    @Published var selectedSkillIds: [String] = []
    @Published var summaryMarkdown: String = ""
    @Published var modelGroups: [ModelGroup] = []

    private weak var store: WorkspaceStore?
    private let llm = AgentLLMClient()
    private var sessionURL: URL?
    private var didSummarize = false
    private var lastActivity = Date()
    private var idleTask: Task<Void, Never>?

    init(bot: Bot) {
        self.bot = bot
    }

    var skillLabelMap: [String: String] {
        Dictionary(uniqueKeysWithValues: skillOptions.map { ($0.value, $0.label) })
    }

    var modelChipTitle: String {
        if model.isEmpty { return "选择模型" }
        let short = model.split(separator: "/").last.map(String.init) ?? model
        if short.count > 18 { return String(short.prefix(16)) + "…" }
        return short
    }

    func attach(store: WorkspaceStore) {
        self.store = store
        let resolved = EmployeeChatStore.resolveModel(botId: bot.id, repoRoot: store.repoRoot)
        selectedProviderId = resolved.providerId
        baseURL = resolved.baseURL
        model = resolved.model
        let prefs = EmployeeChatStore.loadPrefs(botId: bot.id)
        skillOptions = AgentSkillCatalog.allOptions(repoRoot: store.repoRoot)
        if !prefs.defaultSkillIds.isEmpty {
            selectedSkillIds = prefs.defaultSkillIds.filter { id in skillOptions.contains(where: { $0.value == id }) }
        } else {
            selectedSkillIds = inferSkillsFromBot()
        }
        rebuildModelGroups(repoRoot: store.repoRoot)
        sessionURL = EmployeeChatStore.createSessionFile(botId: bot.id)
        didSummarize = false
        messages = [
            AgentChatMessage(
                role: .assistant,
                content: "你好，我是 **\(bot.name)**（\(bot.role)）。可以直接交代任务；结束对话时会写入工作摘要。"
            )
        ]
        reloadSummary()
        touchActivity()
        startIdleWatcher()
    }

    func touchActivity() {
        lastActivity = Date()
    }

    private func startIdleWatcher() {
        idleTask?.cancel()
        idleTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { return }
                let idle = Date().timeIntervalSince(self.lastActivity)
                if idle >= 600, !self.didSummarize, self.hasUserTurns {
                    await self.endAndSummarize(reason: "idle_10m")
                }
            }
        }
    }

    private var hasUserTurns: Bool {
        messages.contains { $0.role == .user }
    }

    private func inferSkillsFromBot() -> [String] {
        let blob = (bot.skills + " " + bot.tools).lowercased()
        return skillOptions.map(\.value).filter { blob.contains($0.lowercased()) }
    }

    private func rebuildModelGroups(repoRoot: URL?) {
        let providers = SharedModelStore.loadProviders(repoRoot: repoRoot)
        var groups: [ModelGroup] = []
        for (i, p) in providers.enumerated() {
            let enabled: Bool = {
                if let b = p["status"] as? Bool { return b }
                if let n = p["status"] as? NSNumber { return n.boolValue }
                return true
            }()
            guard enabled else { continue }
            let id = (p["id"] as? String) ?? "p\(i)"
            let name = (p["name"] as? String) ?? id
            let base = (p["baseURL"] as? String) ?? (p["baseUrl"] as? String) ?? ""
            guard !base.isEmpty else { continue }
            let available = (p["availableModels"] as? [String]) ?? []
            let fallback = (p["model"] as? String) ?? ""
            let ids = available.isEmpty ? (fallback.isEmpty ? [] : [fallback]) : available
            let models = ids.map { ModelPick(providerId: id, providerName: name, modelId: $0) }
            if !models.isEmpty {
                groups.append(ModelGroup(providerId: id, providerName: name, models: models))
            }
        }
        modelGroups = groups
    }

    func selectModel(providerId: String, modelId: String) {
        selectedProviderId = providerId
        model = modelId
        if let store,
           let p = SharedModelStore.loadProviders(repoRoot: store.repoRoot).first(where: { ($0["id"] as? String) == providerId }) {
            baseURL = (p["baseURL"] as? String) ?? (p["baseUrl"] as? String) ?? baseURL
        }
        touchActivity()
    }

    func toggleSkill(_ id: String) {
        if let i = selectedSkillIds.firstIndex(of: id) {
            selectedSkillIds.remove(at: i)
        } else {
            selectedSkillIds.append(id)
        }
        touchActivity()
    }

    func persistPrefsAsDefault() {
        var prefs = EmployeeChatStore.Prefs()
        prefs.providerId = selectedProviderId
        prefs.model = model
        prefs.defaultSkillIds = selectedSkillIds
        _ = EmployeeChatStore.savePrefs(prefs, botId: bot.id)
    }

    func reloadSummary() {
        summaryMarkdown = EmployeeChatStore.loadSummaryMarkdown(botId: bot.id)
    }

    func revealConversationsDir() {
        let dir = EmployeeChatStore.botDir(botId: bot.id)
        EmployeeChatStore.ensureDirs(botId: bot.id)
        NSWorkspace.shared.activateFileViewerSelecting([dir])
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !isStreaming else { return }
        draft = ""
        touchActivity()
        let userMsg = AgentChatMessage(role: .user, content: text)
        messages.append(userMsg)
        if let sessionURL {
            EmployeeChatStore.appendMessage(userMsg, to: sessionURL)
        }
        isStreaming = true
        defer { isStreaming = false }

        guard let store else {
            let m = AgentChatMessage(role: .assistant, content: "内部错误：未绑定 WorkspaceStore。")
            messages.append(m)
            return
        }
        let key = SharedModelStore.loadKey(providerId: selectedProviderId)
            ?? AgentKeychain.loadKey()
            ?? ""
        guard !key.isEmpty else {
            let m = AgentChatMessage(role: .assistant, content: "未配置 API Key。请在全局设置（KY 齿轮 / ⌘,）为当前模型填写密钥。")
            messages.append(m)
            if let sessionURL { EmployeeChatStore.appendMessage(m, to: sessionURL) }
            return
        }

        let skillBlock = AgentSkillCatalog.systemContext(selectedIds: selectedSkillIds, repoRoot: store.repoRoot)
        let system = EmployeeChatStore.buildSystemPrompt(bot: bot, repoRoot: store.repoRoot, skillBlock: skillBlock)
        var apiMessages: [[String: Any]] = [["role": "system", "content": system]]
        // Last ~12 turns (user+assistant), skip tools/system in window.
        let history = messages.filter { $0.role == .user || $0.role == .assistant }
        let window = Array(history.suffix(24)) // ~12 turns
        for m in window {
            let trimmed = m.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            apiMessages.append(["role": m.role.rawValue, "content": m.content])
        }

        let cfg = AgentLLMClient.Config(baseURL: baseURL, model: model, apiKey: key)
        let assistantId = UUID()
        messages.append(AgentChatMessage(id: assistantId, role: .assistant, content: ""))
        do {
            let result = try await llm.streamChat(config: cfg, messages: apiMessages, tools: []) { delta in
                Task { @MainActor in
                    if let idx = self.messages.firstIndex(where: { $0.id == assistantId }) {
                        self.messages[idx].content += delta
                    }
                }
            }
            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                if messages[idx].content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   !result.content.isEmpty {
                    messages[idx].content = result.content
                }
                if messages[idx].content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    messages.remove(at: idx)
                    let fallback = AgentChatMessage(role: .assistant, content: "（模型未返回文本）")
                    messages.append(fallback)
                    if let sessionURL { EmployeeChatStore.appendMessage(fallback, to: sessionURL) }
                } else if let sessionURL {
                    EmployeeChatStore.appendMessage(messages[idx], to: sessionURL)
                }
            }
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == assistantId }) {
                messages.remove(at: idx)
            }
            let m = AgentChatMessage(role: .assistant, content: "调用失败：\(error.localizedDescription)")
            messages.append(m)
            if let sessionURL { EmployeeChatStore.appendMessage(m, to: sessionURL) }
        }
        touchActivity()
    }

    func endAndSummarize(reason: String) async {
        idleTask?.cancel()
        idleTask = nil
        guard !didSummarize else { return }
        guard hasUserTurns else {
            didSummarize = true
            return
        }
        didSummarize = true
        let summary = await generateSummary()
        let sessionName = sessionURL?.lastPathComponent ?? "session.jsonl"
        EmployeeChatStore.appendSummary(botId: bot.id, sessionFileName: sessionName, summary: summary)
        if let sessionURL {
            EmployeeChatStore.append(
                line: .init(
                    ts: EmployeeChatStore.isoNow(),
                    role: "meta",
                    content: summary,
                    toolName: nil,
                    toolArgsSummary: nil,
                    ok: nil,
                    ms: nil,
                    event: "session_end:\(reason)"
                ),
                to: sessionURL
            )
        }
        reloadSummary()
    }

    private func generateSummary() async -> String {
        let transcript = messages
            .filter { $0.role == .user || $0.role == .assistant }
            .suffix(24)
            .map { "\($0.role.rawValue): \($0.content)" }
            .joined(separator: "\n")
        let prompt = """
        请用中文写一段不超过 150 字的工作摘要，包含：问了什么、做了/决定了什么、待办。不要客套。
        对话：
        \(transcript)
        """
        guard let store else {
            return fallbackSummary()
        }
        let key = SharedModelStore.loadKey(providerId: selectedProviderId) ?? AgentKeychain.loadKey() ?? ""
        guard !key.isEmpty else { return fallbackSummary() }
        let cfg = AgentLLMClient.Config(baseURL: baseURL, model: model, apiKey: key)
        let apiMessages: [[String: Any]] = [
            ["role": "system", "content": "你是会议纪要助手，只输出摘要正文。"],
            ["role": "user", "content": prompt]
        ]
        do {
            let result = try await llm.streamChat(config: cfg, messages: apiMessages, tools: []) { _ in }
            let text = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { return fallbackSummary() }
            if text.count > 400 { return String(text.prefix(400)) + "…" }
            return text
        } catch {
            return fallbackSummary() + "（自动摘要失败：\(error.localizedDescription)）"
        }
    }

    private func fallbackSummary() -> String {
        let users = messages.filter { $0.role == .user }.map(\.content)
        let asked = users.suffix(3).joined(separator: "；")
        return "与「\(bot.name)」对话。主要问题：\(asked.isEmpty ? "（无）" : asked)。详情见会话 JSONL。"
    }
}
