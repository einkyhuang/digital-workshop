import { app, BrowserWindow, shell, ipcMain } from 'electron';
import path from 'path';
import { fileURLToPath } from 'url';
import http from 'http';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let mainWindow = null;
const SERVER_PORT = 3300;
const SERVER_URL = `http://localhost:${SERVER_PORT}`;

// Function to check if server is ready
function waitForServer(callback, retries = 30) {
  const req = http.get(SERVER_URL, (res) => {
    if (res.statusCode >= 200 && res.statusCode < 400) {
      callback();
    } else {
      setTimeout(() => waitForServer(callback, retries - 1), 300);
    }
  });

  req.on('error', () => {
    if (retries > 0) {
      setTimeout(() => waitForServer(callback, retries - 1), 300);
    } else {
      console.error('Server failed to start in time');
      callback(); // Try anyway
    }
  });

  req.end();
}

async function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1380,
    height: 900,
    minWidth: 1080,
    minHeight: 700,
    titleBarStyle: 'hiddenInset', // Native macOS traffic lights integrated
    trafficLightPosition: { x: 18, y: 18 },
    backgroundColor: '#f7f7f8',
    show: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: false,
      webSecurity: false
    }
  });

  // Open external links in default browser instead of electron window
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      shell.openExternal(url);
      return { action: 'deny' };
    }
    return { action: 'allow' };
  });

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  await mainWindow.loadURL(SERVER_URL);
}

// Single instance lock
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  app.whenReady().then(async () => {
    // Ensure database path persists in app userData or project dir
    const userDataPath = app.getPath('userData');
    const dbDir = app.isPackaged ? userDataPath : path.join(__dirname, 'server');
    process.env.SMART_PLAN_DB_PATH = path.join(dbDir, 'smart_plan.db');

    // Start backend server in the background inside this process
    try {
      await import('./server/index.js');
      console.log('✅ Local SmartPlan Backend Server successfully started inside Electron, DB:', process.env.SMART_PLAN_DB_PATH);
    } catch (err) {
      console.error('Backend startup error:', err);
    }

    waitForServer(() => {
      createWindow();
    });

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
}
