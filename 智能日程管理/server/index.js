import express from 'express';
import cors from 'cors';
import crypto from 'crypto';
import path from 'path';
import { fileURLToPath } from 'url';
import db from './db.js';
import { remindersService } from './remindersService.js';
import { aiService } from './aiService.js';
import { syncEngine } from './syncEngine.js';
import { websiteService } from './websiteService.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3300;

app.use(cors());
app.use(express.json());

// Serve static build in production
const clientDistPath = path.join(__dirname, '../client/dist');
app.use(express.static(clientDistPath));

// ----------------- PROJECTS API -----------------
app.get('/api/projects', (req, res) => {
  try {
    const projects = db.prepare(`
      SELECT p.*,
        COUNT(t.id) as total_tasks,
        SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) as done_tasks,
        SUM(CASE WHEN t.status != 'done' AND t.status != 'archived' THEN 1 ELSE 0 END) as active_tasks
      FROM projects p
      LEFT JOIN tasks t ON p.id = t.project_id
      GROUP BY p.id
      ORDER BY p.created_at DESC
    `).all();
    res.json({ success: true, data: projects });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/projects', (req, res) => {
  try {
    const { name, description, color, icon } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, error: '项目名称不能为空' });
    }
    const id = crypto.randomUUID();
    const now = new Date().toISOString();
    db.prepare(`
      INSERT INTO projects (id, name, description, color, icon, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 'active', ?, ?)
    `).run(id, name.trim(), description || '', color || '#3b82f6', icon || 'Folder', now, now);

    const project = db.prepare(`SELECT * FROM projects WHERE id = ?`).get(id);
    res.json({ success: true, data: project });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.put('/api/projects/:id', (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, color, icon, status } = req.body;
    const now = new Date().toISOString();
    db.prepare(`
      UPDATE projects
      SET name = COALESCE(?, name),
          description = COALESCE(?, description),
          color = COALESCE(?, color),
          icon = COALESCE(?, icon),
          status = COALESCE(?, status),
          updated_at = ?
      WHERE id = ?
    `).run(name, description, color, icon, status, now, id);

    const updated = db.prepare(`SELECT * FROM projects WHERE id = ?`).get(id);
    res.json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/projects/:id', (req, res) => {
  try {
    const { id } = req.params;
    db.prepare(`DELETE FROM projects WHERE id = ?`).run(id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ----------------- TASKS API -----------------
app.get('/api/tasks', (req, res) => {
  try {
    const { projectId, status } = req.query;
    let query = `
      SELECT t.*, p.name as project_name, p.color as project_color
      FROM tasks t
      LEFT JOIN projects p ON t.project_id = p.id
      WHERE 1=1
    `;
    const params = [];
    if (projectId) {
      query += ` AND t.project_id = ?`;
      params.push(projectId);
    }
    if (status) {
      query += ` AND t.status = ?`;
      params.push(status);
    }
    query += ` ORDER BY t.status = 'done', CASE WHEN t.due_date IS NULL THEN 1 ELSE 0 END, t.due_date ASC, t.due_time ASC, t.created_at DESC`;

    const tasks = db.prepare(query).all(...params);
    res.json({ success: true, data: tasks });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/tasks', async (req, res) => {
  try {
    const { title, description, status, priority, due_date, due_time, project_id } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, error: '任务标题不能为空' });
    }
    const id = crypto.randomUUID();
    const now = new Date().toISOString();
    db.prepare(`
      INSERT INTO tasks (
        id, title, description, status, priority, due_date, due_time,
        project_id, sync_status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)
    `).run(
      id,
      title.trim(),
      description || '',
      status || 'todo',
      priority || 'medium',
      due_date || null,
      due_time || null,
      project_id || null,
      now,
      now
    );

    const task = db.prepare(`
      SELECT t.*, p.name as project_name, p.color as project_color
      FROM tasks t LEFT JOIN projects p ON t.project_id = p.id WHERE t.id = ?
    `).get(id);

    // Trigger immediate sync to Reminders
    syncEngine.pushTaskToReminders(task).catch(e => console.error('[Push error]:', e));

    res.json({ success: true, data: task });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.put('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, status, priority, due_date, due_time, project_id } = req.body;
    const now = new Date().toISOString();

    db.prepare(`
      UPDATE tasks
      SET title = COALESCE(?, title),
          description = COALESCE(?, description),
          status = COALESCE(?, status),
          priority = COALESCE(?, priority),
          due_date = ?,
          due_time = ?,
          project_id = ?,
          updated_at = ?
      WHERE id = ?
    `).run(title, description, status, priority, due_date, due_time, project_id, now, id);

    const task = db.prepare(`
      SELECT t.*, p.name as project_name, p.color as project_color
      FROM tasks t LEFT JOIN projects p ON t.project_id = p.id WHERE t.id = ?
    `).get(id);

    // Push update to Reminders
    syncEngine.pushTaskToReminders(task).catch(e => console.error('[Push error]:', e));

    res.json({ success: true, data: task });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const task = db.prepare(`SELECT * FROM tasks WHERE id = ?`).get(id);
    if (task && task.apple_reminder_id) {
      const listName = syncEngine.getTargetListName();
      remindersService.deleteReminder(listName, task.apple_reminder_id).catch(() => {});
    }
    db.prepare(`DELETE FROM tasks WHERE id = ?`).run(id);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ----------------- AI CHAT & PARSER API -----------------
app.post('/api/ai/chat', async (req, res) => {
  try {
    const { message } = req.body;
    if (!message || !message.trim()) {
      return res.status(400).json({ success: false, error: '输入内容不能为空' });
    }

    const now = new Date().toISOString();
    // Record user message
    db.prepare(`
      INSERT INTO ai_conversations (id, role, content, created_at)
      VALUES (?, 'user', ?, ?)
    `).run(crypto.randomUUID(), message, now);

    // Process through AI
    const result = await aiService.processChatMessage(message);

    let createdTask = null;
    let affectedProject = result.project || null;

    // 1. Task Creation
    if (result.intent === 'create_task' && result.task) {
      const t = result.task;
      const taskId = crypto.randomUUID();
      db.prepare(`
        INSERT INTO tasks (
          id, title, description, status, priority, due_date, due_time,
          project_id, sync_status, created_at, updated_at
        ) VALUES (?, ?, ?, 'todo', ?, ?, ?, ?, 'pending', ?, ?)
      `).run(
        taskId,
        t.title,
        t.description || 'AI智能对话创建',
        t.priority || 'medium',
        t.dueDate || null,
        t.dueTime || null,
        t.projectId || null,
        now,
        now
      );

      createdTask = db.prepare(`
        SELECT t.*, p.name as project_name, p.color as project_color
        FROM tasks t LEFT JOIN projects p ON t.project_id = p.id WHERE t.id = ?
      `).get(taskId);

      // Instantly sync to Mac Reminders!
      syncEngine.pushTaskToReminders(createdTask).catch(e => console.error('[AI push task error]:', e));
    }

    // 2. LLM Website Project Updates if not already applied
    if (result.intent === 'update_website_project' && result.websiteId && result.updates && !affectedProject) {
      try {
        affectedProject = websiteService.updateWebsite(result.websiteId, result.updates);
      } catch (err) {
        console.error('[Apply LLM update error]:', err);
      }
    }

    // 3. LLM Website Project Creation if not already applied
    if (result.intent === 'create_website_project' && result.projectData && !affectedProject) {
      try {
        affectedProject = websiteService.createWebsite(result.projectData);
      } catch (err) {
        console.error('[Apply LLM create error]:', err);
      }
    }

    // Record assistant message
    db.prepare(`
      INSERT INTO ai_conversations (id, role, content, metadata, created_at)
      VALUES (?, 'assistant', ?, ?, ?)
    `).run(
      crypto.randomUUID(),
      result.reply,
      JSON.stringify({ task: createdTask, project: affectedProject, intent: result.intent }),
      now
    );

    res.json({
      success: true,
      reply: result.reply,
      task: createdTask,
      project: affectedProject,
      intent: result.intent
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/ai/history', (req, res) => {
  try {
    const history = db.prepare(`
      SELECT * FROM ai_conversations
      ORDER BY created_at ASC
      LIMIT 100
    `).all();
    res.json({ success: true, data: history });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/ai/history', (req, res) => {
  try {
    db.prepare(`DELETE FROM ai_conversations`).run();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ----------------- SYNC API -----------------
app.get('/api/sync/status', async (req, res) => {
  try {
    const listName = syncEngine.getTargetListName();
    const unsyncedCount = db.prepare(`SELECT count(*) as count FROM tasks WHERE apple_reminder_id IS NULL`).get().count;
    const totalCount = db.prepare(`SELECT count(*) as count FROM tasks`).get().count;
    const lastLog = db.prepare(`SELECT * FROM sync_logs ORDER BY created_at DESC LIMIT 1`).get();
    res.json({
      success: true,
      data: {
        targetList: listName,
        unsyncedCount,
        totalCount,
        lastSync: lastLog ? lastLog.created_at : null
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/sync/now', async (req, res) => {
  try {
    const result = await syncEngine.syncAll();
    res.json({ success: true, result });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/sync/logs', (req, res) => {
  try {
    const logs = db.prepare(`
      SELECT * FROM sync_logs
      ORDER BY created_at DESC
      LIMIT 50
    `).all();
    res.json({ success: true, data: logs });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ----------------- REMINDERS & SETTINGS API -----------------
app.get('/api/reminders/lists', async (req, res) => {
  try {
    const lists = await remindersService.getLists();
    res.json({ success: true, data: lists });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/settings', (req, res) => {
  try {
    const rows = db.prepare(`SELECT key, value FROM settings`).all();
    const settings = {};
    for (const r of rows) settings[r.key] = r.value;
    res.json({ success: true, data: settings });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/settings', (req, res) => {
  try {
    const updates = req.body;
    const updateStmt = db.prepare(`INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)`);
    for (const [k, v] of Object.entries(updates)) {
      updateStmt.run(k, String(v));
    }
    // Restart background sync interval if modified
    syncEngine.startBackgroundSync();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ----------------- CLIENT WEBSITES ARCHIVE API -----------------
// Available Services Catalog API
app.get('/api/website-services', (req, res) => {
  try {
    const list = websiteService.getAvailableServices();
    res.json({ success: true, data: list });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/website-services', (req, res) => {
  try {
    const { name } = req.body;
    const list = websiteService.addAvailableService(name);
    res.json({ success: true, data: list });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/website-services/:name', (req, res) => {
  try {
    const { name } = req.params;
    const list = websiteService.removeAvailableService(decodeURIComponent(name));
    res.json({ success: true, data: list });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/websites', (req, res) => {
  try {
    const { status, search } = req.query;
    const websites = websiteService.getAllWebsites(status, search);
    res.json({ success: true, data: websites });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.get('/api/websites/:id', (req, res) => {
  try {
    const { id } = req.params;
    const website = websiteService.getWebsiteById(id);
    if (!website) {
      return res.status(404).json({ success: false, error: '未找到该网站项目' });
    }
    res.json({ success: true, data: website });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/websites/scan', async (req, res) => {
  try {
    const { baseDir } = req.body || {};
    const list = await websiteService.scanDirectory(baseDir);
    res.json({ success: true, data: list });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.put('/api/websites/:id', (req, res) => {
  try {
    const { id } = req.params;
    const updated = websiteService.updateWebsite(id, req.body);
    res.json({ success: true, data: updated });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Follow-ups API
app.post('/api/websites/:id/follow-ups', (req, res) => {
  try {
    const { id } = req.params;
    const { content, type } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, error: '跟进内容不能为空' });
    }
    const item = websiteService.addFollowUp(id, content, type);
    res.json({ success: true, data: item });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.delete('/api/websites/follow-ups/:followUpId', (req, res) => {
  try {
    const { followUpId } = req.params;
    const result = websiteService.deleteFollowUp(followUpId);
    res.json({ success: true, data: result });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/websites/open-local', async (req, res) => {
  try {
    const { path: localPath } = req.body;
    if (!localPath) {
      return res.status(400).json({ success: false, error: '缺少本地路径' });
    }
    await websiteService.openInFinder(localPath);
    res.json({ success: true, message: '已在访达中打开' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.post('/api/websites/open-editor', async (req, res) => {
  try {
    const { path: localPath } = req.body;
    if (!localPath) {
      return res.status(400).json({ success: false, error: '缺少本地路径' });
    }
    const result = await websiteService.openInEditor(localPath);
    res.json({ success: true, result });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

import fs from 'fs';

// Fallback to React index.html for SPA routing
app.use((req, res, next) => {
  if (req.method === 'GET' && !req.path.startsWith('/api')) {
    const indexPath = path.join(clientDistPath, 'index.html');
    if (fs.existsSync(indexPath)) {
      return res.sendFile(indexPath);
    }
  }
  next();
});

// Start Express and background sync
app.listen(PORT, () => {
  console.log(`🚀 SmartPlan Hub Server running on http://localhost:${PORT}`);
  syncEngine.startBackgroundSync();
  // Automatically scan client website projects on startup
  websiteService.scanDirectory().catch(e => console.error('[Initial Website Scan Error]:', e));
});
