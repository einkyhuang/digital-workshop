import XCTest
@testable import AssetVaultCore

final class AssetVaultTests: XCTestCase {
    private let fakePassword = "csv-test-pw-not-real"

    func testSplitRecordKeepsSecretsOutOfThePublicAccount() throws {
        let draft = try AssetVault.splitRecord([
            "platform": "示例平台",
            "category": "电商",
            "loginURL": "https://example.com/login",
            "username": "name@example.com",
            "password": fakePassword,
            "api_key": "test-api-key",
            "recoveryCodes": "test-recovery",
            "totpSecret": "test-totp",
            "token": "test-token",
            "notes": "不要把密码写在这里",
            "tags": "店铺, 主号",
        ])
        XCTAssertEqual(draft.account.platform, "示例平台")
        XCTAssertEqual(draft.account.category, "电商")
        XCTAssertEqual(draft.patch.values["password"], fakePassword)
        XCTAssertEqual(draft.patch.values["apiKey"], "test-api-key")
        XCTAssertEqual(draft.patch.values["extra"], "test-token")
        XCTAssertFalse(AssetVault.containsSecretKey(draft.account.fileJSON()))
        let encoded = String(data: try JSONSerialization.data(withJSONObject: draft.account.apiJSON()), encoding: .utf8) ?? ""
        XCTAssertFalse(encoded.contains(fakePassword))
    }

    func testUnsafeURLsAndIdsAreRejected() throws {
        XCTAssertEqual(AssetVault.safeLoginURL("https://user:pw@example.com/login"), "")
        XCTAssertEqual(AssetVault.safeLoginURL("javascript:alert(1)"), "")
        XCTAssertEqual(AssetVault.safeLoginURL("https://example.com/login"), "https://example.com/login")
        XCTAssertThrowsError(try AssetVault.splitRecord(["platform": "示例平台", "id": "../outside"])) { error in
            XCTAssertEqual(error as? AssetVaultError, .invalidId)
        }
        let draft = try AssetVault.splitRecord(["platform": "示例平台", "category": "../../tmp"])
        XCTAssertFalse(draft.account.category.contains("/"))
        XCTAssertFalse(draft.account.category.contains(".."))
    }

    func testCSVAndFilterAndGenerator() throws {
        let csv = "platform,category,username,password\n\"Acme, Inc\",电商,name@example.com,\(fakePassword)\n"
        let parsed = AssetVault.parseCSV(csv)
        XCTAssertTrue(parsed.errors.isEmpty)
        XCTAssertEqual(parsed.rows.first?.account.platform, "Acme, Inc")
        XCTAssertEqual(parsed.rows.first?.patch.values["password"], fakePassword)
        let accounts = [
            AssetAccount(platform: "店铺甲", category: "电商", username: "a@example.com"),
            AssetAccount(platform: "广告户", category: "广告", notes: "投放", tags: ["主号"]),
        ]
        XCTAssertEqual(AssetVault.filter(accounts, query: "", category: "广告").count, 1)
        XCTAssertEqual(AssetVault.filter(accounts, query: "主号", category: "").first?.platform, "广告户")
        XCTAssertEqual(AssetVault.filter(accounts, query: "主号", category: "电商").count, 0)
        var n = 0
        let password = try AssetVault.generatePassword(length: 16, randomByte: {
            n += 17
            return UInt8(n % 256)
        })
        XCTAssertEqual(password.count, 16)
        XCTAssertFalse(password.contains(where: { "0OolI1".contains($0) }))
        XCTAssertTrue(ClipboardClearPolicy.shouldClear(copied: "abc", current: "abc", elapsed: 45))
        XCTAssertFalse(ClipboardClearPolicy.shouldClear(copied: "abc", current: "abc", elapsed: 44))
        XCTAssertFalse(ClipboardClearPolicy.shouldClear(copied: "abc", current: "其他内容", elapsed: 45))
    }

