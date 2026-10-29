(function () {
  if (window.electronAPI && window.electronAPI.__swBridge) return;
  const pending = new Map();
  let seq = 0;
  function invoke(method, args) {
    return new Promise((resolve, reject) => {
      const id = String(++seq);
      pending.set(id, { resolve, reject });
      try {
        window.webkit.messageHandlers.swMagicHub.postMessage({ id, method, args: args || [] });
      } catch (e) {
        pending.delete(id);
        reject(e);
      }
    });
  }
  window.addEventListener('message', function () {});
  window.__swBridgeResolve = function (id, ok, payload, error) {
    const p = pending.get(String(id));
    if (!p) return;
    pending.delete(String(id));
    if (ok) p.resolve(payload);
    else p.reject(new Error(error || 'bridge error'));
  };
  window.electronAPI = {
    __swBridge: true,
    platform: 'darwin',
    isSecureMode: () => invoke('get-secure-mode', []),
    openPath: (path) => invoke('open-path', [path]),
    scanDirectory: (path) => invoke('scan-directory', [path]),
    saveSettings: (key, data) => invoke('save-settings', [key, data]),
    loadSettings: (key) => invoke('load-settings', [key]),
    readFile: (path) => invoke('read-file', [path]),
    writeFile: (path, content) => invoke('write-file', [path, content]),
    selectLocalZipAndUpdate: () => invoke('select-local-zip-and-update', [])
  };
  document.documentElement.setAttribute('data-sw-host', 'mac');
})();
