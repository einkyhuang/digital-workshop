import test from "node:test";
import assert from "node:assert/strict";
import fs from "fs";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";
import {
  CLIPBOARD_CLEAR_MS,
  cardFields,
  categoryTabs,
  containsSecretKey,
  copyTextForField,
  fileRecord,
  filterAccounts,
  generatePassword,
  parseCSV,
  publicAccount,
  redactAssetJsonText,
  safeLoginURL,
  shouldClearClipboard,
  splitRecord,
} from "./asset-vault.mjs";
import { deleteAccount, importCsv, listAccounts, saveAccount } from "../../lan/asset-vault-store.mjs";
import { redactPrivateAssetBody } from "../../lan/asset-vault-http.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "../../..");
const FAKE_PASSWORD = "csv-test-pw-not-real";

test("splitRecord removes secret keys from the public account", () => {
  const { account, patch } = splitRecord({
    platform: "示例平台",
    category: "电商",
    loginURL: "https://example.com/login",
    username: "name@example.com",
    password: FAKE_PASSWORD,
    api_key: "test-api-key",
    recoveryCodes: "test-recovery",
    totpSecret: "test-totp",
    token: "test-token",
    notes: "不要把密码写在这里",
    tags: "店铺, 主号",
  }, "2026-11-11T00:00:00Z");
  assert.equal(account.platform, "示例平台");
  assert.equal(account.category, "电商");
  assert.equal(account.username, "name@example.com");
  assert.deepEqual(account.tags, ["店铺", "主号"]);
  assert.equal(patch.password, FAKE_PASSWORD);
  assert.equal(patch.apiKey, "test-api-key");
  assert.equal(patch.recoveryCodes, "test-recovery");
  assert.equal(patch.totpSecret, "test-totp");
  assert.equal(patch.extra, "test-token");
  assert.equal(containsSecretKey(fileRecord(account)), false);
  assert.equal(JSON.stringify(publicAccount(account, true)).includes(FAKE_PASSWORD), false);
});

test("login URLs with embedded passwords or other schemes are dropped", () => {
  assert.equal(safeLoginURL("https://user:pw@example.com/login"), "");
  assert.equal(safeLoginURL("javascript:alert(1)"), "");
  assert.equal(safeLoginURL("file:///tmp/x"), "");
  assert.equal(safeLoginURL("https://example.com/login"), "https://example.com/login");
  assert.equal(safeLoginURL(""), "");
});

test("category and id cannot escape the vault directory", () => {
  assert.throws(() => splitRecord({ platform: "示例平台", id: "../outside" }), /无效的条目 id/);
  const { account } = splitRecord({ platform: "示例平台", category: "../../tmp" });
  assert.equal(account.category.includes("/"), false);
  assert.equal(account.category.includes(".."), false);
});

test("csv import splits a quoted password out of the metadata", () => {
  const csv = [
    "platform,category,loginURL,username,password,notes",
    `"Acme, Inc",电商,https://example.com,name@example.com,"${FAKE_PASSWORD}",备注`,
  ].join("\n");
  const { rows, errors } = parseCSV(csv);
  assert.equal(errors.length, 0);
  assert.equal(rows.length, 1);
  assert.equal(rows[0].account.platform, "Acme, Inc");
  assert.equal(rows[0].patch.password, FAKE_PASSWORD);
  assert.equal(JSON.stringify(rows[0].account).includes(FAKE_PASSWORD), false);
});

test("filter matches category and query without looking at secrets", () => {
  const accounts = [
    { platform: "店铺甲", category: "电商", loginURL: "", username: "a@example.com", notes: "", tags: [], company: "", brand: "" },
    { platform: "广告户", category: "广告", loginURL: "", username: "b@example.com", notes: "投放", tags: ["主号"], company: "", brand: "" },
  ];
  assert.equal(filterAccounts(accounts, { category: "广告" }).length, 1);
  assert.equal(filterAccounts(accounts, { query: "投放" })[0].platform, "广告户");
  assert.equal(filterAccounts(accounts, { query: "主号" }).length, 1);
  assert.equal(filterAccounts(accounts, { category: "电商", query: "主号" }).length, 0);
});

