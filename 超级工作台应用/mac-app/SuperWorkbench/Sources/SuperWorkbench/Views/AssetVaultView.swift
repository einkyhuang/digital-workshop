import SwiftUI
import AppKit
import LocalAuthentication
import UniformTypeIdentifiers
import AssetVaultCore

extension Notification.Name {
    static let swNewAssetAccount = Notification.Name("swNewAssetAccount")
}

enum DeviceOwnerAuth {
    /// Touch ID when the Mac has it, otherwise the device password. Fail closed.
    static func confirm(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "取消"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return false }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

@MainActor
final class AssetVaultModel: ObservableObject {
    @Published var accounts: [AssetAccount] = []
    @Published var query = ""
    @Published var category = "全部"
    @Published var status = "密码和 API 以圆点显示。复制前需要 Touch ID 或开机密码，复制后仍保持隐藏。"
    @Published var copiedKey = ""
    @Published var editor: AssetEditorSession?
    @Published var pendingDelete: AssetAccount?
    @Published var importing = false

    private var fileStore: AssetFileStore?
    private let keychain = KeychainAssetSecretStore()
    private let clipboard = AssetClipboard()
    private var configured = false
    private var copyToken = 0

    var categoryChoices: [AssetCategoryTab] {
        AssetVault.categoryTabs(accounts)
    }

    var filtered: [AssetAccount] {
        AssetVault.filter(accounts, query: query, category: category)
    }

    func configure(repoRoot: URL) {
        let root = repoRoot.appendingPathComponent("超级工作台应用/data/private/资产管理", isDirectory: true)
        if configured, fileStore?.root.path == root.path { return }
        fileStore = AssetFileStore(root: root)
        configured = true
        reload()
    }

    func reload() {
        guard let fileStore else { return }
        do {
            accounts = try fileStore.list(secrets: keychain)
            if !categoryChoices.contains(where: { $0.name == category }) { category = "全部" }
        } catch {
            status = "读取档案失败"
        }
    }

    func startNew() {
        editor = AssetEditorSession(account: .empty)
    }

    func save(account: AssetAccount, patch: AssetSecretPatch) {
        guard let fileStore else { return }
        var raw = account.fileJSON()
        raw.removeValue(forKey: "id")
        if !account.id.isEmpty { raw["id"] = account.id }
        for (key, value) in patch.values { raw[key] = value }
        do {
            _ = try fileStore.save(raw: raw, secrets: keychain)
            editor = nil
            reload()
            status = "已保存。密码在钥匙串里，没有写进文件。"
        } catch AssetVaultError.invalidPlatform {
            status = "请填写平台名称"
        } catch {
            status = "保存失败"
        }
    }

    func delete(_ account: AssetAccount) async {
        guard let fileStore, AssetVault.isValidId(account.id) else { return }
        if account.hasSecret {
            let ok = await DeviceOwnerAuth.confirm(reason: "删除「\(account.platform)」及其钥匙串密码")
            guard ok else {
                status = "未通过设备验证，没有删除"
                return
            }
        }
        do {
            _ = try fileStore.delete(id: account.id, secrets: keychain)
            if editor?.account.id == account.id { editor = nil }
            pendingDelete = nil
            reload()
            status = "已删除"
        } catch {
            status = "删除失败"
        }
    }

    func revealSecrets(for account: AssetAccount) async -> AssetSecrets? {
        let ok = await DeviceOwnerAuth.confirm(reason: "查看「\(account.platform)」的密码")
        guard ok else {
            status = "未通过设备验证"
            return nil
        }
        guard AssetVault.isValidId(account.id) else { return .empty }
        return (try? keychain.load(id: account.id)) ?? .empty
    }

    func copy(_ text: String, platform: String) async {
        let ok = await DeviceOwnerAuth.confirm(reason: "复制「\(platform)」的密码")
        guard ok else {
            status = "未通过设备验证，没有复制"
            return
        }
        copyVerified(text)
    }

    func copyVerified(_ text: String) {
        guard !text.isEmpty else {
            status = "没有可复制的密码"
            return
        }
        clipboard.copySecret(text)
        status = "已复制。约 45 秒后，如果剪贴板仍是这条内容，会自动清除。"
    }

