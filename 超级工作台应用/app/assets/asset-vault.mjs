/**
 * 资产管理：纯函数。密码等密钥只作为“拆出来的补丁”返回，调用方不得写回 JSON、
 * localStorage 或网页包。Mac 应用把补丁放进钥匙串；局域网服务直接丢弃。
 * 与 Swift `AssetVaultCore` 对齐，改动时两边的测试一起改。
 */

export const CATEGORIES = ["电商", "社交", "广告", "主机", "域名", "邮箱", "支付", "其他"];

export const TWO_FACTOR_OPTIONS = [
  { id: "none", label: "无" },
  { id: "totp", label: "验证器 App" },
  { id: "sms", label: "短信" },
  { id: "email", label: "邮箱" },
  { id: "hardware", label: "硬件密钥" },
  { id: "other", label: "其他" },
];

export const PUBLIC_FIELDS = [
  "id", "platform", "category", "loginURL", "username", "notes",
  "twoFactor", "tags", "company", "brand", "updatedAt",
];

export const SECRET_FIELDS = ["password", "apiKey", "recoveryCodes", "totpSecret", "extra"];

export const CLIPBOARD_CLEAR_MS = 45_000;
export const CSV_MAX_CHARS = 512_000;
export const CSV_MAX_ROWS = 1000;

const HEADER_MAP = {
  platform: "platform",
  name: "platform",
  平台: "platform",
  平台名称: "platform",
  category: "category",
  分类: "category",
  loginurl: "loginURL",
  url: "loginURL",
  登录地址: "loginURL",
  登录网址: "loginURL",
  网址: "loginURL",
  username: "username",
  user: "username",
  email: "username",
  用户名: "username",
  账号: "username",
  邮箱: "username",
  password: "password",
  passwd: "password",
  pwd: "password",
  密码: "password",
  notes: "notes",
  note: "notes",
  备注: "notes",
  twofactor: "twoFactor",
  "2fa": "twoFactor",
  二次验证: "twoFactor",
  双重验证: "twoFactor",
  tags: "tags",
  标签: "tags",
  company: "company",
  公司: "company",
  关联公司: "company",
  brand: "brand",
  品牌: "brand",
  apikey: "apiKey",
  密钥: "apiKey",
  api密钥: "apiKey",
  recoverycodes: "recoveryCodes",
  recovery: "recoveryCodes",
  恢复码: "recoveryCodes",
  totpsecret: "totpSecret",
  totp: "totpSecret",
  otpsecret: "totpSecret",
  验证器密钥: "totpSecret",
  token: "extra",
  accesstoken: "extra",
  secret: "extra",
  id: "id",
};

const TWO_FACTOR_MAP = {
  "": "none",
  none: "none",
  无: "none",
  没有: "none",
  totp: "totp",
  app: "totp",
  authenticator: "totp",
  验证器: "totp",
  验证器app: "totp",
  sms: "sms",
  短信: "sms",
  email: "email",
  邮箱: "email",
  hardware: "hardware",
  硬件: "hardware",
  硬件密钥: "hardware",
  other: "other",
  其他: "other",
};

const NAMED_SECRET = new Set([
  "password", "passwd", "pwd", "apikey", "recoverycodes", "recovery",
  "totpsecret", "totp", "otpsecret",
]);

const GENERIC_SECRET = new Set(["secret", "token", "accesstoken"]);

export function compactKey(key) {
  return String(key || "").replace(/[\s_-]/g, "").toLowerCase();
}

export function isSecretKey(key) {
  if (key === "secrets") return true;
  const k = compactKey(key);
  return NAMED_SECRET.has(k) || GENERIC_SECRET.has(k);
}

