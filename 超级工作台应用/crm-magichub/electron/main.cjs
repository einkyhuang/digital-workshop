const { app, BrowserWindow, Menu, shell, ipcMain } = require('electron');
const path = require('path');
const globalModels = require('../../shared/global-models-store.cjs');

let mainWindow = null;

function createWindow() {
  const isDev = !app.isPackaged;
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 850,
    minWidth: 1000,
    minHeight: 700,
    titleBarStyle: 'hiddenInset', // Apple native hidden title bar with traffic lights inset
    vibrancy: isDev ? 'under-window' : null,
    visualEffectState: isDev ? 'active' : 'inactive',
    backgroundColor: isDev ? '#00000000' : '#F9FBFA',
    show: false,                  // Hide window until it is ready to avoid flashing
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.cjs')
    }
  });

  mainWindow.webContents.on('did-fail-load', (_event, errorCode, errorDescription, validatedURL) => {
    console.error('[MagicHub] did-fail-load:', errorCode, errorDescription, validatedURL);
    mainWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(`
      <body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:#F9FBFA;color:#243026;padding:40px;">
        <h2>MagicHub 加载失败</h2>
        <p>页面资源未能正确加载，请检查打包资源路径。</p>
        <pre style="white-space:pre-wrap;background:#fff;border:1px solid #ddd;border-radius:12px;padding:16px;">${errorCode} ${errorDescription}\n${validatedURL}</pre>
      </body>
    `)}`);
  });

  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    console.error('[MagicHub] render-process-gone:', details);
  });

  mainWindow.webContents.on('console-message', (_event, level, message, line, sourceId) => {
    console.log(`[MagicHub renderer:${level}] ${message} (${sourceId}:${line})`);
  });

  if (isDev) {
    // Load local dev server URL
    mainWindow.loadURL('http://localhost:5173');
  } else {
    // Load static HTML in production
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'));
  }

  // Show window once it is fully rendered to avoid flashing
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Setup standard premium macOS Application Menus
  setupMenu();
}

function setupMenu() {
  const template = [
    {
      label: 'MagicHub',
      submenu: [
        { label: '关于 MagicHub', role: 'about' },
        { type: 'separator' },
        { label: '服务设置', role: 'services' },
        { type: 'separator' },
        { label: '隐藏 MagicHub', role: 'hide' },
        { label: '隐藏其他', role: 'hideOthers' },
        { label: '显示全部', role: 'unhide' },
        { type: 'separator' },
        { label: '退出 MagicHub', role: 'quit' }
      ]
    },
    {
      label: '编辑',
      submenu: [
        { label: '撤销', role: 'undo' },
        { label: '重做', role: 'redo' },
        { type: 'separator' },
        { label: '剪切', role: 'cut' },
        { label: '复制', role: 'copy' },
        { label: '粘贴', role: 'paste' },
        { label: '全选', role: 'selectAll' }
      ]
    },
    {
      label: '视图',
      submenu: [
        { label: '重新加载', role: 'reload' },
        { label: '强制重新加载', role: 'forceReload' },
        { label: '开发者工具', role: 'toggleDevTools' },
        { type: 'separator' },
        { label: '实际大小', role: 'resetZoom' },
        { label: '放大', role: 'zoomIn' },
        { label: '缩小', role: 'zoomOut' },
        { type: 'separator' },
        { label: '全屏模式', role: 'togglefullscreen' }
      ]
    },
    {
      label: '窗口',
      submenu: [
        { label: '最小化', role: 'minimize' },
        { label: '缩放', role: 'zoom' },
        { type: 'separator' },
        { label: '前置全部窗口', role: 'front' },
        { type: 'separator' },
        { label: '关闭窗口', role: 'close' }
      ]
    },
    {
      label: '帮助',
      role: 'help',
      submenu: [
        {
          label: '访问官网',
          click: async () => {
            await shell.openExternal('https://www.zen-specialty-manufacturing.com');
          }
        }
      ]
    }
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

// Register IPC Main handler for native folder opening
ipcMain.handle('open-path', async (event, folderPath) => {
  try {
    const fs = require('fs');
    // Auto-create directory if not exist before opening
    if (!fs.existsSync(folderPath)) {
      fs.mkdirSync(folderPath, { recursive: true });
    }
    await shell.openPath(folderPath);
    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

// Secure Settings physical persistence for Electron (Across app updates)
ipcMain.handle('save-settings', async (event, key, data) => {
  try {
    if (globalModels.isModelsKey(key)) {
      // Also mirror into Electron userData for backward compat
      const mirrored = globalModels.saveForSettingsKey(key, data);
      try {
        const fsSync = require('fs');
        const userDataPath = app.getPath('userData');
        const settingsDir = path.join(userDataPath, 'settings');
        if (!fsSync.existsSync(settingsDir)) fsSync.mkdirSync(settingsDir, { recursive: true });
        const providers = Array.isArray(data) ? data : (data && data.providers) || [];
        fsSync.writeFileSync(path.join(settingsDir, 'magichub_ai_providers.json'), JSON.stringify(providers, null, 2));
      } catch (_) {}
      return mirrored || { success: true };
    }
    const fs = require('fs').promises;
    const fsSync = require('fs');
    const userDataPath = app.getPath('userData');
    const settingsDir = path.join(userDataPath, 'settings');
    if (!fsSync.existsSync(settingsDir)) {
      fsSync.mkdirSync(settingsDir, { recursive: true });
    }
    const filePath = path.join(settingsDir, `${key}.json`);
    const tmpPath = `${filePath}.tmp`;
    const payload = JSON.stringify(data, null, 2);

    // Atomic write: write to a temp file first, then rename over the target.
    // This guarantees the existing file is never left half-written/corrupted
    // even if the process is killed (e.g. during an app update) mid-write.
    await fs.writeFile(tmpPath, payload, 'utf-8');
    await fs.rename(tmpPath, filePath);

    // Keep a rolling backup copy as an extra safety net against corruption.
    try {
      await fs.copyFile(filePath, `${filePath}.bak`);
    } catch (_) { /* backup is best-effort */ }

    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

ipcMain.handle('load-settings', async (event, key) => {
  try {
    if (globalModels.isModelsKey(key)) {
      const fs = require('fs');
      const userDataPath = app.getPath('userData');
      const legacyPath = path.join(userDataPath, 'settings', 'magichub_ai_providers.json');
      const altPath = path.join(userDataPath, 'settings', `${key}.json`);
      const result = globalModels.loadForSettingsKey(key, () => {
        for (const p of [legacyPath, altPath]) {
          if (fs.existsSync(p)) {
            try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch (_) {}
          }
        }
        return null;
      });
      if (result) return result;
    }
    const fs = require('fs');
    const userDataPath = app.getPath('userData');
    const filePath = path.join(userDataPath, 'settings', `${key}.json`);
    if (!fs.existsSync(filePath)) {
      return { success: true, data: null };
    }
    try {
      const content = fs.readFileSync(filePath, 'utf-8');
      const data = JSON.parse(content);
      return { success: true, data };
    } catch (parseErr) {
      // Primary file is corrupted — try the rolling backup before giving up.
      const bakPath = `${filePath}.bak`;
      if (fs.existsSync(bakPath)) {
        try {
          const bakContent = fs.readFileSync(bakPath, 'utf-8');
          const bakData = JSON.parse(bakContent);
          console.warn(`[MagicHub] Recovered ${key} from backup after corruption.`);
          return { success: true, data: bakData };
        } catch (_) { /* fall through */ }
      }
      return { success: false, error: parseErr.message };
    }
  } catch (e) {
    return { success: false, error: e.message };
  }
});

// Scan folder for PDF/Office documents
ipcMain.handle('scan-directory', async (event, dirPath) => {
  try {
    const fs = require('fs');
    if (!fs.existsSync(dirPath)) {
      return { success: true, files: [] };
    }
    const files = fs.readdirSync(dirPath);
    const docFiles = files
      .filter(f => f.endsWith('.pdf') || f.endsWith('.docx') || f.endsWith('.xlsx') || f.endsWith('.md') || f.endsWith('.html') || f.endsWith('.json'))
      .map(f => {
        const stats = fs.statSync(path.join(dirPath, f));
        return {
          name: f,
          sizeBytes: stats.size,
          modifiedTime: stats.mtime
        };
      });
    return { success: true, files: docFiles };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

// Read physical file contents from a specific path
ipcMain.handle('read-file', async (event, filePath) => {
  try {
    const fs = require('fs');
    if (!fs.existsSync(filePath)) {
      return { success: false, error: '文件不存在' };
    }
    const content = fs.readFileSync(filePath, 'utf-8');
    return { success: true, content };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

// Secure physical file writing for Electron (Saves generated AI reports locally on disk)
ipcMain.handle('write-file', async (event, filePath, content) => {
  try {
    const fs = require('fs').promises;
    const fsSync = require('fs');
    const dirname = path.dirname(filePath);
    if (!fsSync.existsSync(dirname)) {
      fsSync.mkdirSync(dirname, { recursive: true });
    }
    await fs.writeFile(filePath, content, 'utf-8');
    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
});

// Local One-Key App Update Engine (Select update ZIP package, extract, replace, relaunch)
ipcMain.handle('select-local-zip-and-update', async (event) => {
  try {
    const { dialog } = require('electron');
    const fs = require('fs');
    const { exec, spawn } = require('child_process');

    const result = await dialog.showOpenDialog(mainWindow, {
      title: '选择 MagicHub 本地升级包 (.zip)',
      buttonLabel: '导入并升级 🚀',
      filters: [
        { name: 'Zip 压缩包', extensions: ['zip'] }
      ],
      properties: ['openFile']
    });

    if (result.canceled || result.filePaths.length === 0) {
      return { success: false, cancelled: true };
    }

    const zipPath = result.filePaths[0];

    // Verify running from packaged bundle (.app)
    const runningExePath = process.execPath;
    const appBundlePath = path.resolve(runningExePath, '../../..');

    if (!app.isPackaged || !appBundlePath.endsWith('.app')) {
      return { 
        success: false, 
        error: `当前运行在开发/非打包模式下，不支持应用包一键更新。\n(您的运行路径为: ${runningExePath})` 
      };
    }

    // Define temp extract path inside app userData
    const tempExtractDir = path.join(app.getPath('temp'), `magichub-update-${Date.now()}`);
    if (!fs.existsSync(tempExtractDir)) {
      fs.mkdirSync(tempExtractDir, { recursive: true });
    }

    // Extract using native macOS /usr/bin/unzip (extremely fast and has zero dependencies)
    return new Promise((resolve) => {
      exec(`/usr/bin/unzip -q -o "${zipPath}" -d "${tempExtractDir}"`, (unzipErr) => {
        if (unzipErr) {
          resolve({ success: false, error: `解压升级包失败: ${unzipErr.message}\n请确认该压缩包完整且为合法的 Zip 格式。` });
          return;
        }

        // Scan the extracted dir to find a new .app bundle
        const files = fs.readdirSync(tempExtractDir);
        const appBundleName = files.find(f => f.endsWith('.app'));
        if (!appBundleName) {
          resolve({ success: false, error: '升级包中未检测到合法的 macOS 应用包 (.app) 资源，请确认使用的是 MagicHub 官方打包升级 ZIP。' });
          return;
        }

        const extractedAppPath = path.join(tempExtractDir, appBundleName);

        // Build the self-executing bash script that overwrites the running app bundle and relaunches
        const updaterScriptPath = path.join(app.getPath('temp'), `magichub_updater_${Date.now()}.sh`);
        const scriptContent = `#!/bin/bash
# Local Click Update background script for MagicHub
# 1. Wait for parent process to quit
sleep 1.2

# 2. Force delete old application bundle
rm -rf "${appBundlePath}"

# 3. Copy new application bundle in place
cp -R "${extractedAppPath}" "${appBundlePath}"

# 4. Relaunch the new application
open "${appBundlePath}"

# 5. Clean up temporary extract folder
rm -rf "${tempExtractDir}"
`;

        fs.writeFileSync(updaterScriptPath, scriptContent, { mode: 0o755 });

        // Spawn bash script detached
        const child = spawn('/bin/bash', [updaterScriptPath], {
          detached: true,
          stdio: 'ignore'
        });
        child.unref();

        // Gracefully quit current instance to allow overwriting
        setTimeout(() => {
          app.quit();
        }, 100);

        resolve({ success: true });
      });
    });

  } catch (e) {
    return { success: false, error: e.message };
  }
});


// ── Seed data: auto-import on first launch ──────────────────────────────────
// If magichub_leads.json doesn't exist in userData (fresh install),
// copy the bundled leads_seed.json into userData so all 19,000+ customers
// are available immediately and persist permanently.
function seedLeadsIfNeeded() {
  try {
    const fs = require('fs');
    const userDataPath = app.getPath('userData');
    const settingsDir = path.join(userDataPath, 'settings');
    const leadsFile = path.join(settingsDir, 'magichub_leads.json');

    // Only seed if file doesn't exist yet (first install)
    if (fs.existsSync(leadsFile)) {
      console.log('[MagicHub] Leads data already exists, skipping seed.');
      return;
    }

    // Find the seed file - works both in dev and packaged app
    let seedPath;
    if (app.isPackaged) {
      // In packaged app, resources are in Contents/Resources/
      seedPath = path.join(process.resourcesPath, 'seeds', 'leads_seed.json');
    } else {
      // In dev, use public/seeds/
      seedPath = path.join(__dirname, '../public/seeds/leads_seed.json');
    }

    if (!fs.existsSync(seedPath)) {
      console.warn('[MagicHub] Seed file not found at:', seedPath);
      return;
    }

    // Ensure settings dir exists
    if (!fs.existsSync(settingsDir)) {
      fs.mkdirSync(settingsDir, { recursive: true });
    }

    // Copy seed to userData (minified, already minified in seed file)
    console.log('[MagicHub] First launch detected – seeding 19,000+ customers...');
    fs.copyFileSync(seedPath, leadsFile);
    console.log('[MagicHub] Seed import complete:', leadsFile);
  } catch (e) {
    console.error('[MagicHub] Seed import failed:', e.message);
  }
}

// App lifecycle setup
app.whenReady().then(() => {
  // Seed customer data on first launch before creating window
  seedLeadsIfNeeded();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