    func copyField(_ field: AssetCopyField, from account: AssetAccount) async {
        if field.secret {
            await copySecretField(field, from: account)
            return
        }
        let text = AssetVault.copyText(for: field)
        guard !text.isEmpty else { return }
        clipboard.copyPublic(text)
        flashCopied(account.id, field.id)
        status = "已复制"
    }

    private func copySecretField(_ field: AssetCopyField, from account: AssetAccount) async {
        let ok = await DeviceOwnerAuth.confirm(reason: "复制「\(account.platform)」的\(field.label)")
        guard ok else {
            status = "未通过设备验证，没有复制"
            return
        }
        guard AssetVault.isValidId(account.id) else {
            status = "没有可复制的内容"
            return
        }
        let loaded = (try? keychain.load(id: account.id)) ?? .empty
        let secret: String
        switch field.id {
        case "password": secret = loaded.password
        case "apiKey": secret = loaded.apiKey
        default:
            status = "没有可复制的内容"
            return
        }
        guard !secret.isEmpty else {
            status = "没有可复制的内容"
            return
        }
        clipboard.copySecret(secret)
        flashCopied(account.id, field.id)
        status = "已复制。约 45 秒后，如果剪贴板仍是这条内容，会自动清除。"
    }

    private func flashCopied(_ id: String, _ field: String) {
        copyToken += 1
        let token = copyToken
        copiedKey = "\(id)|\(field)"
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if token == self.copyToken { self.copiedKey = "" }
        }
    }

    func importCSV(_ text: String) {
        guard let fileStore else { return }
        guard text.count <= AssetVaultCatalog.csvMaxChars else {
            status = "CSV 过大，没有导入"
            return
        }
        let result = fileStore.importCSV(text, secrets: keychain)
        reload()
        status = "导入 \(result.imported) 条。其中 \(result.secretsStored) 条的密钥已放入钥匙串，没有写入文件。"
    }

