/**
 * Website project privacy: full data ↔ redacted public workspace.json
 *
 * Private SoT: 超级工作台应用/data/private/websiteProjects.local.json (gitignored)
 * Public: websiteProjects[] in workspace.json with client aliases, amounts cleared, localPath stripped.
 * Writeback to SmartPlan must NEVER use redacted placeholders.
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const REPO = path.resolve(__dirname, "../..");
export const PRIVATE_DIR = path.join(REPO, "超级工作台应用/data/private");
export const PRIVATE_FILE = path.join(PRIVATE_DIR, "websiteProjects.local.json");
export const PRIVATE_APP_DIR = path.join(REPO, "超级工作台应用/app/data/private");
export const PRIVATE_APP_FILE = path.join(PRIVATE_APP_DIR, "websiteProjects.local.json");

const SENSITIVE_AMOUNT_KEYS = ["totalAmount", "depositAmount", "paidAmount", "unpaidAmount"];
const ALIAS_RE = /^客户[A-Z]\d{2,}$/;
const HIDDEN = "已隐藏";

export function isAliasClientName(name) {
  const s = String(name || "").trim();
  return !s || s === HIDDEN || ALIAS_RE.test(s);
}

export function isRedactedPlaceholder(project) {
  if (!project) return true;
  const cn = String(project.clientName || "").trim();
  if (cn && (cn === HIDDEN || ALIAS_RE.test(cn))) return true;
  const cc = String(project.clientCompany || "").trim();
  if (cc === HIDDEN) return true;
  // amounts all null/undefined/0 and no real client — ambiguous; treat alias-only as redacted
  return false;
}

export function looksUnredacted(project) {
  if (!project || typeof project !== "object") return false;
  const cn = String(project.clientName || "").trim();
  if (cn && !isAliasClientName(cn)) return true;
  const cc = String(project.clientCompany || "").trim();
  if (cc && cc !== HIDDEN) return true;
  const lp = String(project.localPath || "");
  if (lp.startsWith("/") || lp.startsWith("~") || lp.includes("/Users/") || lp.includes("/Library/")) return true;
  for (const k of SENSITIVE_AMOUNT_KEYS) {
    const v = project[k];
    if (v != null && Number(v) > 0) return true;
  }
  return false;
}

function nextAlias(aliases) {
  let max = 0;
  for (const a of Object.values(aliases || {})) {
    const m = String(a).match(/^客户([A-Z])(\d+)$/);
    if (m) {
      const n = parseInt(m[2], 10);
      if (n > max) max = n;
    }
  }
  const n = max + 1;
  return `客户A${String(n).padStart(2, "0")}`;
}

export function ensureAliases(projects, aliases = {}) {
  const out = { ...aliases };
  for (const p of projects || []) {
    if (!p?.id) continue;
    if (out[p.id]) continue;
    const cn = String(p.clientName || "").trim();
    const cc = String(p.clientCompany || "").trim();
    // Always assign stable alias per id (even if currently empty) so future fills stay stable
    if (cn || cc || looksUnredacted(p)) {
      out[p.id] = nextAlias(out);
    }
  }
  return out;
}

export function redactProject(project, aliases = {}) {
  if (!project || typeof project !== "object") return project;
  const alias = aliases[project.id] || (String(project.clientName || "").trim() ? HIDDEN : "");
  const hasClient = Boolean(String(project.clientName || "").trim() || String(project.clientCompany || "").trim() || aliases[project.id]);
  const out = { ...project };
  out.clientName = hasClient ? (aliases[project.id] || alias || HIDDEN) : "";
  out.clientCompany = String(project.clientCompany || "").trim() ? HIDDEN : "";
  out.localPath = "";
  for (const k of SENSITIVE_AMOUNT_KEYS) {
    out[k] = null;
  }
  // keep paymentStatus as coarse signal (no amount); optional — leave as-is
  return out;
}

export function redactProjects(projects, aliases = {}) {
  const als = ensureAliases(projects, aliases);
  return {
    aliases: als,
    projects: (projects || []).map((p) => redactProject(p, als)),
  };
}

export function loadPrivate() {
  if (!fs.existsSync(PRIVATE_FILE)) return null;
  try {
    const raw = JSON.parse(fs.readFileSync(PRIVATE_FILE, "utf8"));
    if (!raw || !Array.isArray(raw.projects)) return null;
    return raw;
  } catch {
    return null;
  }
}

export function savePrivate(projects, aliases = {}) {
  fs.mkdirSync(PRIVATE_DIR, { recursive: true });
  const als = ensureAliases(projects, aliases);
  const payload = {
    version: 1,
    updatedAt: new Date().toISOString(),
    note: "LOCAL ONLY — gitignored. Full websiteProjects (client/amounts/localPath). Do not commit.",
    aliases: als,
    projects,
  };
  fs.writeFileSync(PRIVATE_FILE, JSON.stringify(payload, null, 2) + "\n", "utf8");
  // Local web overlay (also gitignored)
  try {
    fs.mkdirSync(PRIVATE_APP_DIR, { recursive: true });
    fs.writeFileSync(PRIVATE_APP_FILE, JSON.stringify(payload, null, 2) + "\n", "utf8");
  } catch (_) {}
  return payload;
}

/** Merge: prefer private full projects by id; fall back to public list. */
export function mergeFullWebsiteProjects(publicList, privateDoc) {
  if (!privateDoc?.projects?.length) return publicList || [];
  const byId = new Map((publicList || []).map((p) => [p.id, p]));
  for (const p of privateDoc.projects) {
    if (p?.id) byId.set(p.id, p);
  }
  // preserve public order when possible
  const ordered = [];
  const seen = new Set();
  for (const p of publicList || []) {
    if (p?.id && byId.has(p.id)) {
      ordered.push(byId.get(p.id));
      seen.add(p.id);
    }
  }
  for (const p of privateDoc.projects) {
    if (p?.id && !seen.has(p.id)) ordered.push(p);
  }
  return ordered;
}

/** Strip redacted placeholders before SmartPlan writeback — return null fields instead of aliases. */
export function forSmartPlanWriteback(project) {
  if (!project) return project;
  const out = { ...project };
  if (isAliasClientName(out.clientName) && String(out.clientName || "").trim()) {
    // Do not push alias/hidden back
    delete out.clientName;
    delete out.client_name;
  }
  if (String(out.clientCompany || "").trim() === HIDDEN) {
    delete out.clientCompany;
    delete out.client_company;
  }
  if (!out.localPath) {
    delete out.localPath;
    delete out.local_path;
  }
  for (const k of SENSITIVE_AMOUNT_KEYS) {
    if (out[k] == null) {
      delete out[k];
    }
  }
  return out;
}

export function assertPublicClean(projects, label = "workspace.json") {
  const bad = [];
  for (const p of projects || []) {
    if (looksUnredacted(p)) {
      bad.push(p.id || p.name || "?");
    }
  }
  if (bad.length) {
    throw new Error(`[privacy] ${label} still has unredacted website project fields: ${bad.slice(0, 8).join(", ")}${bad.length > 8 ? "…" : ""}`);
  }
}
