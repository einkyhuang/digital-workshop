#!/usr/bin/env node
/**
 * Sync SmartPlan Hub website_projects ↔ workspace.json websiteProjects[]
 *
 * Import: prefer http://localhost:3300/api/websites, else read SQLite.
 * Push (--push): PUT updates to API when reachable; INSERT new rows via SQLite
 *   when API has no POST /api/websites. Never copies assets_credentials / API keys /
 *   client phone/wechat/email into workspace.json.
 *
 * Usage:
 *   node 超级工作台应用/scripts/sync-smartplan.mjs
 *   node 超级工作台应用/scripts/sync-smartplan.mjs --push
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { spawnSync } from "child_process";
import {
  loadPrivate,
  savePrivate,
  mergeFullWebsiteProjects,
  redactProjects,
  assertPublicClean,
  forSmartPlanWriteback,
  isAliasClientName,
} from "./website-privacy.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, "../..");
const WS = path.join(REPO, "超级工作台应用/data/workspace.json");
const WS_APP = path.join(REPO, "超级工作台应用/app/data/workspace.json");
const DB = path.join(REPO, "智能日程管理/server/smart_plan.db");
const API = process.env.SMARTPLAN_API || "http://localhost:3300";

const STRIP = new Set([
  "assets_credentials",
  "client_phone",
  "client_wechat",
  "client_email",
  "llm_api_key",
]);

function progressFromStatus(status) {
  switch (status) {
    case "delivered": return 100;
    case "in_progress": return 55;
    case "infrastructure": return 25;
    case "inactive": return 0;
    default: return 40;
  }
}

function sanitize(row) {
  const services = (() => {
    if (Array.isArray(row.services)) return row.services;
    if (typeof row.services === "string" && row.services.trim()) {
      try { const p = JSON.parse(row.services); return Array.isArray(p) ? p : []; }
      catch { return row.services.split(",").map(s => s.trim()).filter(Boolean); }
    }
    return [];
  })();
  return {
    id: row.id,
    name: row.name || "",
    category: row.category || "",
    status: row.status || "in_progress",
    localPath: row.local_path || row.localPath || "",
    url: row.url || "",
    framework: row.framework || "",
    description: row.description || "",
    clientName: row.client_name || row.clientName || "",
    clientCompany: row.client_company || row.clientCompany || "",
    totalAmount: Number(row.total_amount ?? row.totalAmount ?? 0) || 0,
    depositAmount: Number(row.deposit_amount ?? row.depositAmount ?? 0) || 0,
    paidAmount: Number(row.paid_amount ?? row.paidAmount ?? 0) || 0,
    unpaidAmount: Number(row.unpaid_amount ?? row.unpaidAmount ?? 0) || 0,
    paymentStatus: row.payment_status || row.paymentStatus || "pending",
    services,
    serviceStartDate: row.service_start_date || row.serviceStartDate || "",
    serviceEndDate: row.service_end_date || row.serviceEndDate || "",
    deadline: row.service_end_date || row.serviceEndDate || row.deadline || "",
    progress: row.progress != null ? Number(row.progress) : progressFromStatus(row.status),
    ownerBotId: row.ownerBotId || "",
    lastModified: row.last_modified || row.lastModified || "",
    createdAt: row.created_at || row.createdAt || "",
    updatedAt: row.updated_at || row.updatedAt || "",
    source: "smartplan",
    dirty: false,
  };
}

async function fetchApi() {
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 2500);
    const res = await fetch(`${API}/api/websites`, { signal: ctrl.signal });
    clearTimeout(t);
    if (!res.ok) return null;
    const json = await res.json();
    if (!json?.success || !Array.isArray(json.data)) return null;
    return json.data;
  } catch {
    return null;
  }
}

function fetchSqlite() {
  if (!fs.existsSync(DB)) return null;
  const sql = `SELECT id,name,category,status,local_path,url,framework,description,
    client_name,client_company,total_amount,deposit_amount,paid_amount,unpaid_amount,
    payment_status,services,service_start_date,service_end_date,last_modified,created_at,updated_at
    FROM website_projects ORDER BY updated_at DESC;`;
  const r = spawnSync("sqlite3", ["-json", DB, sql], { encoding: "utf8", maxBuffer: 20 * 1024 * 1024 });
  if (r.status !== 0) {
    console.error("sqlite3 failed:", r.stderr);
    return null;
  }
  try { return JSON.parse(r.stdout || "[]"); } catch { return null; }
}

async function putApi(id, body) {
  const res = await fetch(`${API}/api/websites/${id}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok || json.success === false) throw new Error(json.error || `PUT ${res.status}`);
  return json.data;
}

function insertSqlite(item) {
  const safe = forSmartPlanWriteback(item);
  const services = JSON.stringify(safe.services || []);
  const cat = safe.category || (safe.status === "delivered" ? "已交付" : safe.status === "inactive" ? "已暂停/挂了" : safe.status === "infrastructure" ? "功能基础建设" : "进行中");
  const clientName = (safe.clientName != null && !isAliasClientName(safe.clientName)) ? safe.clientName : "";
  const clientCompany = (safe.clientCompany && String(safe.clientCompany).trim() !== "已隐藏") ? safe.clientCompany : "";
  const localPath = safe.localPath || "";
  const sql = `INSERT INTO website_projects (
    id,name,category,status,local_path,url,framework,description,last_modified,
    client_name,client_phone,client_wechat,client_email,client_company,
    total_amount,deposit_amount,paid_amount,unpaid_amount,payment_status,
    assets_credentials,services,service_start_date,service_end_date,created_at,updated_at
  ) VALUES (
    '${esc(safe.id)}','${esc(safe.name)}','${esc(cat)}','${esc(safe.status)}',
    '${esc(localPath)}',
    '${esc(safe.url)}','${esc(safe.framework || "React")}','${esc(safe.description)}',
    datetime('now','localtime'),
    '${esc(clientName)}','','','','${esc(clientCompany)}',
    ${Number(safe.totalAmount)||0},${Number(safe.depositAmount)||0},${Number(safe.paidAmount)||0},${Number(safe.unpaidAmount)||0},
    '${esc(safe.paymentStatus||"pending")}','','${esc(services)}',
    '${esc(safe.serviceStartDate||"")}','${esc(safe.deadline||safe.serviceEndDate||"")}',
    datetime('now'),datetime('now')
  );`;
  const r = spawnSync("sqlite3", [DB, sql], { encoding: "utf8" });
  if (r.status !== 0) throw new Error(r.stderr || "sqlite insert failed");
}

function esc(s) {
  return String(s ?? "").replace(/'/g, "''");
}

function toApiBody(item) {
  // Never push redacted aliases / hidden placeholders back into SmartPlan
  const safe = forSmartPlanWriteback(item);
  const body = {
    name: safe.name,
    url: safe.url,
    category: safe.category,
    status: safe.status,
    description: safe.description,
    framework: safe.framework,
    // intentionally omit phone/wechat/email/credentials
    payment_status: safe.paymentStatus,
    services: safe.services,
    service_start_date: safe.serviceStartDate,
    service_end_date: safe.deadline || safe.serviceEndDate,
  };
  if (safe.clientName != null && !isAliasClientName(safe.clientName)) body.client_name = safe.clientName;
  if (safe.clientCompany != null && String(safe.clientCompany).trim() && String(safe.clientCompany).trim() !== "已隐藏") {
    body.client_company = safe.clientCompany;
  }
  if (safe.totalAmount != null) body.total_amount = safe.totalAmount;
  if (safe.depositAmount != null) body.deposit_amount = safe.depositAmount;
  if (safe.paidAmount != null) body.paid_amount = safe.paidAmount;
  if (safe.unpaidAmount != null) body.unpaid_amount = safe.unpaidAmount;
  return body;
}

function loadWs() {
  return JSON.parse(fs.readFileSync(WS, "utf8"));
}
function saveWs(data) {
  data.updatedAt = new Date().toISOString();
  const text = JSON.stringify(data, null, 2) + "\n";
  fs.writeFileSync(WS, text);
  fs.mkdirSync(path.dirname(WS_APP), { recursive: true });
  fs.writeFileSync(WS_APP, text);
}

async function main() {
  const doPush = process.argv.includes("--push");
  const ws = loadWs();
  const local = Array.isArray(ws.websiteProjects) ? ws.websiteProjects : [];
  const localById = new Map(local.map((x) => [x.id, x]));

  let source = "api";
  let remote = await fetchApi();
  if (!remote) {
    source = "sqlite";
    remote = fetchSqlite();
  }
  if (!remote) {
    console.error("无法从 API 或 SQLite 读取 website_projects");
    process.exit(1);
  }

  const notes = [];
  notes.push(`导入来源: ${source}（${remote.length} 条）`);

  // Push dirty local edits first (so import doesn't overwrite pending)
  let pushed = 0, created = 0, pushErrors = [];
  if (doPush) {
    const apiUp = !!(await fetchApi());
    for (const item of local) {
      if (!item.dirty && !item.localOnly) continue;
      try {
        if (item.localOnly) {
          insertSqlite(item);
          item.localOnly = false;
          item.source = "smartplan";
          created++;
        } else if (apiUp) {
          await putApi(item.id, toApiBody(item));
          pushed++;
        } else {
          // one-way note
          pushErrors.push(`${item.name}: API 不可用，跳过写回`);
        }
        item.dirty = false;
      } catch (e) {
        pushErrors.push(`${item.name}: ${e.message}`);
      }
    }
    notes.push(`写回: PUT ${pushed} · 新建 ${created}` + (pushErrors.length ? ` · 失败 ${pushErrors.length}` : ""));
    if (!apiUp && local.some((x) => x.dirty)) notes.push("注意: SmartPlan API 未启动时仅能 SQLite 新建；已有记录的状态改动需 API PUT（或下次 API 可用时 --push）");
  }

  // Re-read after push
  remote = (await fetchApi()) || fetchSqlite() || remote;
  source = (await fetchApi()) ? "api" : "sqlite";

  const merged = remote.map((row) => {
    const clean = sanitize(row);
    const prev = localById.get(clean.id);
    if (prev) {
      // preserve workbench-only fields
      if (prev.ownerBotId) clean.ownerBotId = prev.ownerBotId;
      if (prev.progress != null && prev.dirty) clean.progress = prev.progress;
      else if (prev.progress != null && prev.progress !== progressFromStatus(prev.status)) clean.progress = prev.progress;
      if (prev.dirty) {
        // keep local pending edits over remote
        return { ...clean, ...pickEditable(prev), dirty: false, source: clean.source };
      }
    }
    return clean;
  });

  // keep localOnly drafts not yet in remote
  for (const item of local) {
    if (item.localOnly && !merged.find((m) => m.id === item.id)) merged.unshift(item);
  }

  ws.websiteProjects = merged;
  ws.smartplanSync = {
    lastSyncAt: new Date().toISOString(),
    source,
    count: merged.length,
    direction: doPush ? "bidirectional-when-api-up" : "import",
    note: "不导入 assets_credentials / 客户电话微信邮箱 / settings.llm_api_key。编辑写回依赖 PUT /api/websites/:id；新建无 POST 时走 SQLite INSERT。公开仓库中的 websiteProjects 已脱敏；完整数据仅存 data/private/。",
    messages: notes.concat(pushErrors),
  };
  // Keep prior aliases stable across sync
  saveWs(ws, { aliases: aliasSeed });
  console.log(JSON.stringify({ ok: true, count: merged.length, source, pushed, created, notes, pushErrors }, null, 2));
}

function pickEditable(prev) {
  return {
    name: prev.name,
    category: prev.category,
    status: prev.status,
    url: prev.url,
    framework: prev.framework,
    description: prev.description,
    clientName: prev.clientName,
    clientCompany: prev.clientCompany,
    totalAmount: prev.totalAmount,
    depositAmount: prev.depositAmount,
    paidAmount: prev.paidAmount,
    unpaidAmount: prev.unpaidAmount,
    paymentStatus: prev.paymentStatus,
    services: prev.services,
    serviceStartDate: prev.serviceStartDate,
    serviceEndDate: prev.serviceEndDate,
    deadline: prev.deadline,
    progress: prev.progress,
    ownerBotId: prev.ownerBotId,
  };
}

main().catch((e) => { console.error(e); process.exit(1); });
