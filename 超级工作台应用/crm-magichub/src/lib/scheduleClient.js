import { reactive } from 'vue';
import {
  calendarEntries,
  datesForHome,
  fetchBases,
  homeBoardScheduleTasks,
  isDayKey,
  loadScheduleMap,
  shanghaiStamp,
  shanghaiYMD,
} from '../../../app/assets/schedule-board.mjs';

export const scheduleState = reactive({
  byDate: {},
  ready: false,
  error: '',
});

let refreshPromise = null;
let writes = 0;
const tails = new Map();

function hostedPage() {
  try {
    const host = location.hostname || '';
    return host.endsWith('github.io') || host.endsWith('pages.dev');
  } catch (_) {
    return false;
  }
}

async function loadIndexes(bases) {
  const today = shanghaiYMD(new Date());
  const months = new Set();
  months.add(today.slice(0, 7));
  for (let i = 1; i <= 4; i++) {
    const shifted = new Date();
    shifted.setMonth(shifted.getMonth() + i);
    months.add(shanghaiYMD(shifted).slice(0, 7));
  }
  const dates = [];
  for (const ym of months) {
    for (const base of bases) {
      try {
        const res = await fetch(`${base}${ym}.index.json`, { cache: 'no-store' });
        if (!res.ok) continue;
        const idx = await res.json();
        for (const d of idx.dates || []) dates.push(d);
        break;
      } catch (_) {}
    }
  }
  return dates;
}

export async function refreshSchedule() {
  if (writes > 0) return scheduleState.byDate;
  if (refreshPromise) return refreshPromise;
  refreshPromise = (async () => {
    try {
      const api = window.electronAPI;
      if (api?.listScheduleDocs) {
        const res = await api.listScheduleDocs();
        if (res?.success && Array.isArray(res.docs)) {
          const byDate = {};
          for (const doc of res.docs) {
            if (doc && isDayKey(doc.date)) byDate[doc.date] = doc;
          }
          scheduleState.byDate = byDate;
          scheduleState.ready = true;
          scheduleState.error = '';
          return byDate;
        }
      }
      const today = shanghaiYMD(new Date());
      const bases = fetchBases(hostedPage());
      const indexDates = await loadIndexes(bases);
      const dates = datesForHome(today, indexDates, hostedPage());
      const byDate = await loadScheduleMap({
        fetchImpl: (url) => fetch(url, { cache: 'no-store' }),
        bases,
        dates,
      });
      scheduleState.byDate = byDate;
      scheduleState.ready = true;
      scheduleState.error = '';
      return byDate;
    } catch (e) {
      scheduleState.error = e?.message || '日程读取失败';
      return scheduleState.byDate;
    } finally {
      refreshPromise = null;
    }
  })();
  return refreshPromise;
}

export function scheduleHomeTasks(now = new Date()) {
  return homeBoardScheduleTasks(scheduleState.byDate, shanghaiYMD(now));
}

export function scheduleEntries(date) {
  const doc = scheduleState.byDate[date];
  return doc ? calendarEntries(doc) : [];
}

export function toggleScheduleTask(date, taskId, done) {
  const prevTail = tails.get(date) || Promise.resolve();
  const next = prevTail.then(() => writeOne(date, taskId, done));
  tails.set(date, next.catch(() => {}));
  return next;
}

async function writeOne(date, taskId, done) {
  const prev = scheduleState.byDate[date];
  const applied = applyOptimistic(prev, taskId, done);
  if (!applied.ok) {
    scheduleState.error = '找不到这条日程';
    return applied;
  }
  writes += 1;
  scheduleState.byDate = { ...scheduleState.byDate, [date]: applied.doc };
  try {
    const api = window.electronAPI;
    if (!api?.setScheduleTaskStatus) {
      scheduleState.error = '当前环境不能写回本地日程文件，请用 Mac 超级工作台勾选';
      if (prev) scheduleState.byDate = { ...scheduleState.byDate, [date]: prev };
      return { ok: false, reason: 'no-writer' };
    }
    const res = await api.setScheduleTaskStatus(date, taskId, !!done);
    if (!res?.success) throw new Error(res?.error || 'write failed');
    if (res.doc && isDayKey(res.doc.date)) {
      scheduleState.byDate = { ...scheduleState.byDate, [res.doc.date]: res.doc };
    }
    scheduleState.error = '';
    return { ok: true, doc: res.doc || applied.doc };
  } catch (e) {
    if (prev) scheduleState.byDate = { ...scheduleState.byDate, [date]: prev };
    scheduleState.error = e?.message || '写回失败';
    return { ok: false, reason: 'write' };
  } finally {
    writes -= 1;
  }
}

function applyOptimistic(doc, taskId, done) {
  if (!doc) return { ok: false };
  const tasks = Array.isArray(doc.tasks) ? doc.tasks : null;
  if (!tasks || !tasks.some((t) => t && t.id === taskId)) return { ok: false };
  return {
    ok: true,
    doc: {
      ...doc,
      updatedAt: shanghaiStamp(new Date()),
      tasks: tasks.map((t) => (t && t.id === taskId ? { ...t, status: done ? '完成' : '待办' } : t)),
    },
  };
}
