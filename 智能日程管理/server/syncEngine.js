import db from './db.js';
import { remindersService } from './remindersService.js';
import { aiService } from './aiService.js';
import crypto from 'crypto';

let isSyncing = false;
let syncTimer = null;

export const syncEngine = {
  /**
   * Start auto sync background interval
   */
  startBackgroundSync() {
    this.stopBackgroundSync();
    const intervalSetting = db.prepare(`SELECT value FROM settings WHERE key = 'auto_sync_interval'`).get();
    const enabledSetting = db.prepare(`SELECT value FROM settings WHERE key = 'auto_sync_enabled'`).get();

    if (enabledSetting && enabledSetting.value === 'false') {
      console.log('[Sync Engine]: Auto sync disabled.');
      return;
    }

    const intervalSec = parseInt(intervalSetting?.value || '20', 10);
    console.log(`[Sync Engine]: Starting auto sync every ${intervalSec}s...`);

    syncTimer = setInterval(async () => {
      try {
        await this.syncAll();
      } catch (err) {
        console.error('[Sync Engine Background Error]:', err.message);
      }
    }, intervalSec * 1000);
  },

  /**
   * Stop background sync
   */
  stopBackgroundSync() {
    if (syncTimer) {
      clearInterval(syncTimer);
      syncTimer = null;
    }
  },

  /**
   * Get target reminder list name from settings
   */
  getTargetListName() {
    const row = db.prepare(`SELECT value FROM settings WHERE key = 'reminder_list_name'`).get();
    return row?.value || 'AI 智能日程';
  },

  /**
   * Full bi-directional sync cycle
   */
  async syncAll() {
    if (isSyncing) return { status: 'busy' };
    isSyncing = true;
    const listName = this.getTargetListName();
    const now = new Date().toISOString();
    let stats = { fromReminders: 0, toReminders: 0, statusUpdates: 0 };

    try {
      // 1. Fetch all reminders from macOS Reminders
      const macReminders = await remindersService.getReminders(listName);

      // Map existing DB tasks by apple_reminder_id
      const allDbTasks = db.prepare(`SELECT * FROM tasks`).all();
      const dbTaskByReminderId = new Map();
      const dbTaskById = new Map();

      for (const t of allDbTasks) {
        dbTaskById.set(t.id, t);
        if (t.apple_reminder_id) {
          dbTaskByReminderId.set(t.apple_reminder_id, t);
        }
      }

      // --- PHASE 1: REVERSE SYNC (Mac Reminders -> Local Kanban) ---
      for (const r of macReminders) {
        if (!r.id) continue;

        const existingTask = dbTaskByReminderId.get(r.id);

        if (!existingTask) {
          // New reminder found in macOS Reminders! Auto classify and create in Kanban!
          console.log(`[Sync Engine]: New macOS reminder detected: "${r.name}". AI classifying...`);

          const classification = await aiService.classifyExternalReminder(r.name, r.body);

          // Parse date if rawDate exists
          let dueDate = null;
          let dueTime = null;
          if (r.rawDate) {
            // e.g. "2026年10月12日 星期一 15:00:00" or similar
            const m = r.rawDate.match(/(\d{4})[年/-](\d{1,2})[月/-](\d{1,2})/);
            if (m) {
              dueDate = `${m[1]}-${String(m[2]).padStart(2, '0')}-${String(m[3]).padStart(2, '0')}`;
            }
            const tm = r.rawDate.match(/(\d{1,2}):(\d{1,2})/);
            if (tm) {
              dueTime = `${String(tm[1]).padStart(2, '0')}:${String(tm[2]).padStart(2, '0')}`;
            }
          }

          const newTaskId = crypto.randomUUID();
          const taskStatus = r.completed ? 'done' : 'todo';

          db.prepare(`
            INSERT INTO tasks (
              id, title, description, status, priority, due_date, due_time,
              project_id, apple_reminder_id, sync_status, last_synced_at, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'synced', ?, ?, ?)
          `).run(
            newTaskId,
            r.name,
            r.body || '来自 Mac 提醒事项自动识别归档',
            taskStatus,
            classification.priority || 'medium',
            dueDate,
            dueTime,
            classification.projectId,
            r.id,
            now,
            now,
            now
          );

          db.prepare(`
            INSERT INTO sync_logs (id, direction, action, item_name, project_name, details, status, created_at)
            VALUES (?, 'from_reminders', 'created', ?, ?, ?, 'success', ?)
          `).run(
            crypto.randomUUID(),
            r.name,
            classification.projectName,
            `自动识别并归档到看板 [${classification.projectName}]`,
            now
          );

          stats.fromReminders++;
        } else {
          // Existing task: Check completion status synchronization
          const isDoneInDb = existingTask.status === 'done' || existingTask.status === 'archived';
          if (r.completed && !isDoneInDb) {
            // Mark DB task done
            db.prepare(`UPDATE tasks SET status = 'done', updated_at = ? WHERE id = ?`).run(now, existingTask.id);
            stats.statusUpdates++;

            db.prepare(`
              INSERT INTO sync_logs (id, direction, action, item_name, project_name, details, status, created_at)
              VALUES (?, 'from_reminders', 'completed', ?, '', 'Mac 提醒事项勾选完成，同步更新看板状态', 'success', ?)
            `).run(crypto.randomUUID(), existingTask.title, now);
          } else if (!r.completed && isDoneInDb) {
            // Completed in DB but uncompleted in reminders, or vice versa
            // Keep DB priority or sync status
          }
        }
      }

      // --- PHASE 2: OUTBOUND SYNC (Local Kanban -> Mac Reminders) ---
      // Check for pending unsynced tasks created locally
      const pendingTasks = db.prepare(`SELECT * FROM tasks WHERE apple_reminder_id IS NULL`).all();
      for (const t of pendingTasks) {
        try {
          const reminderId = await remindersService.createReminder(listName, t);
          db.prepare(`
            UPDATE tasks SET apple_reminder_id = ?, sync_status = 'synced', last_synced_at = ? WHERE id = ?
          `).run(reminderId, now, t.id);

          stats.toReminders++;
          db.prepare(`
            INSERT INTO sync_logs (id, direction, action, item_name, project_name, details, status, created_at)
            VALUES (?, 'to_reminders', 'created', ?, '', '本地看板新建日程，已成功同步至 Mac 提醒事项', 'success', ?)
          `).run(crypto.randomUUID(), t.title, now);
        } catch (e) {
          console.error(`[Sync Engine]: Failed to push task "${t.title}" to Reminders:`, e.message);
          db.prepare(`UPDATE tasks SET sync_status = 'error' WHERE id = ?`).run(t.id);
        }
      }

      return { success: true, stats };
    } catch (err) {
      console.error('[Sync Engine Run Error]:', err.message);
      return { success: false, error: err.message };
    } finally {
      isSyncing = false;
    }
  },

  /**
   * Push single task immediately to macOS Reminders
   */
  async pushTaskToReminders(task) {
    const listName = this.getTargetListName();
    const now = new Date().toISOString();
    try {
      if (task.apple_reminder_id) {
        // Update completion
        const completed = task.status === 'done' || task.status === 'archived';
        await remindersService.updateReminderStatus(listName, task.apple_reminder_id, completed);
      } else {
        const reminderId = await remindersService.createReminder(listName, task);
        db.prepare(`
          UPDATE tasks SET apple_reminder_id = ?, sync_status = 'synced', last_synced_at = ? WHERE id = ?
        `).run(reminderId, now, task.id);
      }
    } catch (e) {
      console.warn('[pushTaskToReminders error]:', e.message);
    }
  }
};
