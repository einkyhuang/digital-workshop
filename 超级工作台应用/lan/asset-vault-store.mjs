/**
 * 局域网 / 浏览器侧的资产管理文件库。
 * 只写元数据。任何密码、密钥、恢复码都会从文件里删掉，并且不会另存。
 */
import fs from "fs";
import path from "path";
import {
  containsSecretKey,
  fileRecord,
  filterAccounts,
  isValidId,
  isoNow,
  parseCSV,
  patchHasValue,
  publicAccount,
  safeCategory,
  splitRecord,
  stripSecretKeys,
} from "../app/assets/asset-vault.mjs";

export function assetRoot(privateRoot) {
  return path.join(privateRoot, "资产管理");
}

function insideRoot(rootReal, candidate) {
  const real = fs.realpathSync(candidate);
  return real === rootReal || real.startsWith(rootReal + path.sep);
}

function walkJson(root) {
  if (!fs.existsSync(root)) return [];
  const rootReal = fs.realpathSync(root);
  const found = [];
  const stack = [rootReal];
  while (stack.length) {
    const dir = stack.pop();
    let entries = [];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const entry of entries) {
      if (entry.name.startsWith(".")) continue;
      const full = path.join(dir, entry.name);
      let real;
      try {
        real = fs.realpathSync(full);
      } catch {
        continue;
      }
      if (!(real === rootReal || real.startsWith(rootReal + path.sep))) continue;
      let stat;
      try {
        stat = fs.statSync(real);
      } catch {
        continue;
      }
      if (stat.isDirectory()) stack.push(real);
      else if (stat.isFile() && entry.name.endsWith(".json")) found.push(real);
    }
  }
  return found;
}

function readScrubbed(file) {
  let text;
  try {
    text = fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    return null;
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return null;
  if (containsSecretKey(parsed)) {
    const stripped = stripSecretKeys(parsed);
    const tmp = `${file}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(stripped, null, 2));
    fs.renameSync(tmp, file);
    return stripped;
  }
  return parsed;
}

function destination(root, account) {
  if (!isValidId(account.id)) {
    const error = new Error("无效的条目 id");
    error.code = "invalid-id";
    throw error;
  }
  fs.mkdirSync(root, { recursive: true });
  const category = safeCategory(account.category);
  const dir = path.join(root, category);
  fs.mkdirSync(dir, { recursive: true });
  const rootReal = fs.realpathSync(root);
  if (!insideRoot(rootReal, dir)) {
    const error = new Error("路径越界");
    error.code = "path-escape";
    throw error;
  }
  const dest = path.join(fs.realpathSync(dir), `${account.id}.json`);
  const dirReal = fs.realpathSync(dir);
  if (!dest.startsWith(dirReal + path.sep)) {
    const error = new Error("路径越界");
    error.code = "path-escape";
    throw error;
  }
  return { dest, rootReal };
}

function removeOtherCopies(rootReal, id, keep) {
  for (const file of walkJson(rootReal)) {
    if (path.basename(file, ".json") === id && file !== keep) {
      try { fs.unlinkSync(file); } catch { /* ignore */ }
    }
  }
}

export function listAccounts(root) {
  const accounts = [];
  for (const file of walkJson(root)) {
    const obj = readScrubbed(file);
    if (!obj) continue;
    try {
      const parent = path.basename(path.dirname(file));
      if (!String(obj.category || "").trim() && parent !== path.basename(root)) obj.category = parent;
      const { account } = splitRecord(obj, obj.updatedAt || isoNow());
      const idFromName = path.basename(file, ".json");
      if (!account.id) account.id = idFromName;
      if (!isValidId(account.id) || account.id !== idFromName) continue;
      accounts.push(publicAccount(account, false));
    } catch {
      continue;
    }
  }
  accounts.sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)));
  return accounts;
}

export function saveAccount(root, input, now = isoNow()) {
  const { account, patch } = splitRecord(input, now);
  const secretsDropped = patchHasValue(patch);
  const stored = { ...account, id: account.id || crypto.randomUUID(), updatedAt: isoNow(new Date(now)) };
  const record = fileRecord(stored);
  if (containsSecretKey(record)) {
    const error = new Error("拒绝把密钥写入文件");
    error.code = "secret-leak";
    throw error;
  }
  const { dest, rootReal } = destination(root, stored);
  const tmp = `${dest}.tmp`;
  fs.writeFileSync(tmp, `${JSON.stringify(record, null, 2)}\n`);
  fs.renameSync(tmp, dest);
  removeOtherCopies(rootReal, stored.id, dest);
  return { account: publicAccount(stored, false), secretsDropped };
}

export function deleteAccount(root, id) {
  if (!isValidId(String(id || ""))) {
    const error = new Error("无效的条目 id");
    error.code = "invalid-id";
    throw error;
  }
  if (!fs.existsSync(root)) return false;
  const rootReal = fs.realpathSync(root);
  let removed = false;
  for (const file of walkJson(rootReal)) {
    if (path.basename(file, ".json") !== id) continue;
    if (!insideRoot(rootReal, file)) continue;
    fs.unlinkSync(file);
    removed = true;
  }
  return removed;
}

export function importCsv(root, csv, now = isoNow()) {
  const { rows, errors } = parseCSV(csv);
  let imported = 0;
  let secretsDropped = 0;
  for (const row of rows) {
    if (patchHasValue(row.patch)) secretsDropped += 1;
    try {
      saveAccount(root, row.account, now);
      imported += 1;
    } catch {
      errors.push("有一行没有写入");
    }
  }
  return { imported, skipped: errors.length, secretsDropped, errors };
}

export function searchAccounts(root, query, category) {
  return filterAccounts(listAccounts(root), { query, category });
}
