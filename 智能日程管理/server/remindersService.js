import { execFile } from 'child_process';
import util from 'util';

const execFileAsync = util.promisify(execFile);

/**
 * Run AppleScript via osascript
 */
async function runAppleScript(script) {
  try {
    const { stdout, stderr } = await execFileAsync('osascript', ['-e', script], {
      timeout: 10000,
      maxBuffer: 1024 * 1024 * 5
    });
    if (stderr && stderr.trim().length > 0) {
      console.warn('[AppleScript Warn]:', stderr);
    }
    return stdout.trim();
  } catch (error) {
    console.error('[AppleScript Error]:', error.message);
    throw error;
  }
}

function escapeAppleScriptString(str) {
  if (!str) return '';
  return String(str)
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\r/g, '')
    .replace(/\n/g, '\\n');
}

/**
 * Format date for AppleScript
 * e.g. YYYY/MM/DD HH:mm:ss
 */
function formatDateForAppleScript(dueDate, dueTime) {
  if (!dueDate) return null;
  const parts = dueDate.split('-');
  if (parts.length !== 3) return null;
  const [year, month, day] = parts;
  const time = dueTime ? (dueTime.length === 5 ? `${dueTime}:00` : dueTime) : '09:00:00';
  return `${year}/${month}/${day} ${time}`;
}

export const remindersService = {
  /**
   * Get all reminder list names from macOS Reminders
   */
  async getLists() {
    const script = `
      tell application "Reminders"
        return name of lists
      end tell
    `;
    const res = await runAppleScript(script);
    if (!res) return [];
    return res.split(', ').map(s => s.trim());
  },

  /**
   * Ensure specific list exists
   */
  async ensureList(listName) {
    const safeName = escapeAppleScriptString(listName);
    const script = `
      tell application "Reminders"
        if not (exists list "${safeName}") then
          make new list with properties {name:"${safeName}"}
        end if
        return name of list "${safeName}"
      end tell
    `;
    return await runAppleScript(script);
  },

  /**
   * Get all reminders from a specific list
   */
  async getReminders(listName) {
    await this.ensureList(listName);
    const safeName = escapeAppleScriptString(listName);
    const script = `
      tell application "Reminders"
        if exists list "${safeName}" then
          tell list "${safeName}"
            set n to count of reminders
            if n is 0 then return ""
            set idList to id of reminders
            set nameList to name of reminders
            set compList to completed of reminders
            set bodyList to body of reminders
            set dateList to due date of reminders
            set res to ""
            repeat with i from 1 to n
              set rId to item i of idList
              set rName to item i of nameList
              set rComp to item i of compList
              set rBody to ""
              try
                set b to item i of bodyList
                if b is not missing value then set rBody to b
              end try
              set rDate to ""
              try
                set d to item i of dateList
                if d is not missing value then set rDate to d as string
              end try
              set res to res & rId & "|||" & rName & "|||" & (rComp as string) & "|||" & rDate & "|||" & rBody & "###---ITEM---###"
            end repeat
            return res
          end tell
        else
          return ""
        end if
      end tell
    `;

    const raw = await runAppleScript(script);
    if (!raw) return [];

    const items = raw.split('###---ITEM---###').filter(Boolean);
    return items.map(itemStr => {
      const [id, name, compStr, dateStr, ...rest] = itemStr.split('|||');
      const body = rest.join('|||');
      return {
        id: (id || '').trim(),
        name: (name || '').trim(),
        completed: (compStr || '').trim().toLowerCase() === 'true',
        rawDate: (dateStr || '').trim(),
        body: (body || '').trim()
      };
    });
  },

  /**
   * Create a new reminder in Reminders
   */
  async createReminder(listName, task) {
    await this.ensureList(listName);
    const safeList = escapeAppleScriptString(listName);
    const safeName = escapeAppleScriptString(task.title);
    const safeBody = escapeAppleScriptString(task.description || '');
    const formattedDate = formatDateForAppleScript(task.due_date, task.due_time);

    let script = '';
    if (formattedDate) {
      script = `
        tell application "Reminders"
          tell list "${safeList}"
            set newRem to make new reminder with properties {name:"${safeName}", body:"${safeBody}", due date:date "${formattedDate}"}
            return id of newRem
          end tell
        end tell
      `;
    } else {
      script = `
        tell application "Reminders"
          tell list "${safeList}"
            set newRem to make new reminder with properties {name:"${safeName}", body:"${safeBody}"}
            return id of newRem
          end tell
        end tell
      `;
    }

    const reminderId = await runAppleScript(script);
    return reminderId;
  },

  /**
   * Update existing reminder status or details
   */
  async updateReminderStatus(listName, reminderId, completed) {
    const safeList = escapeAppleScriptString(listName);
    const safeId = escapeAppleScriptString(reminderId);
    const boolStr = completed ? 'true' : 'false';

    const script = `
      tell application "Reminders"
        try
          tell list "${safeList}"
            set targetRem to (first reminder whose id is "${safeId}")
            set completed of targetRem to ${boolStr}
            return "ok"
          end tell
        on error errMsg
          return errMsg
        end try
      end tell
    `;
    return await runAppleScript(script);
  },

  /**
   * Delete reminder
   */
  async deleteReminder(listName, reminderId) {
    const safeList = escapeAppleScriptString(listName);
    const safeId = escapeAppleScriptString(reminderId);

    const script = `
      tell application "Reminders"
        try
          tell list "${safeList}"
            delete (first reminder whose id is "${safeId}")
            return "ok"
          end tell
        on error errMsg
          return errMsg
        end try
      end tell
    `;
    return await runAppleScript(script);
  }
};
