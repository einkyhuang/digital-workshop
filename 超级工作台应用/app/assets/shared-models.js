/**
 * Global AI model/providers store shared by 超级工作台 (web agent) and MagicHub.
 * Preferred persistence (in order):
 *   1) window.electronAPI load/saveSettings (Mac WKWebView bridge / Electron → Application Support)
 *   2) localStorage "sw.global.models" (browser fallback; keys stay local, never commit)
 * Migrates from magichub_ai_providers / sw.agent.providers / sw.agent.apiKey.
 */
(function (global) {
  const LS_DOC = "sw.global.models";
  const LS_MH = "magichub_ai_providers";
  const LS_AGENT = "sw.agent.providers";
  const LS_AGENT_KEY = "sw.agent.apiKey";
  const SETTINGS_KEY = "magichub_ai_providers";
  const DOC_KEY = "sw_global_models";

  function preset(id, name, icon, iconColor, status, baseUrl, modelGroup, model) {
    return {
      id, name, type: "openai-compatible", icon, iconColor, status,
      baseUrl, apiKey: "", modelGroup, model,
      previewUrl: String(baseUrl).replace(/\/+$/, "") + "/chat/completions",
      availableModels: []
    };
  }

  function defaultProviders() {
    return [
      preset("apifree", "APIFree", "A", "bg-purple-600", true, "https://api.apifree.ai/agent/v1", "skywork-ai", "skywork-ai/skyclaw-v1"),
      preset("cloudflare", "Cloudflare", "C", "bg-orange-500", true, "https://api.cloudflare.com/client/v4", "workers-ai", "meta-llama/llama-3-8b-instruct"),
      preset("siliconflow", "硅基流动", "硅", "bg-indigo-600", true, "https://api.siliconflow.cn/v1", "deepseek", "deepseek-ai/DeepSeek-V3"),
      preset("gemini", "Gemini", "G", "bg-blue-500", true, "https://generativelanguage.googleapis.com/v1beta/openai", "google", "gemini-1.5-pro"),
      preset("alicoding", "阿里coding", "阿", "bg-blue-800", true, "https://api.alicoding.com/v1", "qwen", "qwen-turbo"),
      preset("qwen", "通义千问", "千", "bg-violet-600", true, "https://dashscope.aliyuncs.com/compatible-mode/v1", "qwen", "qwen-max"),
      preset("bailian", "阿里云百炼", "百", "bg-blue-600", false, "https://dashscope.aliyuncs.com/compatible-mode/v1", "qwen", "qwen-max"),
      preset("volcengine", "火山引擎", "火", "bg-blue-400", false, "https://ark.cn-beijing.volces.com/api/v3", "doubao", "doubao-pro"),
      preset("minimax", "MiniMax", "M", "bg-red-500", false, "https://api.minimaxi.com/v1", "abab", "abab6.5-chat"),
      preset("deepseek", "深度求索", "深", "bg-blue-700", true, "https://api.deepseek.com/v1", "deepseek", "deepseek-chat"),
      preset("zhipu", "智谱开放平台", "智", "bg-blue-900", false, "https://open.bigmodel.cn/api/paas/v4", "glm", "glm-4"),
      preset("openrouter", "OpenRouter", "O", "bg-purple-800", false, "https://openrouter.ai/api/v1", "openrouter", "meta-llama/llama-3-70b-instruct"),
      preset("cerebras", "Cerebras AI", "C", "bg-orange-600", false, "https://api.cerebras.ai/v1", "cerebras", "llama3.1-8b"),
      preset("nvidia", "英伟达", "英", "bg-green-600", false, "https://integrate.api.nvidia.com/v1", "nvidia", "meta/llama3-70b-instruct"),
      preset("vpsairobot", "vpsairobot", "V", "bg-green-500", false, "https://api.vpsairobot.com/v1", "custom", "vps-smart-v1"),
      preset("vercel", "Vercel AI Gateway", "▲", "bg-black", false, "https://gateway.ai.vercel.cloud/v1", "gateway", "openai/gpt-4o"),
      preset("qiniu", "七牛云 AI 推理", "七", "bg-blue-300", false, "https://api.qiniu.com/v1", "qiniu-ai", "qiniu-llama-3")
    ];
  }

  function mergePresets(existing) {
    const defaults = defaultProviders();
    if (!existing || !existing.length) return defaults;
    const byId = {};
    defaults.forEach((p) => { byId[p.id] = { ...p }; });
    existing.forEach((p) => {
      if (!p || !p.id) return;
      byId[p.id] = { ...(byId[p.id] || {}), ...p, type: p.type || "openai-compatible" };
    });
    const out = [];
    const seen = new Set();
    defaults.forEach((p) => { out.push(byId[p.id]); seen.add(p.id); });
    existing.forEach((p) => {
      if (p && p.id && !seen.has(p.id)) { out.push({ ...p, type: p.type || "openai-compatible" }); seen.add(p.id); }
    });
    return out;
  }

  function readLocalDoc() {
    try {
      const raw = localStorage.getItem(LS_DOC);
      if (raw) {
        const d = JSON.parse(raw);
        if (d && Array.isArray(d.providers)) return d;
      }
    } catch (_) {}
    return null;
  }

  function migrateLocal() {
    let providers = null;
    try {
      const mh = localStorage.getItem(LS_MH);
      if (mh) {
        const parsed = JSON.parse(mh);
        if (Array.isArray(parsed)) providers = parsed;
        else if (parsed && Array.isArray(parsed.providers)) providers = parsed.providers;
      }
    } catch (_) {}
    try {
      const ag = localStorage.getItem(LS_AGENT);
      if (ag) {
        const arr = JSON.parse(ag);
        if (Array.isArray(arr) && arr.length) {
          const mapped = arr.map((p, i) => ({
            id: p.id || ("sw-agent-" + i),
            name: p.name || p.label || ("Agent " + i),
            type: "openai-compatible",
            status: true,
            baseUrl: p.baseURL || p.baseUrl || "",
            apiKey: "",
            modelGroup: "custom",
            model: p.model || "deepseek-chat",
            previewUrl: ((p.baseURL || p.baseUrl || "").replace(/\/+$/, "")) + "/chat/completions",
            availableModels: []
          })).filter((p) => p.baseUrl);
          if (!providers) providers = mapped;
          else {
            mapped.forEach((m) => {
              if (!providers.some((x) => x.id === m.id)) providers.push(m);
            });
          }
        }
      }
    } catch (_) {}
    const key = (localStorage.getItem(LS_AGENT_KEY) || "").trim();
    providers = mergePresets(providers || []);
    if (key) {
      const t = providers.find((p) => p.status) || providers.find((p) => p.id === "deepseek") || providers[0];
      if (t && !t.apiKey) t.apiKey = key;
    }
    const activeProviderId = (providers.find((p) => p.status) || providers[0] || {}).id || "deepseek";
    return { version: 1, activeProviderId, providers, updatedAt: new Date().toISOString() };
  }

  async function loadDocument() {
    if (global.electronAPI && global.electronAPI.loadSettings) {
      try {
        let res = await global.electronAPI.loadSettings(DOC_KEY);
        if (res && res.success && res.data && Array.isArray(res.data.providers)) {
          return { version: res.data.version || 1, activeProviderId: res.data.activeProviderId || "", providers: mergePresets(res.data.providers), updatedAt: res.data.updatedAt || "" };
        }
        res = await global.electronAPI.loadSettings(SETTINGS_KEY);
        if (res && res.success && res.data) {
          const arr = Array.isArray(res.data) ? res.data : (res.data.providers || null);
          if (arr && arr.length) {
            const doc = { version: 1, activeProviderId: (arr.find((p) => p.status) || arr[0]).id, providers: mergePresets(arr), updatedAt: new Date().toISOString() };
            try { await saveDocument(doc); } catch (_) {}
            return doc;
          }
        }
      } catch (_) {}
    }
    const local = readLocalDoc();
    if (local) {
      local.providers = mergePresets(local.providers);
      return local;
    }
    const migrated = migrateLocal();
    try { localStorage.setItem(LS_DOC, JSON.stringify(migrated)); } catch (_) {}
    try { localStorage.setItem(LS_MH, JSON.stringify(migrated.providers)); } catch (_) {}
    return migrated;
  }

  async function saveDocument(doc) {
    const payload = {
      version: doc.version || 1,
      activeProviderId: doc.activeProviderId || "",
      providers: doc.providers || [],
      updatedAt: new Date().toISOString()
    };
    try { localStorage.setItem(LS_DOC, JSON.stringify(payload)); } catch (_) {}
    try { localStorage.setItem(LS_MH, JSON.stringify(payload.providers)); } catch (_) {}
    // Keep agent panel in sync (no keys in agent list)
    try {
      localStorage.setItem(LS_AGENT, JSON.stringify(payload.providers.map((p) => ({
        id: p.id, name: p.name, baseURL: p.baseUrl || p.baseURL, model: p.model, hasKey: !!(p.apiKey && String(p.apiKey).trim())
      }))));
    } catch (_) {}
    if (global.electronAPI && global.electronAPI.saveSettings) {
      try {
        await global.electronAPI.saveSettings(SETTINGS_KEY, payload.providers);
        await global.electronAPI.saveSettings(DOC_KEY, payload);
      } catch (_) {}
    }
    return payload;
  }

  async function loadProviders() {
    const doc = await loadDocument();
    return doc.providers || [];
  }

  async function saveProviders(providers, activeProviderId) {
    const active = activeProviderId || (providers.find((p) => p.status) || providers[0] || {}).id || "";
    return saveDocument({ version: 1, activeProviderId: active, providers });
  }

  global.SWSharedModels = {
    SETTINGS_KEY, DOC_KEY, defaultProviders, mergePresets, loadDocument, saveDocument, loadProviders, saveProviders
  };
})(typeof window !== "undefined" ? window : globalThis);
