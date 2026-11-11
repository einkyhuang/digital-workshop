/**
 * 日程日文件（超级工作台应用/data/schedule/YYYY-MM-DD.json）的纯逻辑。
 * 浏览器、MagicHub、Node 测试共用。不要在这里 import node:fs。
 */

export const HOME_PAST_DAYS = 14;
export const HOME_FUTURE_DAYS = 120;

export function isDayKey(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value);
}

export function dayKeyFromName(name) {
  const m = /^(\d{4}-\d{2}-\d{2})\.json$/.exec(String(name || ""));
  return m ? m[1] : "";
}

export function shanghaiYMD(date = new Date()) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(date);
}

export function shanghaiStamp(date = new Date()) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const g = (type) => {
    const hit = parts.find((p) => p.type === type);
    return hit ? hit.value : "00";
  };
  return `${g("year")}-${g("month")}-${g("day")}T${g("hour")}:${g("minute")}:${g("second")}+08:00`;
}

export function addDaysYMD(ymd, delta) {
  if (!isDayKey(ymd) || !Number.isInteger(delta)) return "";
  const [y, m, d] = ymd.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + delta));
  const yy = dt.getUTCFullYear();
  const mm = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(dt.getUTCDate()).padStart(2, "0");
  return `${yy}-${mm}-${dd}`;
}

/** 今天（含已完成）到未来 HOME_FUTURE_DAYS，以及近 HOME_PAST_DAYS 里仍未完成的任务。 */
export function taskBelongsOnHomeBoard(fileDate, status, today) {
  if (!isDayKey(fileDate) || !isDayKey(today)) return false;
  const end = addDaysYMD(today, HOME_FUTURE_DAYS);
  if (fileDate >= today && fileDate <= end) return true;
  if (status !== "完成") {
    const start = addDaysYMD(today, -HOME_PAST_DAYS);
    if (fileDate >= start && fileDate < today) return true;
  }
  return false;
}

export function localProbeDates(today) {
  const out = [];
  for (let i = -HOME_PAST_DAYS; i <= HOME_FUTURE_DAYS; i++) {
    const d = addDaysYMD(today, i);
    if (d) out.push(d);
  }
  return out;
}

export function monthDates(ym) {
  if (!/^\d{4}-\d{2}$/.test(ym || "")) return [];
  const [y, m] = ym.split("-").map(Number);
  const n = new Date(Date.UTC(y, m, 0)).getUTCDate();
  const out = [];
  for (let d = 1; d <= n; d++) out.push(`${ym}-${String(d).padStart(2, "0")}`);
  return out;
}

export function datesForMonth(ym, indexDates, hosted) {
  const listed = (indexDates || []).filter((d) => isDayKey(d) && d.startsWith(`${ym}-`));
  if (hosted) return listed;
  const set = new Set(monthDates(ym));
  for (const d of listed) set.add(d);
  return [...set].sort();
}

export function datesForHome(today, indexDates, hosted) {
  const set = new Set();
  for (const d of indexDates || []) {
    if (taskBelongsOnHomeBoard(d, "待办", today)) set.add(d);
  }
  if (!hosted) {
    for (const d of localProbeDates(today)) set.add(d);
  }
  return [...set].sort();
}

export function fetchBases(hosted) {
  if (hosted) return ["./data/schedule/"];
  return ["../../data/schedule/", "../data/schedule/", "./data/schedule/"];
}

export function homeBoardScheduleTasks(docs, today) {
  const list = Array.isArray(docs) ? docs : Object.values(docs || {});
  const out = [];
  for (const doc of list) {
    if (!doc || typeof doc !== "object") continue;
    const fileDate = isDayKey(doc.date) ? doc.date : "";
    if (!fileDate) continue;
    for (const t of doc.tasks || []) {
      if (!t || typeof t !== "object" || typeof t.id !== "string" || !t.id || !t.title) continue;
      const status = t.status || "待办";
      if (!taskBelongsOnHomeBoard(fileDate, status, today)) continue;
      out.push({
        id: t.id,
        title: t.title,
        status,
        date: fileDate,
        ownerName: t.ownerName || "",
        ownerBotId: t.ownerBotId || "",
        note: t.note || "",
        dueAt: t.dueAt || "",
        source: "schedule",
      });
    }
  }
  out.sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : String(a.title).localeCompare(String(b.title), "zh")));
  return out;
}

export function calendarEntries(doc) {
  if (!doc || typeof doc !== "object") return [];
  const date = isDayKey(doc.date) ? doc.date : "";
  const out = [];
  for (const t of doc.tasks || []) {
    if (!t || typeof t !== "object" || typeof t.id !== "string" || !t.id) continue;
    const status = t.status || "待办";
    out.push({
      kind: "task",
      id: t.id,
      date,
      title: t.title || "",
      status,
      done: status === "完成",
      owner: t.ownerName || t.ownerBotId || "",
      note: t.note || "",
      dueAt: t.dueAt || "",
      icon: status === "完成" ? "✅" : "📋",
    });
  }
  for (const s of doc.schedule || []) {
    if (!s || typeof s !== "object") continue;
    out.push({
      kind: "block",
      id: typeof s.id === "string" ? s.id : "",
      date,
      title: s.title || "",
      status: "",
      done: false,
      owner: s.who || "",
      note: [s.kind, s.startAt, s.endAt].filter(Boolean).join(" · "),
      dueAt: s.startAt || "",
      icon: "🗓",
    });
  }
  return out;
}

/**
 * 只改命中任务的 status，以及文件顶层 updatedAt。
 * 不改其它任务、schedule、meta 和未知字段。未命中时不返回新文档。
 */
export function applyTaskStatus(doc, taskId, done, updatedAt) {
  if (!doc || typeof doc !== "object" || Array.isArray(doc)) return { ok: false, reason: "bad-doc" };
  if (typeof taskId !== "string" || !taskId || taskId.length > 200 || /[/\\]/.test(taskId) || taskId.includes("..")) {
    return { ok: false, reason: "bad-id" };
  }
  if (!Array.isArray(doc.tasks)) return { ok: false, reason: "no-tasks" };
  let hit = 0;
  const tasks = doc.tasks.map((t) => {
    if (!t || typeof t !== "object" || t.id !== taskId) return t;
    hit += 1;
    return { ...t, status: done ? "完成" : "待办" };
  });
  if (!hit) return { ok: false, reason: "missing-task" };
  return { ok: true, doc: { ...doc, tasks, updatedAt } };
}

export async function loadScheduleMap({ fetchImpl, bases, dates }) {
  const byDate = {};
  await Promise.all((dates || []).map(async (date) => {
    if (!isDayKey(date)) return;
    for (const base of bases || []) {
      try {
        const res = await fetchImpl(String(base) + date + ".json");
        if (!res || !res.ok) continue;
        const doc = await res.json();
        if (!doc || typeof doc !== "object" || Array.isArray(doc)) continue;
        if (!isDayKey(doc.date)) doc.date = date;
        byDate[doc.date] = doc;
        return;
      } catch (_) {}
    }
  }));
  return byDate;
}

const api = {
  HOME_PAST_DAYS,
  HOME_FUTURE_DAYS,
  isDayKey,
  dayKeyFromName,
  shanghaiYMD,
  shanghaiStamp,
  addDaysYMD,
  taskBelongsOnHomeBoard,
  localProbeDates,
  monthDates,
  datesForMonth,
  datesForHome,
  fetchBases,
  homeBoardScheduleTasks,
  calendarEntries,
  applyTaskStatus,
  loadScheduleMap,
};

globalThis.ScheduleBoard = api;