export function canonicalSecret(key) {
  const mapped = HEADER_MAP[compactKey(key)] || HEADER_MAP[String(key || "").trim()];
  if (SECRET_FIELDS.includes(mapped)) return mapped;
  const k = compactKey(key);
  if (NAMED_SECRET.has(k) || GENERIC_SECRET.has(k)) {
    if (k === "password" || k === "passwd" || k === "pwd") return "password";
    if (k === "apikey") return "apiKey";
    if (k === "recoverycodes" || k === "recovery") return "recoveryCodes";
    if (k === "totpsecret" || k === "totp" || k === "otpsecret") return "totpSecret";
    return "extra";
  }
  return null;
}

export function safeCategory(raw) {
  const cleaned = String(raw || "").trim().replace(/[/\\\0]/g, "").replace(/^\.+/, "");
  const clipped = [...cleaned].slice(0, 32).join("");
  if (!clipped || clipped === "." || clipped === "..") return "其他";
  return clipped;
}

export function safeLoginURL(raw) {
  const text = String(raw || "").trim();
  if (!text) return "";
  let url;
  try {
    url = new URL(text);
  } catch {
    return "";
  }
  if (url.username || url.password) return "";
  if (url.protocol !== "http:" && url.protocol !== "https:") return "";
  return url.toString();
}

export function isValidId(id) {
  return /^[A-Za-z0-9][A-Za-z0-9_-]{0,80}$/.test(id);
}

export function isoNow(date = new Date()) {
  const value = date instanceof Date ? date : new Date(date);
  const safe = Number.isNaN(value.getTime()) ? new Date() : value;
  return safe.toISOString().replace(/\.\d{3}Z$/, "Z");
}

function clip(value, max) {
  return [...String(value ?? "")].slice(0, max).join("");
}

export function normalizeTwoFactor(raw) {
  const key = compactKey(raw);
  return TWO_FACTOR_MAP[key] || TWO_FACTOR_MAP[String(raw || "").trim()] || "none";
}

export function normalizeTags(raw) {
  const parts = Array.isArray(raw) ? raw : String(raw || "").split(/[,，;；|]/);
  const out = [];
  for (const part of parts) {
    const tag = clip(String(part).trim(), 32);
    if (!tag || out.includes(tag)) continue;
    out.push(tag);
    if (out.length >= 20) break;
  }
  return out;
}

export function normalizeAccount(meta, now = isoNow()) {
  const platform = clip(meta.platform, 120).trim();
  if (!platform) {
    const error = new Error("缺少平台名称");
    error.code = "invalid-platform";
    throw error;
  }
  const id = String(meta.id || "").trim();
  if (id && !isValidId(id)) {
    const error = new Error("无效的条目 id");
    error.code = "invalid-id";
    throw error;
  }
  return {
    id,
    platform,
    category: safeCategory(meta.category),
    loginURL: safeLoginURL(meta.loginURL),
    username: clip(meta.username, 200).trim(),
    notes: clip(meta.notes, 8000),
    twoFactor: normalizeTwoFactor(meta.twoFactor),
    tags: normalizeTags(meta.tags),
    company: clip(meta.company, 120).trim(),
    brand: clip(meta.brand, 120).trim(),
    updatedAt: isoNow(new Date(now)),
  };
}

function emptyPatch() {
  return {};
}

function absorbSecret(patch, canon, value) {
  const text = value == null ? "" : String(value);
  if (!Object.prototype.hasOwnProperty.call(patch, canon) || patch[canon] === "") {
    patch[canon] = text;
    return;
  }
  if (text) patch[canon] = `${patch[canon]}\n${text}`;
}

function walkSecrets(patch, obj) {
  if (!obj || typeof obj !== "object" || Array.isArray(obj)) return;
  for (const [key, value] of Object.entries(obj)) {
    if (key === "secrets" && value && typeof value === "object") {
      walkSecrets(patch, value);
      continue;
    }
    const canon = canonicalSecret(key);
    if (canon) {
      absorbSecret(patch, canon, value);
      continue;
    }
  }
}

