import SwiftUI

/// P0 Global Agent: ⌘K panel — streaming chat + visible L0 tool steps.
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
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(vm.messages) { msg in
                                messageRow(msg).id(msg.id)
                            }
                            ForEach(vm.steps) { step in
                                stepRow(step).id(step.id)
                            }
                            if vm.isStreaming {
                                ProgressView().scaleEffect(0.8).padding(.leading, 8)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: vm.messages.count) { _ in
                        if let last = vm.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }
                Divider()
                composer
            }
            .frame(maxWidth: 720, maxHeight: 640)
            .background(SWTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        HStack {
            Image(systemName: "sparkles")
            Text("全局 Agent").font(.headline)
            Text("P2 · CRM + 确认").font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button("设置") { vm.showSettings = true }
                .buttonStyle(.borderless)
            Button { isPresented = false } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(14)
        .sheet(isPresented: $vm.showSettings) {
            AgentSettingsSheet(vm: vm)
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("问工作台…（⌘K 开关 · Esc 关闭）", text: $vm.draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .onSubmit { Task { await vm.send() } }
            Button {
                Task { await vm.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(vm.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isStreaming)
        }
        .padding(14)
    }

    private func messageRow(_ msg: AgentChatMessage) -> some View {
        HStack(alignment: .top) {
            if msg.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(msg.role == .user ? "你" : (msg.role == .tool ? "工具" : "Agent"))
                    .font(.caption2).foregroundStyle(.secondary)
                Text(msg.content)
                    .font(.system(size: SWTheme.Typography.body))
                    .textSelection(.enabled)
            }
            .padding(10)
            .background(msg.role == .user ? Color.accentColor.opacity(0.12) : Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            if msg.role != .user { Spacer(minLength: 40) }
        }
    }

    private func stepRow(_ step: AgentStepEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: step.ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(step.ok ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(step.name).font(.system(size: 13, weight: .semibold))
                Text(step.argsSummary).font(.caption).foregroundStyle(.secondary)
                Text(step.detail).font(.caption).lineLimit(8).textSelection(.enabled)
            }
            Spacer()
            Text("\(step.ms)ms").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

@MainActor
final class GlobalAgentViewModel: ObservableObject {
    @Published var messages: [AgentChatMessage] = []
    @Published var steps: [AgentStepEvent] = []
    @Published var draft: String = ""
    @Published var isStreaming = false
    @Published var showSettings = false
    @Published var baseURL: String = UserDefaults.standard.string(forKey: "sw.agent.baseURL") ?? "https://api.deepseek.com"
    @Published var model: String = UserDefaults.standard.string(forKey: "sw.agent.model") ?? "deepseek-chat"
    @Published var keyDraft: String = ""
    @Published var status: String = ""
    struct ProviderItem: Identifiable, Equatable { var id: String; var name: String; var baseURL: String; var model: String }
    @Published var providerList: [ProviderItem] = []
    @Published var selectedProviderId: String = ""

    private var store: WorkspaceStore?
    private let executor = AgentExecutor()
    private let llm = AgentLLMClient()

    func attach(store: WorkspaceStore) {
        self.store = store
        executor.store = store
        executor.audit = AgentAuditLog(repoRoot: store.repoRoot)
        executor.confirmHandler = { [weak self] name, summary, _ in
            guard let self else { return false }
            return await self.askConfirm(name: name, summary: summary)
        }
        if messages.isEmpty {
            messages.append(AgentChatMessage(role: .assistant, content: "全局 Agent P2：CRM 搜索/跟进/报价草稿(L2)/外发拦截(L3)。配置 Key 流式 tools；无 Key 本地指令（例：搜客户 菲律宾）。"))
        }
    }

    @Published var confirmText: String = ""
    private var confirmContinuation: CheckedContinuation<Bool, Never>? = nil
    @Published var showConfirm = false

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
        if !k.isEmpty { AgentKeychain.saveKey(k); keyDraft = "" }
        status = "已保存（Key 在 Keychain）"
    }

    func importMagicHubProviders() {
        guard let store else { status = "无 store"; return }
        let url = store.repoRoot.appendingPathComponent("超级工作台应用/data/private/crm/settings/magichub_ai_providers.json")
        guard let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) else {
            status = "未找到 magichub_ai_providers.json"; return
        }
        var arr: [[String: Any]] = []
        if let a = obj as? [[String: Any]] { arr = a }
        else if let d = obj as? [String: Any] {
            arr = (d["providers"] as? [[String: Any]]) ?? (d["data"] as? [[String: Any]]) ?? []
        }
        var items: [ProviderItem] = []
        for (i, p) in arr.enumerated() {
            let base = (p["baseURL"] as? String) ?? (p["baseUrl"] as? String) ?? (p["apiBase"] as? String) ?? ""
            let model = (p["model"] as? String) ?? (p["defaultModel"] as? String) ?? ""
            let name = (p["name"] as? String) ?? (p["label"] as? String) ?? "provider-\(i)"
            let id = (p["id"] as? String) ?? "p\(i)"
            if !base.isEmpty {
                items.append(ProviderItem(id: id, name: name, baseURL: base, model: model.isEmpty ? self.model : model))
            }
        }
        providerList = items
        if let first = items.first {
            selectedProviderId = first.id
            applySelectedProvider()
        }
        status = items.isEmpty ? "列表为空" : "已导入 \(items.count) 个（未导入任何 API Key）"
    }

    func applySelectedProvider() {
        guard let p = providerList.first(where: { $0.id == selectedProviderId }) else { return }
        baseURL = p.baseURL
        if !p.model.isEmpty { model = p.model }
    }

    func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        draft = ""
        messages.append(AgentChatMessage(role: .user, content: text))
        isStreaming = true
        defer { isStreaming = false }

        if let key = AgentKeychain.loadKey(), !key.isEmpty {
            await runLLM(userText: text, apiKey: key)
        } else {
            await runLocal(userText: text)
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
        var lines: [String] = ["（本地模式 · 未配置 API Key）"]
        for (name, params) in actions {
            let step = await executor.execute(name: name, params: params)
            steps.append(step)
            messages.append(AgentChatMessage(role: .tool, content: step.detail, toolName: name, toolArgsSummary: step.argsSummary, ok: step.ok, ms: step.ms))
            lines.append("• \(name): \(step.ok ? "OK" : "FAIL")")
        }
        messages.append(AgentChatMessage(role: .assistant, content: lines.joined(separator: "\n")))
    }

    private func runLLM(userText: String, apiKey: String) async {
        let snap = await executor.execute(name: "context.get_snapshot", params: ["scope": "brief"])
        steps.append(snap)
        let system = """
        你是超级工作台全局 Agent。只使用提供的 tools 操控工作台。当前上下文：
        \(snap.detail)
        用中文简短回复。单轮 tool 不超过 8 次。
        """
        var apiMessages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": userText]
        ]
        let tools = AgentLLMClient.openAIToolsFromSchema()
        let cfg = AgentLLMClient.Config(baseURL: baseURL, model: model, apiKey: apiKey)
        var assistantId = UUID()
        messages.append(AgentChatMessage(id: assistantId, role: .assistant, content: ""))
        var loops = 0
        while loops < 8 {
            loops += 1
            do {
                let result = try await llm.streamChat(config: cfg, messages: apiMessages, tools: tools) { delta in
                    Task { @MainActor in
                        if let idx = self.messages.firstIndex(where: { $0.id == assistantId }) {
                            self.messages[idx].content += delta
                        }
                    }
                }
                if let idx = messages.firstIndex(where: { $0.id == assistantId }), messages[idx].content.isEmpty, !result.content.isEmpty {
                    messages[idx].content = result.content
                }
                if result.toolCalls.isEmpty { break }
                apiMessages.append([
                    "role": "assistant",
                    "content": result.content,
                    "tool_calls": result.toolCalls
                ])
                for tc in result.toolCalls {
                    guard let fn = tc["function"] as? [String: Any],
                          let name = fn["name"] as? String else { continue }
                    let argStr = fn["arguments"] as? String ?? "{}"
                    let params = (try? JSONSerialization.jsonObject(with: Data(argStr.utf8))) as? [String: Any] ?? [:]
                    let step = await executor.execute(name: name, params: params)
                    steps.append(step)
                    messages.append(AgentChatMessage(role: .tool, content: step.detail, toolName: name, toolArgsSummary: step.argsSummary, ok: step.ok, ms: step.ms))
                    apiMessages.append([
                        "role": "tool",
                        "tool_call_id": tc["id"] as? String ?? name,
                        "content": step.detail
                    ])
                }
                assistantId = UUID()
                messages.append(AgentChatMessage(id: assistantId, role: .assistant, content: ""))
            } catch {
                messages.append(AgentChatMessage(role: .assistant, content: "调用失败：\(error.localizedDescription)"))
                break
            }
        }
    }
}

struct AgentSettingsSheet: View {
    @ObservedObject var vm: GlobalAgentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("全局 Agent · 模型").font(.title3.bold())
            Text("OpenAI 兼容 · Key 存 Keychain（不进 git）").font(.caption).foregroundStyle(.secondary)
            TextField("Base URL", text: $vm.baseURL)
            TextField("Model", text: $vm.model)
            SecureField("API Key（留空则保留原 Key）", text: $vm.keyDraft)
            if !vm.status.isEmpty { Text(vm.status).font(.caption).foregroundStyle(.green) }
            HStack {
                Button("清除 Key") { AgentKeychain.deleteKey(); vm.status = "Key 已清除" }
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") { vm.saveSettings(); dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            Divider().padding(.vertical, 4)
            Button("从 MagicHub 导入 Provider 列表") { vm.importMagicHubProviders() }
                .buttonStyle(.bordered)
            if !vm.providerList.isEmpty {
                Text("已载入 \(vm.providerList.count) 个网关（Key 仍用上方 Keychain，不读 MagicHub 密钥文件进聊天）")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("选用", selection: $vm.selectedProviderId) {
                    ForEach(vm.providerList, id: \.id) { p in
                        Text(p.name).tag(p.id)
                    }
                }
                .onChange(of: vm.selectedProviderId) { vm.applySelectedProvider() }
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
