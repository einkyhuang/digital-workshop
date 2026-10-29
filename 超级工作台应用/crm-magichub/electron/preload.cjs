// ZenCRM Electron Preload Script
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  platform: process.platform,
  isSecureMode: () => ipcRenderer.invoke('get-secure-mode'),
  openPath: (path) => ipcRenderer.invoke('open-path', path),
  scanDirectory: (path) => ipcRenderer.invoke('scan-directory', path),
  saveSettings: (key, data) => ipcRenderer.invoke('save-settings', key, data),
  loadSettings: (key) => ipcRenderer.invoke('load-settings', key),
  readFile: (path) => ipcRenderer.invoke('read-file', path),
  writeFile: (path, content) => ipcRenderer.invoke('write-file', path, content),
  selectLocalZipAndUpdate: () => ipcRenderer.invoke('select-local-zip-and-update')
});