test("category tabs list only categories that have accounts", () => {
  const accounts = [
    { platform: "店铺甲", category: "电商", username: "shop-user", email: "name@example.com", loginURL: "", notes: "", tags: [], company: "", brand: "" },
    { platform: "工具", category: "AI工具", username: "name@example.com", email: "", loginURL: "", notes: "", tags: [], company: "", brand: "", hasPassword: true, password: FAKE_PASSWORD },
    { platform: "广告户", category: "广告", username: "ads", email: "", loginURL: "https://example.com/login", notes: "", tags: [], company: "", brand: "", hasApiKey: true, apiKey: "test-api-key" },
  ];
  assert.deepEqual(categoryTabs(accounts), [
    { name: "全部", count: 3 },
    { name: "电商", count: 1 },
    { name: "广告", count: 1 },
    { name: "AI工具", count: 1 },
  ]);
  assert.equal(categoryTabs(accounts).some((item) => item.name === "社交"), false);
  assert.deepEqual(categoryTabs([]), [{ name: "全部", count: 0 }]);
  const custom = categoryTabs([
    { category: "AI工具" },
    { category: "AI工具" },
    { category: "SUNWIN" },
  ]);
  assert.deepEqual(custom, [
    { name: "全部", count: 3 },
    { name: "AI工具", count: 2 },
    { name: "SUNWIN", count: 1 },
  ]);
  assert.equal(filterAccounts(accounts, { category: "电商", query: "name@example.com" }).length, 1);
  assert.equal(filterAccounts(accounts, { category: "广告", query: "name@example.com" }).length, 0);
  assert.equal(filterAccounts(accounts, { category: "AI工具", query: "name@example.com" }).length, 1);
});

test("card fields hide empty rows and never copy secret values", () => {
  const shop = cardFields({
    username: "shop-user",
    email: "name@example.com",
    password: FAKE_PASSWORD,
    hasPassword: false,
  });
  assert.deepEqual(shop.map((row) => row.label), ["账号", "邮箱"]);
  assert.equal(copyTextForField(shop[1]), "name@example.com");
  assert.equal(JSON.stringify(shop).includes(FAKE_PASSWORD), false);

  const tool = cardFields({
    username: "name@example.com",
    email: "",
    hasPassword: true,
    password: FAKE_PASSWORD,
    apiKey: "test-api-key",
  });
  assert.deepEqual(tool.map((row) => row.label), ["账号/邮箱", "密码"]);
  assert.equal(tool[1].secret, true);
  assert.equal(tool[1].value, "");
  assert.equal(copyTextForField(tool[1]), "");
  assert.equal(tool[1].hint, "请在 Mac 应用中复制");
  assert.equal(JSON.stringify(tool).includes(FAKE_PASSWORD), false);
  assert.equal(JSON.stringify(tool).includes("test-api-key"), false);

  const ads = cardFields({
    username: "ads",
    loginURL: "https://example.com/login",
    hasApiKey: true,
    apiKey: "test-api-key",
  });
  assert.deepEqual(ads.map((row) => row.id), ["username", "apiKey", "loginURL"]);
  assert.equal(copyTextForField(ads.find((row) => row.id === "apiKey")), "");
  assert.equal(copyTextForField(ads.find((row) => row.id === "loginURL")), "https://example.com/login");

  const same = cardFields({ username: "Name@Example.com", email: "name@example.com" });
  assert.deepEqual(same.map((row) => row.label), ["账号/邮箱"]);
  assert.equal(copyTextForField(same[0]), "name@example.com");
});