    func openLogin(_ account: AssetAccount) {
        guard let url = URL(string: account.loginURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.user == nil, url.password == nil else {
            status = "登录地址需要是 http 或 https，且不能在地址里夹带密码"
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private final class AssetClipboard {
    private var timer: Timer?
    private var expected = ""
    private var changeCount = 0

    func copyPublic(_ text: String) {
        timer?.invalidate()
        timer = nil
        expected = ""
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(text, forType: .string)
    }

    func copySecret(_ text: String) {
        let board = NSPasteboard.general
        board.clearContents()
        board.setString(text, forType: .string)
        expected = text
        changeCount = board.changeCount
        timer?.invalidate()
        let seconds = AssetVaultCatalog.clipboardClearSeconds
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self else { return }
            let board = NSPasteboard.general
            let current = board.string(forType: .string)
            guard board.changeCount == self.changeCount,
                  ClipboardClearPolicy.shouldClear(copied: self.expected, current: current, elapsed: seconds) else { return }
            board.clearContents()
            self.expected = ""
        }
    }
}

struct AssetVaultView: View {
    @EnvironmentObject var store: WorkspaceStore
    @StateObject private var model = AssetVaultModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            categoryPills
            if model.filtered.isEmpty {
                Text(model.accounts.isEmpty ? "还没有账号。点「新建」添加，或从 CSV 导入。密码不会出现在仓库里。" : "没有符合筛选的账号。")
                    .font(.subheadline)
                    .foregroundStyle(SWTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .swCard()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                        ForEach(model.filtered) { account in
                            card(account)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            model.configure(repoRoot: store.repoRoot)
            store.assetAccountCount = model.accounts.count
        }
        .onChange(of: model.accounts.count) { _, _ in
            store.assetAccountCount = model.accounts.count
        }
        .onReceive(NotificationCenter.default.publisher(for: .swNewAssetAccount)) { _ in
            model.startNew()
        }
        .sheet(item: $model.editor) { session in
            AssetEditorSheet(account: session.account, model: model)
        }
        .alert("删除这条账号？", isPresented: Binding(
            get: { model.pendingDelete != nil },
            set: { if !$0 { model.pendingDelete = nil } }
        )) {
            Button("删除", role: .destructive) {
                if let account = model.pendingDelete {
                    Task { await model.delete(account) }
                }
            }
            Button("取消", role: .cancel) { model.pendingDelete = nil }
        } message: {
            Text("会删除本地档案，并移除钥匙串里对应的密码。不能撤销。")
        }
        .fileImporter(isPresented: $model.importing, allowedContentTypes: [.commaSeparatedText, .plainText, .text]) { result in
            guard case .success(let url) = result else { return }
            let started = url.startAccessingSecurityScopedResource()
            defer { if started { url.stopAccessingSecurityScopedResource() } }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                model.status = "读不到这个 CSV"
                return
            }
            model.importCSV(text)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.activeWorkbenchId == "trade" {
                Text("资产管理")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(SWTheme.text)
            }
            HStack(spacing: 8) {
                TextField("搜索平台、账号、邮箱、备注、标签", text: $model.query)
                    .textFieldStyle(.roundedBorder)
                Button("新建") { model.startNew() }
                    .buttonStyle(.borderedProminent)
                Button("导入 CSV") { model.importing = true }
                    .buttonStyle(.bordered)
            }
            Text(model.status)
                .font(.caption)
                .foregroundStyle(SWTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.categoryChoices) { tab in
                    let selected = model.category == tab.name
                    Button {
                        model.category = tab.name
                    } label: {
                        HStack(spacing: 6) {
                            Text(tab.name)
                            Text("\(tab.count)")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(selected ? Color.white.opacity(0.18) : Color.black.opacity(0.06))
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.white : SWTheme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selected ? SWTheme.accent : Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(selected ? Color.clear : SWTheme.border, lineWidth: 1))
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func card(_ account: AssetAccount) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(account.platform)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SWTheme.text)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(account.category)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SWTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Capsule())
            }
            if account.hasSecret || account.twoFactor != "none" {
                HStack(spacing: 6) {
                    if account.hasSecret {
                        Label("钥匙串", systemImage: "lock")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(red: 0.08, green: 0.45, blue: 0.28))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.86, green: 0.95, blue: 0.88))
                            .clipShape(Capsule())
                    }
                    if account.twoFactor != "none" {
                        Text(account.twoFactorLabel)
                            .font(.caption)
                            .foregroundStyle(SWTheme.textSecondary)
                    }
                }
            }
            VStack(spacing: 6) {
                ForEach(AssetVault.cardFields(for: account)) { field in
                    copyRow(field, account: account)
                }
            }
            if !account.company.isEmpty || !account.brand.isEmpty {
                Text([account.company, account.brand].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(SWTheme.textSecondary)
            }
            if !account.tags.isEmpty {
                Text(account.tags.joined(separator: "  "))
                    .font(.caption)
                    .foregroundStyle(SWTheme.textMuted)
            }
            if !account.notes.isEmpty {
                Text(account.notes)
                    .font(.caption)
                    .foregroundStyle(SWTheme.textSecondary)
                    .lineLimit(2)
            }
            HStack(spacing: 12) {
                Button("编辑") { model.editor = AssetEditorSession(account: account) }
                    .buttonStyle(.borderless)
                Button("删除") { model.pendingDelete = account }
                    .buttonStyle(.borderless)
                Spacer()
                Text(account.updatedAt)
                    .font(.caption2)
                    .foregroundStyle(SWTheme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCard()
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private func copyRow(_ field: AssetCopyField, account: AssetAccount) -> some View {
        let copied = model.copiedKey == "\(account.id)|\(field.id)"
        return HStack(spacing: 8) {
            Button {
                Task { await model.copyField(field, from: account) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: symbol(for: field))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(SWTheme.textSecondary)
                        .frame(width: 16)
                    Text(field.label)
                        .font(.system(size: 12))
                        .foregroundStyle(SWTheme.textSecondary)
                        .frame(width: 64, alignment: .leading)
                    Text(field.secret ? "••••••••" : field.value)
                        .font(.system(size: 13, design: field.secret ? .monospaced : .default))
                        .foregroundStyle(SWTheme.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 4)
                    if copied {
                        Text("已复制")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(red: 0.08, green: 0.45, blue: 0.28))
                    } else {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundStyle(SWTheme.textMuted)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(field.secret ? "验证后复制，内容保持隐藏" : "点击复制")
            if field.id == "loginURL" {
                Button {
                    model.openLogin(account)
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("打开登录页")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func symbol(for field: AssetCopyField) -> String {
        switch field.icon {
        case "envelope": return "envelope"
        case "key": return "key"
        case "api": return "chevron.left.forwardslash.chevron.right"
        case "link": return "link"
        default: return "person"
        }
    }
}

struct AssetEditorSession: Identifiable {
    let id = UUID()
    var account: AssetAccount
}

private struct AssetEditorSheet: View {
    let account: AssetAccount
    @ObservedObject var model: AssetVaultModel
    @Environment(\.dismiss) private var dismiss

    @State private var platform: String
    @State private var category: String
    @State private var customCategory = ""
    @State private var loginURL: String
    @State private var username: String
    @State private var email: String
    @State private var notes: String
    @State private var twoFactor: String
    @State private var tags: String
    @State private var company: String
    @State private var brand: String
    @State private var password = ""
    @State private var apiKey = ""
    @State private var recoveryCodes = ""
    @State private var totpSecret = ""
    @State private var keepTotp = false
    @State private var passwordDirty = false
    @State private var apiDirty = false
    @State private var recoveryDirty = false
    @State private var totpDirty = false
    @State private var revealed = false
    @State private var length = 20.0
    @State private var useSymbols = true

    init(account: AssetAccount, model: AssetVaultModel) {
        self.account = account
        self.model = model
        _platform = State(initialValue: account.platform)
        _category = State(initialValue: AssetVaultCatalog.categories.contains(account.category) ? account.category : "其他")
        _customCategory = State(initialValue: AssetVaultCatalog.categories.contains(account.category) ? "" : account.category)
        _loginURL = State(initialValue: account.loginURL)
        _username = State(initialValue: account.username)
        _email = State(initialValue: account.email)
        _notes = State(initialValue: account.notes)
        _twoFactor = State(initialValue: account.twoFactor.isEmpty ? "none" : account.twoFactor)
        _tags = State(initialValue: account.tags.joined(separator: ", "))
        _company = State(initialValue: account.company)
        _brand = State(initialValue: account.brand)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(account.id.isEmpty ? "新建账号" : "编辑账号").font(.title2.bold())
            Text(account.hasSecret ? "钥匙串里已有密钥。留空表示不修改；显示或复制需要验证。" : "密码默认隐藏。不会写进 JSON 或 iCloud 文档。")
                .font(.caption)
                .foregroundStyle(.secondary)
            form
            secretFields
            generator
            HStack {
                if !account.id.isEmpty {
                    Button("删除", role: .destructive) {
                        let target = account
                        dismiss()
                        model.pendingDelete = target
                    }
                }
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    private var form: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            labeled("平台") { TextField("例如：店铺后台", text: $platform) }
            labeled("分类") {
                HStack {
                    Picker("分类", selection: $category) {
                        ForEach(AssetVaultCatalog.categories, id: \.self) { Text($0).tag($0) }
                    }
                    .labelsHidden()
                    TextField("或自定义", text: $customCategory)
                }
            }
            labeled("登录地址") { TextField("https://", text: $loginURL) }
            labeled("账号") { TextField("用户名", text: $username) }
            labeled("邮箱") { TextField("可选", text: $email) }
            labeled("二次验证") {
                Picker("二次验证", selection: $twoFactor) {
                    ForEach(AssetVaultCatalog.twoFactorOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .labelsHidden()
            }
            labeled("标签") { TextField("用逗号分隔", text: $tags) }
            labeled("公司") { TextField("关联公司", text: $company) }
            labeled("品牌") { TextField("关联品牌", text: $brand) }
            labeled("备注") { TextField("不要在备注里写密码", text: $notes, axis: .vertical) }
        }
    }

    private var secretFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("密钥").font(.headline)
                Spacer()
                Button(revealed ? "隐藏" : "显示") { Task { await toggleReveal() } }
                Button("复制密码") { Task { await copyPassword() } }
            }
            secretRow("密码", text: $password, dirty: $passwordDirty)
            secretRow("API 密钥", text: $apiKey, dirty: $apiDirty)
            DisclosureGroup("恢复码（只有明确要保存时才填）") {
                secretRow("恢复码", text: $recoveryCodes, dirty: $recoveryDirty)
            }
            Toggle("我明确要保存验证器密钥", isOn: $keepTotp)
                .font(.caption)
            if keepTotp {
                secretRow("验证器密钥", text: $totpSecret, dirty: $totpDirty)
            }
        }
    }

    private var generator: some View {
        HStack {
            Text("生成密码")
            Slider(value: $length, in: 12...40, step: 1)
            Text("\(Int(length))").frame(width: 28)
            Toggle("符号", isOn: $useSymbols).toggleStyle(.checkbox)
            Button("生成") { generate() }
        }
        .font(.caption)
    }

    @ViewBuilder
    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        GridRow {
            Text(title).frame(width: 72, alignment: .leading)
            content().textFieldStyle(.roundedBorder)
        }
    }

    private func secretRow(_ title: String, text: Binding<String>, dirty: Binding<Bool>) -> some View {
        HStack {
            Text(title).frame(width: 72, alignment: .leading).font(.caption)
            Group {
                if revealed {
                    TextField(title, text: text)
                } else {
                    SecureField(account.hasSecret ? "已保存，留空不修改" : title, text: text)
                }
            }
            .textFieldStyle(.roundedBorder)
            .onChange(of: text.wrappedValue) { _, _ in dirty.wrappedValue = true }
        }
    }

    private func currentAccount() -> AssetAccount {
        var next = account
        next.platform = platform.trimmingCharacters(in: .whitespacesAndNewlines)
        let custom = customCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        next.category = custom.isEmpty ? category : custom
        next.loginURL = loginURL
        next.username = username
        next.email = email
        next.notes = notes
        next.twoFactor = twoFactor
        next.tags = tags.split { ",，;；".contains($0) }.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        next.company = company
        next.brand = brand
        return next
    }

    private func patch() -> AssetSecretPatch {
        var values: [String: String] = [:]
        if passwordDirty { values["password"] = password }
        if apiDirty { values["apiKey"] = apiKey }
        if recoveryDirty { values["recoveryCodes"] = recoveryCodes }
        if keepTotp && totpDirty { values["totpSecret"] = totpSecret }
        return AssetSecretPatch(values: values)
    }

    private func save() {
        model.save(account: currentAccount(), patch: patch())
    }

    private func generate() {
        guard let value = try? AssetVault.generatePassword(length: Int(length), symbols: useSymbols) else { return }
        password = value
        passwordDirty = true
        revealed = false
    }

    private func toggleReveal() async {
        if revealed {
            revealed = false
            return
        }
        if let loaded = await model.revealSecrets(for: account) {
            if !passwordDirty && password.isEmpty { password = loaded.password }
            if !apiDirty && apiKey.isEmpty { apiKey = loaded.apiKey }
            if !recoveryDirty && recoveryCodes.isEmpty { recoveryCodes = loaded.recoveryCodes }
            if !totpDirty && !loaded.totpSecret.isEmpty {
                totpSecret = loaded.totpSecret
                keepTotp = true
            }
            revealed = true
        }
    }

    private func copyPassword() async {
        let name = platform.isEmpty ? account.platform : platform
        if passwordDirty || revealed {
            await model.copy(password, platform: name)
            return
        }
        guard let loaded = await model.revealSecrets(for: account) else { return }
        if password.isEmpty { password = loaded.password }
        model.copyVerified(loaded.password)
    }
}

private extension AssetAccount {
    var twoFactorLabel: String {
        AssetVaultCatalog.twoFactorOptions.first { $0.id == twoFactor }?.label ?? "无"
    }
}
