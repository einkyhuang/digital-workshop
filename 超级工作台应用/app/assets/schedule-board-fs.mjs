/**
 * 把日程任务状态原子写回 YYYY-MM-DD.json。仅 Node / Electron 主进程使用。
 */
import fs from "node:fs";
import path from "node:path";
import { applyTaskStatus, dayKeyFromName, isDayKey, shanghaiStamp } from "./schedule-board.mjs";

function dayFile(dir, date) {
  if (!isDayKey(date)) throw new Error("bad date");
  const root = path.resolve(dir);
  const file = path.resolve(root, `${date}.json`);
  const rel = path.relative(root, file);
  if (!rel || rel.startsWith("..") || path.isAbsolute(rel)) throw new Error("path escapes schedule dir");
  return file;
}

export function listDayDocs(dir) {
  if (!dir || !fs.existsSync(dir)) return [];
  const out = [];
  for (const name of fs.readdirSync(dir)) {
    const date = dayKeyFromName(name);
    if (!date) continue;
    try {
      const doc = JSON.parse(fs.readFileSync(path.join(dir, name), "utf8"));
      if (!doc || typeof doc !== "object" || Array.isArray(doc)) continue;
      if (!isDayKey(doc.date)) doc.date = date;
      out.push(doc);
    } catch (_) {}
  }
  return out;
}

export function writeJsonAtomic(filePath, doc) {
  const text = `${JSON.stringify(doc, null, 2)}\n`;
  const tmp = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  fs.writeFileSync(tmp, text);
  fs.renameSync(tmp, filePath);
}

export function setTaskStatusOnDisk(dir, date, taskId, done, now = new Date(), mirrorDir = "") {
  const file = dayFile(dir, date);
  if (!fs.existsSync(file)) throw new Error("missing file");
  const before = fs.readFileSync(file, "utf8");
  const doc = JSON.parse(before);
  const applied = applyTaskStatus(doc, taskId, !!done, shanghaiStamp(now));
  if (!applied.ok) {
    const err = new Error(applied.reason);
    err.code = applied.reason;
    throw err;
  }
  writeJsonAtomic(file, applied.doc);
  if (mirrorDir) {
    const mirror = path.resolve(mirrorDir, `${date}.json`);
    if (fs.existsSync(mirror) && path.resolve(mirror) !== path.resolve(file)) {
      try {
        setTaskStatusOnDisk(mirrorDir, date, taskId, !!done, now, "");
      } catch (_) {}
    }
  }
  return applied.doc;
}