export function splitRecord(input, now = isoNow()) {
  const src = input && typeof input === "object" && !Array.isArray(input) ? input : {};
  const patch = emptyPatch();
  const meta = {};
  for (const [key, value] of Object.entries(src)) {
    if (key === "secrets" && value && typeof value === "object") {
      walkSecrets(patch, value);
      continue;
    }
    const canon = canonicalSecret(key);
    if (canon) {
      absorbSecret(patch, canon, value);
      continue;
    }
    if (key === "hasSecret") continue;
    meta[key] = value;
  }
  return { account: normalizeAccount(meta, now), patch };
}

export function patchHasValue(patch) {
  return SECRET_FIELDS.some((key) => typeof patch?.[key] === "string" && patch[key].length > 0);
}

export function emptySecrets() {
  return { password: "", apiKey: "", recoveryCodes: "", totpSecret: "", extra: "" };
}

export function applySecretPatch(existing, patch) {
  const next = { ...emptySecrets(), ...(existing || {}) };
  for (const key of SECRET_FIELDS) {
    if (Object.prototype.hasOwnProperty.call(patch || {}, key)) next[key] = patch[key] || "";
  }
  return next;
}

export function secretsAreEmpty(secrets) {
  return SECRET_FIELDS.every((key) => !secrets || !secrets[key]);
}

export function fileRecord(account) {
  const out = {};
  for (const key of PUBLIC_FIELDS) {
    if (key === "updatedAt") out[key] = account.updatedAt || "";
    else if (account[key] !== undefined) out[key] = account[key];
  }
  delete out.hasSecret;
  return out;
}

export function publicAccount(account, hasSecret = false) {
  return { ...fileRecord(account), hasSecret: Boolean(hasSecret) };
}

export function containsSecretKey(value) {
  if (Array.isArray(value)) return value.some(containsSecretKey);
  if (!value || typeof value !== "object") return false;
  return Object.entries(value).some(([key, child]) => {
    if (key === "secrets" || canonicalSecret(key)) return true;
    return containsSecretKey(child);
  });
}

export function stripSecretKeys(value) {
  if (Array.isArray(value)) return value.map(stripSecretKeys);
  if (!value || typeof value !== "object") return value;
  const out = {};
  for (const [key, child] of Object.entries(value)) {
    if (key === "secrets" || canonicalSecret(key)) continue;
    out[key] = child && typeof child === "object" ? stripSecretKeys(child) : child;
  }
  return out;
}

export function redactAssetJsonText(text) {
  try {
    const parsed = JSON.parse(String(text || ""));
    return JSON.stringify(stripSecretKeys(parsed), null, 2);
  } catch {
    return "";
  }
}

export function isAssetVaultPath(filePath) {
  return String(filePath || "").split(/[/\\]/).includes("资产管理");
}

export function filterAccounts(accounts, { query = "", category = "" } = {}) {
  const needle = String(query || "").trim().toLowerCase();
  const cat = String(category || "").trim();
  return (accounts || []).filter((account) => {
    if (cat && cat !== "全部" && account.category !== cat) return false;
    if (!needle) return true;
    const hay = [
      account.platform, account.category, account.loginURL, account.username,
      account.notes, account.company, account.brand, ...(account.tags || []),
    ].join("\n").toLowerCase();
    return hay.includes(needle);
  });
}

function parseRecords(text) {
  const records = [];
  let row = [];
  let cell = "";
  let quoted = false;
  const src = String(text || "").replace(/^\uFEFF/, "");
  for (let i = 0; i < src.length; i++) {
    const ch = src[i];
    if (quoted) {
      if (ch === '"') {
        if (src[i + 1] === '"') {
          cell += '"';
          i += 1;
        } else {
          quoted = false;
        }
      } else {
        cell += ch;
      }
      continue;
    }
    if (ch === '"') {
      quoted = true;
      continue;
    }
    if (ch === ",") {
      row.push(cell);
      cell = "";
      continue;
    }
    if (ch === "\n" || ch === "\r") {
      if (ch === "\r" && src[i + 1] === "\n") i += 1;
      row.push(cell);
      records.push(row);
      row = [];
      cell = "";
      continue;
    }
    cell += ch;
  }
  if (cell.length || row.length) {
    row.push(cell);
    records.push(row);
  }
  return records.filter((record, index) => record.some((item) => String(item).trim()) || index === 0);
}

