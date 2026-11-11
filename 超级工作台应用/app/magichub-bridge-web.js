/* Browser / LAN bridge for MagicHub. On LAN server, settings go to /api/mh/settings (private/crm). */
(function () {
  if (window.electronAPI && window.electronAPI.__swBridge) return;
  const storeKey = (k) => "magichub_settings:" + k;
  async function apiLoad(key) {
    try {
      const res = await fetch("/api/mh/settings/" + encodeURIComponent(key), {
        credentials: "same-origin",
        cache: "no-store",
      });
      if (!res.ok) return null;
      return await res.json();
    } catch (_) {
      return null;
    }
  }
  async function apiSave(key, data) {
    try {
      const res = await fetch("/api/mh/settings/" + encodeURIComponent(key), {
        method: "PUT",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data }),
      });
      if (!res.ok) return { success: false, error: "http " + res.status };
      return await res.json();
    } catch (e) {
      return { success: false, error: String(e) };
    }
  }
  async function loadSettings(key) {
    const remote = await apiLoad(key);
    if (remote && remote.success) return remote;
    try {
      const raw = localStorage.getItem(storeKey(key));
      return { success: true, data: raw ? JSON.parse(raw) : null };
    } catch (e) {
      return { success: false, error: String(e) };
    }
  }
  async function saveSettings(key, data) {
    const remote = await apiSave(key, data);
    if (remote && remote.success) {
      try {
        localStorage.setItem(storeKey(key), JSON.stringify(data));
      } catch (_) {}
      return remote;
    }
    try {
      localStorage.setItem(storeKey(key), JSON.stringify(data));
      return { success: true };
    } catch (e) {
      return { success: false, error: String(e) };
    }
  }
  window.electronAPI = {
    __swBridge: true,
    platform: "web-lan",
    isSecureMode: async () => ({ secure: false }),
    openPath: async () => ({ success: false, error: "浏览器内请下载后本地打开" }),
    scanDirectory: async () => ({ success: true, files: [] }),
    saveSettings,
    loadSettings,
    readFile: async (filePath) => {
      try {
        const res = await fetch("/api/mh/local-text?path=" + encodeURIComponent(filePath || ""), {
          credentials: "same-origin",
          cache: "no-store",
        });
        if (res.ok) return await res.json();
      } catch (_) {}
      return { success: false, error: "浏览器无本地读文件" };
    },
    listCustomerArchives: async () => {
      try {
        const res = await fetch("/api/mh/customer-archives", { credentials: "same-origin", cache: "no-store" });
        if (res.ok) return await res.json();
      } catch (_) {}
      return { success: true, archives: [] };
    },
    listKnowledgeFiles: async () => {
      try {
        const res = await fetch("/api/mh/knowledge-files", { credentials: "same-origin", cache: "no-store" });
        if (res.ok) return await res.json();
      } catch (_) {}
      return { success: true, items: [] };
    },
    writeFile: async () => ({ success: false, error: "浏览器无本地写文件" }),
    selectLocalZipAndUpdate: async () => ({ success: false, error: "请用 Mac 应用更新" }),
    openGlobalSettings: async () => ({ success: false, error: "浏览器请使用本页设置" }),
    // Metadata only. Secret fields are removed before the request leaves the page.
    listAssets: async () => {
      try {
        const res = await fetch("/api/assets", { credentials: "same-origin", cache: "no-store" });
        if (!res.ok) return { success: false, error: "http " + res.status, accounts: [] };
        return await res.json();
      } catch (e) {
        return { success: false, error: String(e), accounts: [] };
      }
    },
    saveAsset: async (record) => {
      const account = stripAssetSecrets(record);
      try {
        const res = await fetch("/api/assets", {
          method: "POST",
          credentials: "same-origin",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ account }),
        });
        if (!res.ok) return { success: false, error: "http " + res.status };
        return await res.json();
      } catch (e) {
        return { success: false, error: String(e) };
      }
    },
    deleteAsset: async (id) => {
      try {
        const res = await fetch("/api/assets?id=" + encodeURIComponent(id || ""), {
          method: "DELETE",
          credentials: "same-origin",
        });
        if (!res.ok) return { success: false, error: "http " + res.status };
        return await res.json();
      } catch (e) {
        return { success: false, error: String(e) };
      }
    },
    importAssetsCsv: async (csv) => {
      try {
        const res = await fetch("/api/assets", {
          method: "POST",
          credentials: "same-origin",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ csv: String(csv || "") }),
        });
        if (!res.ok) return { success: false, error: "http " + res.status };
        return await res.json();
      } catch (e) {
        return { success: false, error: String(e) };
      }
    },
  };
  function stripAssetSecrets(record) {
    const blocked = /^(password|passwd|pwd|apikey|recoverycodes|recovery|totpsecret|totp|otpsecret|secret|token|accesstoken|secrets)$/i;
    const out = {};
    if (!record || typeof record !== "object") return out;
    for (const [key, value] of Object.entries(record)) {
      if (blocked.test(String(key).replace(/[\s_-]/g, ""))) continue;
      out[key] = value;
    }
    return out;
  }
})();