test("optional email stays in metadata and older files still load", () => {
  const split = splitRecord({
    platform: "示例平台",
    username: "shop-user",
    email: "name@example.com",
    password: FAKE_PASSWORD,
  }, "2026-11-11T00:00:00Z");
  assert.equal(split.account.email, "name@example.com");
  assert.equal(split.account.username, "shop-user");
  assert.equal(split.patch.password, FAKE_PASSWORD);
  assert.equal(fileRecord(split.account).email, "name@example.com");
  assert.equal(JSON.stringify(fileRecord(split.account)).includes(FAKE_PASSWORD), false);
  const legacy = splitRecord({ platform: "示例平台", username: "name@example.com" }, "2026-11-11T00:00:00Z");
  assert.equal(legacy.account.email, "");
  assert.deepEqual(cardFields(legacy.account).map((row) => row.label), ["账号/邮箱"]);
  const csv = parseCSV("platform,账号,邮箱\n示例平台,shop-user,name@example.com\n");
  assert.equal(csv.errors.length, 0);
  assert.equal(csv.rows[0].account.username, "shop-user");
  assert.equal(csv.rows[0].account.email, "name@example.com");
  assert.equal(csv.rows[0].patch.password, undefined);
});

test("generator stays inside the requested classes and length", () => {
  let n = 0;
  const password = generatePassword({
    length: 16,
    avoidAmbiguous: true,
  }, () => (n += 17) % 256);
  assert.equal(password.length, 16);
  assert.match(password, /[abcdefghijkmnpqrstuvwxyz]/);
  assert.match(password, /[ABCDEFGHJKLMNPQRSTUVWXYZ]/);
  assert.match(password, /[23456789]/);
  assert.match(password, /[!@#$%^&*\-_=+?]/);
  assert.equal(/[0OolI1]/.test(password), false);
});

test("clipboard clear only happens when the same value is still there", () => {
  assert.equal(shouldClearClipboard({ copied: "abc", current: "abc", elapsedMs: CLIPBOARD_CLEAR_MS }), true);
  assert.equal(shouldClearClipboard({ copied: "abc", current: "abc", elapsedMs: CLIPBOARD_CLEAR_MS - 1 }), false);
  assert.equal(shouldClearClipboard({ copied: "abc", current: "其他内容", elapsedMs: CLIPBOARD_CLEAR_MS }), false);
  assert.equal(shouldClearClipboard({ copied: "", current: "", elapsedMs: CLIPBOARD_CLEAR_MS }), false);
});

test("redaction empties non-json and strips secret keys", () => {
  const redacted = JSON.parse(redactAssetJsonText(JSON.stringify({
    platform: "示例平台",
    password: FAKE_PASSWORD,
    secrets: { apiKey: "test-api-key" },
  })));
  assert.equal(redacted.platform, "示例平台");
  assert.equal(redacted.password, undefined);
  assert.equal(redacted.secrets, undefined);
  assert.equal(redactAssetJsonText("this is not json"), "");
});

test("file store never persists plaintext secrets", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "asset-vault-"));
  try {
    const planted = path.join(root, "电商");
    fs.mkdirSync(planted, { recursive: true });
    const id = "plantedid1";
    fs.writeFileSync(path.join(planted, `${id}.json`), JSON.stringify({
      id,
      platform: "手写条目",
      category: "电商",
      username: "name@example.com",
      password: FAKE_PASSWORD,
      updatedAt: "2026-11-11T00:00:00Z",
    }));
    const listed = listAccounts(root);
    assert.equal(listed.length, 1);
    assert.equal(JSON.stringify(listed).includes(FAKE_PASSWORD), false);
    const rewritten = fs.readFileSync(path.join(planted, `${id}.json`), "utf8");
    assert.equal(rewritten.includes(FAKE_PASSWORD), false);
    assert.equal(rewritten.includes("password"), false);

    const saved = saveAccount(root, {
      platform: "新平台",
      category: "../../逃逸",
      username: "other@example.com",
      password: FAKE_PASSWORD,
      loginURL: "https://user:pw@example.com/a",
    }, "2026-11-11T01:00:00Z");
    assert.equal(saved.secretsDropped, true);
    assert.equal(saved.account.hasSecret, false);
    assert.equal(saved.account.loginURL, "");
    assert.equal(saved.account.category.includes("/"), false);
    assert.equal(saved.account.category.includes(".."), false);
    const tree = walkText(root);
    assert.equal(tree.includes(FAKE_PASSWORD), false);
    assert.equal(fs.existsSync(path.join(path.dirname(root), "逃逸")), false);

    const imported = importCsv(root, `platform,password\n导入平台,${FAKE_PASSWORD}\n`);
    assert.equal(imported.imported, 1);
    assert.equal(imported.secretsDropped, 1);
    assert.equal(walkText(root).includes(FAKE_PASSWORD), false);

    assert.equal(deleteAccount(root, saved.account.id), true);
    assert.equal(listAccounts(root).some((item) => item.id === saved.account.id), false);
    assert.throws(() => saveAccount(root, { platform: "坏 id", id: "../x" }), /无效的条目 id/);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test("asset files served from the private tree are redacted", () => {
  const body = Buffer.from(JSON.stringify({ platform: "示例平台", password: FAKE_PASSWORD }));
  const redacted = redactPrivateAssetBody("资产管理/电商/a.json", ".json", body);
  assert.equal(redacted.status, 200);
  assert.equal(redacted.body.includes(FAKE_PASSWORD), false);
  assert.equal(redacted.body.includes("示例平台"), true);
  assert.equal(redactPrivateAssetBody("资产管理/note.txt", ".txt", Buffer.from("hello")).status, 404);
  assert.equal(redactPrivateAssetBody("客户档案/a.json", ".json", body), null);
});

test("built magichub bundle ships the card copy UI", () => {
  const dir = path.join(repoRoot, "超级工作台应用/app/magichub/assets");
  const files = fs.readdirSync(dir).filter((name) => name.endsWith(".js"));
  assert.equal(files.length, 1);
  const src = fs.readFileSync(path.join(dir, files[0]), "utf8");
  assert.match(src, /请在 Mac 应用中复制/);
  assert.match(src, /账号\/邮箱/);
  assert.equal(src.includes(FAKE_PASSWORD), false);
  assert.equal(src.includes("SUNWIN"), false);
  const html = fs.readFileSync(path.join(repoRoot, "超级工作台应用/app/magichub/index.html"), "utf8");
  assert.match(html, new RegExp(files[0].replace(/\./g, "\\.")));
});

test("private asset folder stays gitignored and bridges cannot bulk-read secrets", () => {
  const gitignore = fs.readFileSync(path.join(repoRoot, ".gitignore"), "utf8");
  assert.match(gitignore, /超级工作台应用\/data\/private\//);
  const bridge = fs.readFileSync(path.join(repoRoot, "超级工作台应用/mac-app/SuperWorkbench/Sources/SuperWorkbench/magichub-bridge.js"), "utf8");
  const swiftBridge = fs.readFileSync(path.join(repoRoot, "超级工作台应用/mac-app/SuperWorkbench/Sources/SuperWorkbench/MagicHubBridge.swift"), "utf8");
  for (const src of [bridge, swiftBridge]) {
    assert.match(src, /list-assets/);
    assert.doesNotMatch(src, /list-asset-secrets|get-asset-secret|dump-assets|asset-secrets/);
    assert.doesNotMatch(src, /\.load\(id:/);
  }
  const moduleSrc = fs.readFileSync(path.join(here, "asset-vault.mjs"), "utf8");
  assert.doesNotMatch(moduleSrc, /localStorage\s*\./);
  assert.doesNotMatch(moduleSrc, /sessionStorage/);
});

function walkText(root) {
  let all = "";
  for (const entry of fs.readdirSync(root, { recursive: true })) {
    const full = path.join(root, entry);
    if (fs.statSync(full).isFile()) all += fs.readFileSync(full, "utf8");
  }
  return all;
}
