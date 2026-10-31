/**
 * Shared Application Support models.json for Electron + LAN server.
 * Path: ~/Library/Application Support/超级工作台/models.json (darwin)
 *       ~/.local/share/超级工作台/models.json (linux fallback)
 * Keys may live in this file (outside git). Never commit this path.
 */
const fs = require("fs");
const path = require("path");
const os = require("os");

function supportDir() {
  if (process.platform === "darwin") {
    return path.join(os.homedir(), "Library", "Application Support", "超级工作台");
  }
  return path.join(os.homedir(), ".local", "share", "超级工作台");
}

function modelsPath() {
  return path.join(supportDir(), "models.json");
}

function ensureDir() {
  fs.mkdirSync(supportDir(), { recursive: true });
}

function readDoc() {
  const fp = modelsPath();
  if (!fs.existsSync(fp)) return null;
  try {
    const raw = JSON.parse(fs.readFileSync(fp, "utf8"));
    if (raw && Array.isArray(raw.providers)) return raw;
    if (Array.isArray(raw)) {
      return { version: 1, activeProviderId: (raw[0] && raw[0].id) || "", providers: raw, updatedAt: new Date().toISOString() };
    }
  } catch (_) {}
  return null;
}

function writeDoc(doc) {
  ensureDir();
  const fp = modelsPath();
  const payload = {
    version: doc.version || 1,
    activeProviderId: doc.activeProviderId || "",
    providers: doc.providers || [],
    updatedAt: new Date().toISOString()
  };
  const tmp = fp + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(payload, null, 2));
  fs.renameSync(tmp, fp);
  try { fs.copyFileSync(fp, fp + ".bak"); } catch (_) {}
  return payload;
}

function isModelsKey(key) {
  return key === "magichub_ai_providers" || key === "sw_global_models";
}

function loadForSettingsKey(key, legacyReaders) {
  if (!isModelsKey(key)) return null;
  let doc = readDoc();
  if (!doc && typeof legacyReaders === "function") {
    const legacy = legacyReaders();
    if (legacy) {
      const providers = Array.isArray(legacy) ? legacy : (legacy.providers || []);
      if (providers.length) {
        doc = writeDoc({
          version: 1,
          activeProviderId: (providers.find((p) => p.status) || providers[0] || {}).id || "",
          providers
        });
      }
    }
  }
  if (!doc) return { success: true, data: null };
  if (key === "sw_global_models") return { success: true, data: doc };
  return { success: true, data: doc.providers };
}

function saveForSettingsKey(key, data) {
  if (!isModelsKey(key)) return null;
  let providers = [];
  let activeProviderId = "";
  if (key === "sw_global_models" && data && typeof data === "object" && !Array.isArray(data)) {
    providers = data.providers || [];
    activeProviderId = data.activeProviderId || "";
  } else if (Array.isArray(data)) {
    providers = data;
  } else if (data && Array.isArray(data.providers)) {
    providers = data.providers;
    activeProviderId = data.activeProviderId || "";
  }
  if (!activeProviderId) {
    activeProviderId = (providers.find((p) => p.status) || providers[0] || {}).id || "";
  }
  const doc = writeDoc({ version: 1, activeProviderId, providers });
  return { success: true, data: key === "sw_global_models" ? doc : providers };
}

module.exports = {
  supportDir, modelsPath, readDoc, writeDoc, isModelsKey, loadForSettingsKey, saveForSettingsKey
};
