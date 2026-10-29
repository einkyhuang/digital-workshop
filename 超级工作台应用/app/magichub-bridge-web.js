/* Browser fallback for MagicHub electronAPI (local web only; Pages should not load private data). */
(function () {
  if (window.electronAPI && window.electronAPI.__swBridge) return;
  const storeKey = (k) => "magichub_settings:" + k;
  async function loadSettings(key) {
    try {
      const raw = localStorage.getItem(storeKey(key));
      return { success: true, data: raw ? JSON.parse(raw) : null };
    } catch (e) {
      return { success: false, error: String(e) };
    }
  }
  async function saveSettings(key, data) {
    try {
      localStorage.setItem(storeKey(key), JSON.stringify(data));
      return { success: true };
    } catch (e) {
      return { success: false, error: String(e) };
    }
  }
  window.electronAPI = {
    __swBridge: true,
    platform: "web",
    isSecureMode: async () => ({ secure: false }),
    openPath: async () => ({ success: false, error: "浏览器内请下载后本地打开" }),
    scanDirectory: async () => ({ success: true, files: [] }),
    saveSettings,
    loadSettings,
    readFile: async () => ({ success: false, error: "浏览器无本地读文件" }),
    writeFile: async () => ({ success: false, error: "浏览器无本地写文件" }),
    selectLocalZipAndUpdate: async () => ({ success: false, error: "请用 Mac 应用更新" })
  };
})();
