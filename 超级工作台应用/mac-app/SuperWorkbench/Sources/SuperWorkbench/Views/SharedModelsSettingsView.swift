import SwiftUI

/// Global model / API settings shared with MagicHub (Application Support models.json + Keychain).
struct SharedModelsSettingsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    @State private var providers: [ProviderRow] = []
    @State private var selectedId: String = ""
    @State private var status: String = ""
    @State private var keyDraft: String = ""

    struct ProviderRow: Identifiable, Equatable {
        var id: String
        var name: String
        var baseURL: String
        var model: String
        var enabled: Bool
        var hasKey: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("全局模型设置").font(.title2.bold())
                    Text("超级工作台与外贸工作台共用 · ~/Library/Application Support/超级工作台/models.json")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            HStack(alignment: .top, spacing: 16) {
                List(selection: $selectedId) {
                    ForEach(providers) { p in
                        HStack {
                            Circle()
                                .fill(p.enabled ? Color.green : Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.system(size: 13, weight: .semibold))
                                Text(p.model).font(.caption2.monospaced()).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if p.hasKey {
                                Image(systemName: "key.fill").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .tag(p.id)
                    }
                }
                .frame(minWidth: 200, maxWidth: 240)
                .listStyle(.inset)

                if let binding = selectedBinding {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("启用", isOn: binding.enabled)
                        TextField("Base URL", text: binding.baseURL)
                            .textFieldStyle(.roundedBorder)
                        TextField("默认模型", text: binding.model)
                            .textFieldStyle(.roundedBorder)
                        SecureField("API Key（留空保留原值）", text: $keyDraft)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Button("清除 Key") {
                                SharedModelStore.deleteKey(providerId: selectedId)
                                keyDraft = ""
                                persist(clearKey: true)
                                status = "已清除该平台 Key"
                            }
                            Spacer()
                            Button("保存") { persist(clearKey: false); status = "已保存到全局配置" }
                                .buttonStyle(.borderedProminent)
                        }
                        if !status.isEmpty {
                            Text(status).font(.caption).foregroundStyle(.green)
                        }
                        Text("外贸工作台「系统设置 → AI 模型平台接入」读写同一份配置。")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("选择左侧平台").foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(20)
        .frame(width: 640, height: 420)
        .onAppear(perform: reload)
    }

    private var selectedBinding: Binding<ProviderRow>? {
        guard let idx = providers.firstIndex(where: { $0.id == selectedId }) else { return nil }
        return $providers[idx]
    }

    private func reload() {
        let raw = SharedModelStore.loadProviders(repoRoot: store.repoRoot)
        let doc = SharedModelStore.loadDocument(repoRoot: store.repoRoot)
        var rows: [ProviderRow] = []
        for p in raw {
            guard let id = p["id"] as? String else { continue }
            let name = (p["name"] as? String) ?? id
            let base = (p["baseUrl"] as? String) ?? (p["baseURL"] as? String) ?? ""
            let model = (p["model"] as? String) ?? ""
            let enabled = (p["status"] as? Bool) ?? false
            let key = (p["apiKey"] as? String) ?? ""
            let has = !key.isEmpty || (SharedModelStore.loadKey(providerId: id)?.isEmpty == false)
            rows.append(ProviderRow(id: id, name: name, baseURL: base, model: model, enabled: enabled, hasKey: has))
        }
        providers = rows
        if selectedId.isEmpty || !rows.contains(where: { $0.id == selectedId }) {
            selectedId = doc.activeProviderId.isEmpty ? (rows.first?.id ?? "") : doc.activeProviderId
        }
        keyDraft = ""
        status = rows.isEmpty ? "暂无平台" : "已载入 \(rows.count) 个平台"
    }

    private func persist(clearKey: Bool) {
        var raw = SharedModelStore.loadProviders(repoRoot: store.repoRoot)
        for row in providers {
            if let idx = raw.firstIndex(where: { ($0["id"] as? String) == row.id }) {
                raw[idx]["baseUrl"] = row.baseURL
                raw[idx]["model"] = row.model
                raw[idx]["status"] = row.enabled
                if row.id == selectedId {
                    if clearKey {
                        raw[idx]["apiKey"] = ""
                    } else {
                        let k = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !k.isEmpty {
                            raw[idx]["apiKey"] = k
                            SharedModelStore.saveKey(providerId: row.id, key: k)
                            AgentKeychain.saveKey(k)
                        }
                    }
                }
            }
        }
        _ = SharedModelStore.saveProviders(raw, activeProviderId: selectedId, repoRoot: store.repoRoot)
        keyDraft = ""
        reload()
    }
}