    func testFilesMovePlaintextIntoTheSecretStore() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("asset-vault-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("电商", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let planted = folder.appendingPathComponent("plantedid1.json")
        let plantedJSON: [String: Any] = [
            "id": "plantedid1",
            "platform": "手写条目",
            "category": "电商",
            "username": "name@example.com",
            "password": fakePassword,
            "updatedAt": "2026-11-11T00:00:00Z",
        ]
        try JSONSerialization.data(withJSONObject: plantedJSON).write(to: planted)
        let secrets = MemoryAssetSecretStore()
        let store = AssetFileStore(root: root)
        let listed = try store.list(secrets: secrets)
        XCTAssertEqual(listed.count, 1)
        XCTAssertTrue(listed[0].hasPassword)
        XCTAssertFalse(listed[0].hasApiKey)
        XCTAssertEqual(try secrets.load(id: "plantedid1")?.password, fakePassword)
        let rewritten = try String(contentsOf: planted, encoding: .utf8)
        XCTAssertFalse(rewritten.contains(fakePassword))
        XCTAssertFalse(rewritten.contains("password"))

        let saved = try store.save(raw: [
            "platform": "新平台",
            "category": "../../逃逸",
            "username": "other@example.com",
            "password": fakePassword,
            "loginURL": "https://user:pw@example.com/a",
        ], secrets: secrets)
        XCTAssertTrue(saved.hasSecret)
        XCTAssertTrue(saved.hasPassword)
        XCTAssertFalse(saved.hasApiKey)
        XCTAssertEqual(saved.loginURL, "")
        let tree = try fileTree(root)
        XCTAssertFalse(tree.contains(fakePassword))
        XCTAssertEqual(try secrets.load(id: saved.id)?.password, fakePassword)

        let imported = store.importCSV("platform,password\n导入平台,\(fakePassword)\n", secrets: secrets)
        XCTAssertEqual(imported.imported, 1)
        XCTAssertEqual(imported.secretsStored, 1)
        XCTAssertFalse(try fileTree(root).contains(fakePassword))
        XCTAssertFalse(try fileTree(root).contains("hasPassword"))
        XCTAssertTrue(try store.delete(id: saved.id, secrets: secrets))
        XCTAssertNil(try secrets.load(id: saved.id))
    }

    func testCategoryTabsAndCardCopyFields() throws {
        let accounts = [
            AssetAccount(platform: "店铺甲", category: "电商", username: "shop-user", email: "name@example.com"),
            AssetAccount(platform: "工具", category: "AI工具", username: "name@example.com", hasPassword: true),
            AssetAccount(platform: "广告户", category: "广告", username: "ads", hasApiKey: true, loginURL: "https://example.com/login"),
        ]
        XCTAssertEqual(AssetVault.categoryTabs(accounts), ["全部", "电商", "广告", "AI工具"])
        XCTAssertFalse(AssetVault.categoryTabs(accounts).contains("社交"))
        XCTAssertEqual(AssetVault.filter(accounts, query: "name@example.com", category: "电商").count, 1)
        XCTAssertEqual(AssetVault.filter(accounts, query: "name@example.com", category: "广告").count, 0)

        let shop = AssetVault.cardFields(for: accounts[0])
        XCTAssertEqual(shop.map(\.label), ["账号", "邮箱"])
        XCTAssertEqual(AssetVault.copyText(for: shop[1]), "name@example.com")

        let tool = AssetVault.cardFields(for: accounts[1])
        XCTAssertEqual(tool.map(\.label), ["账号/邮箱", "密码"])
        XCTAssertEqual(tool[1].value, "")
        XCTAssertTrue(tool[1].secret)
        XCTAssertEqual(AssetVault.copyText(for: tool[1]), "")

        let polluted = AssetCopyField(id: "password", label: "密码", icon: "key", value: fakePassword, secret: true)
        XCTAssertEqual(AssetVault.copyText(for: polluted), "")

        let ads = AssetVault.cardFields(for: accounts[2])
        XCTAssertEqual(ads.map(\.id), ["username", "apiKey", "loginURL"])
        XCTAssertEqual(ads.first { $0.id == "apiKey" }?.value, "")
        XCTAssertEqual(AssetVault.copyText(for: ads[2]), "https://example.com/login")

        let csv = "platform,账号,邮箱\n示例平台,shop-user,name@example.com\n"
        let parsed = AssetVault.parseCSV(csv)
        XCTAssertEqual(parsed.rows.first?.account.username, "shop-user")
        XCTAssertEqual(parsed.rows.first?.account.email, "name@example.com")
        XCTAssertTrue(parsed.rows.first?.patch.values.isEmpty ?? false)
        let legacy = try AssetVault.splitRecord(["platform": "示例平台", "username": "name@example.com"])
        XCTAssertEqual(legacy.account.email, "")
        XCTAssertEqual(AssetVault.cardFields(for: legacy.account).map(\.label), ["账号/邮箱"])
        let same = AssetAccount(platform: "示例平台", username: "Name@Example.com", email: "name@example.com")
        let combined = AssetVault.cardFields(for: same)
        XCTAssertEqual(combined.map(\.label), ["账号/邮箱"])
        XCTAssertEqual(combined.first?.value, "name@example.com")
    }

    private func fileTree(_ root: URL) throws -> String {
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return "" }
        var all = ""
        for case let url as URL in enumerator {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), !isDir.boolValue {
                all += (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            }
        }
        return all
    }
}
