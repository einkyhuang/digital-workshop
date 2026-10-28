import Database from 'better-sqlite3';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dbPath = process.env.SMART_PLAN_DB_PATH || path.join(__dirname, 'smart_plan.db');

const db = new Database(dbPath);

// Enable WAL mode for high concurrency
db.pragma('journal_mode = WAL');

// Initialize database tables
db.exec(`
  CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    color TEXT DEFAULT '#3b82f6',
    icon TEXT DEFAULT 'Folder',
    status TEXT DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'todo', -- 'todo', 'in_progress', 'done', 'archived'
    priority TEXT DEFAULT 'medium', -- 'high', 'medium', 'low'
    due_date TEXT, -- YYYY-MM-DD
    due_time TEXT, -- HH:mm
    project_id TEXT,
    apple_reminder_id TEXT,
    sync_status TEXT DEFAULT 'synced', -- 'synced', 'pending', 'error'
    last_synced_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE SET NULL
  );

  CREATE TABLE IF NOT EXISTS ai_conversations (
    id TEXT PRIMARY KEY,
    role TEXT NOT NULL, -- 'user', 'assistant', 'system'
    content TEXT NOT NULL,
    metadata TEXT, -- JSON string
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS sync_logs (
    id TEXT PRIMARY KEY,
    direction TEXT NOT NULL, -- 'to_reminders', 'from_reminders'
    action TEXT NOT NULL, -- 'created', 'updated', 'completed', 'archived', 'skipped'
    item_name TEXT NOT NULL,
    project_name TEXT,
    details TEXT,
    status TEXT DEFAULT 'success',
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS website_projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- '进行中', '已交付', '功能基础建设', '挂了'
    status TEXT NOT NULL, -- 'in_progress', 'delivered', 'infrastructure', 'inactive'
    local_path TEXT NOT NULL UNIQUE,
    url TEXT,
    framework TEXT,
    description TEXT,
    last_modified TEXT,
    -- Customer CRM details
    client_name TEXT,
    client_phone TEXT,
    client_wechat TEXT,
    client_email TEXT,
    client_company TEXT,
    -- Financial tracking
    total_amount REAL DEFAULT 0,
    deposit_amount REAL DEFAULT 0,
    paid_amount REAL DEFAULT 0,
    unpaid_amount REAL DEFAULT 0,
    payment_status TEXT DEFAULT 'pending', -- 'pending', 'deposit_paid', 'fully_paid'
    -- Assets & Credentials (encrypted/secure json note)
    assets_credentials TEXT, -- domain accounts, server logins, cms logins
    services TEXT, -- JSON array of ordered services: ["网站搭建", "SEO/GEO", ...]
    service_start_date TEXT, -- YYYY-MM-DD
    service_end_date TEXT, -- YYYY-MM-DD
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS website_follow_ups (
    id TEXT PRIMARY KEY,
    website_id TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT DEFAULT 'note', -- 'note', 'call', 'meeting', 'payment', 'milestone'
    created_at TEXT NOT NULL,
    FOREIGN KEY (website_id) REFERENCES website_projects(id) ON DELETE CASCADE
  );
`);

// Safe migrations for website_projects existing columns
const existingColumns = db.prepare(`PRAGMA table_info(website_projects)`).all().map(c => c.name);
const columnsToAdd = [
  { name: 'client_name', type: 'TEXT' },
  { name: 'client_phone', type: 'TEXT' },
  { name: 'client_wechat', type: 'TEXT' },
  { name: 'client_email', type: 'TEXT' },
  { name: 'client_company', type: 'TEXT' },
  { name: 'total_amount', type: 'REAL DEFAULT 0' },
  { name: 'deposit_amount', type: 'REAL DEFAULT 0' },
  { name: 'paid_amount', type: 'REAL DEFAULT 0' },
  { name: 'unpaid_amount', type: 'REAL DEFAULT 0' },
  { name: 'payment_status', type: "TEXT DEFAULT 'pending'" },
  { name: 'assets_credentials', type: 'TEXT' },
  { name: 'services', type: 'TEXT' },
  { name: 'service_start_date', type: 'TEXT' },
  { name: 'service_end_date', type: 'TEXT' }
];

for (const col of columnsToAdd) {
  if (!existingColumns.includes(col.name)) {
    try {
      db.exec(`ALTER TABLE website_projects ADD COLUMN ${col.name} ${col.type}`);
    } catch (e) {
      console.error(`Migration error adding ${col.name}:`, e.message);
    }
  }
}


// Seed default settings if not exists
const defaultSettings = [
  ['reminder_list_name', 'AI 智能日程'],
  ['auto_sync_interval', '20'],
  ['auto_sync_enabled', 'true'],
  ['llm_provider', 'deepseek'],
  ['llm_base_url', 'https://api.deepseek.com/v1'],
  ['llm_api_key', ''],
  ['llm_model', 'deepseek-chat'],
  ['fallback_to_heuristic', 'true'],
  ['website_available_services', JSON.stringify(['网站搭建', 'SEO/GEO', '科学上网'])]
];

const insertSetting = db.prepare(`INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)`);
for (const [k, v] of defaultSettings) {
  insertSetting.run(k, v);
}

// Seed default starter projects if table is empty
const projectCount = db.prepare(`SELECT count(*) as count FROM projects`).get().count;
if (projectCount === 0) {
  const now = new Date().toISOString();
  const insertProject = db.prepare(`
    INSERT INTO projects (id, name, description, color, icon, status, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, 'active', ?, ?)
  `);

  insertProject.run(crypto.randomUUID(), '外贸客户跟进', '海外客户询盘、报价与订单跟踪', '#3b82f6', 'Globe', now, now);
  insertProject.run(crypto.randomUUID(), '智能日程管理', '系统功能开发、迭代与AI算法优化', '#8b5cf6', 'Sparkles', now, now);
  insertProject.run(crypto.randomUUID(), '个人生活与健康', '运动健身、阅读提升与生活日常安排', '#10b981', 'Heart', now, now);
  insertProject.run(crypto.randomUUID(), '日常综合待办', '琐碎杂务与未归类临时任务', '#f59e0b', 'CheckSquare', now, now);
}

export default db;