function headerName(cell) {
  const raw = String(cell || "").trim();
  return HEADER_MAP[compactKey(raw)] || HEADER_MAP[raw] || "";
}

export function parseCSV(text) {
  const src = String(text || "");
  if (src.length > CSV_MAX_CHARS) return { rows: [], errors: ["csv 过大"] };
  const records = parseRecords(src);
  if (!records.length) return { rows: [], errors: ["csv 是空的"] };
  const header = records[0].map(headerName);
  if (!header.includes("platform")) return { rows: [], errors: ["csv 需要平台列"] };
  const rows = [];
  const errors = [];
  for (let i = 1; i < records.length; i++) {
    if (rows.length >= CSV_MAX_ROWS) {
      errors.push("超过 1000 行，其余已忽略");
      break;
    }
    const cells = records[i];
    if (cells.every((cell) => !String(cell).trim())) continue;
    const obj = {};
    header.forEach((key, index) => {
      if (!key) return;
      obj[key] = cells[index] ?? "";
    });
    try {
      rows.push(splitRecord(obj));
    } catch (error) {
      errors.push(`第 ${i + 1} 行：${error.code === "invalid-id" ? "无效的条目 id" : "缺少平台名称"}`);
    }
  }
  return { rows, errors };
}

function randomIndex(modulo, randomByte) {
  if (modulo <= 1) return 0;
  const max = Math.floor(256 / modulo) * modulo;
  let guard = 0;
  let value = randomByte();
  while (value >= max && guard < 32) {
    value = randomByte();
    guard += 1;
  }
  return value % modulo;
}

function defaultRandomByte() {
  const bytes = new Uint8Array(1);
  const cryptoObj = globalThis.crypto;
  if (!cryptoObj?.getRandomValues) throw new Error("缺少安全随机数");
  cryptoObj.getRandomValues(bytes);
  return bytes[0];
}

export function generatePassword(options = {}, randomByte = defaultRandomByte) {
  const length = Math.min(128, Math.max(8, Number(options.length) || 20));
  const avoid = options.avoidAmbiguous !== false;
  const classes = [];
  if (options.lower !== false) classes.push(avoid ? "abcdefghijkmnpqrstuvwxyz" : "abcdefghijklmnopqrstuvwxyz");
  if (options.upper !== false) classes.push(avoid ? "ABCDEFGHJKLMNPQRSTUVWXYZ" : "ABCDEFGHIJKLMNOPQRSTUVWXYZ");
  if (options.digits !== false) classes.push(avoid ? "23456789" : "0123456789");
  if (options.symbols !== false) classes.push("!@#$%^&*-_=+?");
  if (!classes.length) throw new Error("至少选择一类字符");
  const pool = classes.join("");
  const chars = [];
  for (let i = 0; i < length; i++) chars.push(pool[randomIndex(pool.length, randomByte)]);
  classes.forEach((set, index) => {
    if (!chars.some((ch) => set.includes(ch))) {
      chars[index % chars.length] = set[randomIndex(set.length, randomByte)];
    }
  });
  for (let i = chars.length - 1; i > 0; i--) {
    const j = randomIndex(i + 1, randomByte);
    const tmp = chars[i];
    chars[i] = chars[j];
    chars[j] = tmp;
  }
  return chars.join("");
}

export function shouldClearClipboard({ copied, current, elapsedMs, limitMs = CLIPBOARD_CLEAR_MS }) {
  if (!copied) return false;
  if (typeof current !== "string" || current !== copied) return false;
  return Number(elapsedMs) >= Number(limitMs);
}
