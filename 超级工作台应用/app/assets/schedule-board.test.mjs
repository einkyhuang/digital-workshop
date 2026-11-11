import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  applyTaskStatus,
  datesForHome,
  datesForMonth,
  dayKeyFromName,
  fetchBases,
  homeBoardScheduleTasks,
  loadScheduleMap,
  localProbeDates,
  shanghaiStamp,
  shanghaiYMD,
  taskBelongsOnHomeBoard,
} from "./schedule-board.mjs";
import { listDayDocs, setTaskStatusOnDisk } from "./schedule-board-fs.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "../../..");
const today = "2026-11-11";

test("shanghai date rolls at UTC+8", () => {
  assert.equal(shanghaiYMD(new Date("2026-11-11T15:30:00Z")), "2026-11-11");
  assert.equal(shanghaiYMD(new Date("2026-11-11T16:30:00Z")), "2026-11-12");
  assert.equal(shanghaiStamp(new Date("2026-11-11T16:00:00Z")), "2026-11-12T00:00:00+08:00");
});

test("home board shows today and upcoming, keeps recent open tasks", () => {
  assert.equal(taskBelongsOnHomeBoard("2026-11-11", "完成", today), true);
  assert.equal(taskBelongsOnHomeBoard("2026-11-12", "待办", today), true);
  assert.equal(taskBelongsOnHomeBoard("2027-03-11", "待办", today), true);
  assert.equal(taskBelongsOnHomeBoard("2027-03-12", "待办", today), false);
  assert.equal(taskBelongsOnHomeBoard("2026-10-28", "待办", today), true);
  assert.equal(taskBelongsOnHomeBoard("2026-10-27", "待办", today), false);
  assert.equal(taskBelongsOnHomeBoard("2026-10-28", "完成", today), false);
  assert.equal(localProbeDates(today).length, 14 + 1 + 120);
});

test("hosted pages use the month index only", () => {
  const hosted = datesForHome(today, ["2026-11-12", "2026-10-01"], true);
  assert.deepEqual(hosted, ["2026-11-12"]);
  assert.deepEqual(fetchBases(true), ["./data/schedule/"]);
  const localMonth = datesForMonth("2026-11", ["2026-11-12"], false);
  assert.equal(localMonth.length, 30);
  assert.ok(localMonth.includes("2026-11-12"));
  assert.deepEqual(datesForMonth("2026-11", ["2026-11-12", "2026-10-30"], true), ["2026-11-12"]);
});

test("day filenames ignore the monthly index", () => {
  assert.equal(dayKeyFromName("2026-11-12.json"), "2026-11-12");
  assert.equal(dayKeyFromName("2026-11.index.json"), "");
  assert.equal(dayKeyFromName("README.md"), "");
});

test("applyTaskStatus keeps other bots' fields and only flips one task", () => {
  const original = {
    version: 1,
    date: "2026-11-12",
    timezone: "Asia/Shanghai",
    updatedAt: "2026-11-12T02:08:00+08:00",
    customFlag: { keep: true },
    tasks: [
      { id: "t-a", title: "甲", status: "进行中", note: "留着", lane: "bot-a", ownerName: "甲" },
      { id: "t-b", title: "乙", status: "待办", note: "别人的", extra: 7 },
    ],
    schedule: [{ id: "s-1", title: "会", kind: "meeting", room: "A" }],
    meta: { hasEmailSummary: false, emailSource: "secret-path" },
  };
  const applied = applyTaskStatus(original, "t-a", true, "2026-11-12T10:00:00+08:00");
  assert.equal(applied.ok, true);
  assert.equal(original.tasks[0].status, "进行中");
  assert.equal(original.updatedAt, "2026-11-12T02:08:00+08:00");
  assert.equal(applied.doc.tasks[0].status, "完成");
  assert.equal(applied.doc.tasks[0].note, "留着");
  assert.equal(applied.doc.tasks[0].lane, "bot-a");
  assert.equal(applied.doc.tasks[1].status, "待办");
  assert.equal(applied.doc.tasks[1].extra, 7);
  assert.equal(applied.doc.tasks[1], original.tasks[1]);
  assert.deepEqual(applied.doc.schedule, original.schedule);
  assert.equal(applied.doc.schedule[0], original.schedule[0]);
  assert.equal(applied.doc.meta, original.meta);
  assert.deepEqual(applied.doc.customFlag, { keep: true });
  assert.equal(applied.doc.version, 1);
  assert.equal(applied.doc.updatedAt, "2026-11-12T10:00:00+08:00");
  const back = applyTaskStatus(applied.doc, "t-a", false, "2026-11-12T11:00:00+08:00");
  assert.equal(back.doc.tasks[0].status, "待办");
  assert.equal(back.doc.tasks[0].lane, "bot-a");
  assert.equal(applyTaskStatus(original, "missing", true, "x").ok, false);
  assert.equal(applyTaskStatus(original, "../t", true, "x").reason, "bad-id");
});

test("home board reads a day file without code changes for that date", () => {
  const docs = {
    "2026-10-01": {
      date: "2026-10-01",
      tasks: [{ id: "old", title: "旧的完成", status: "完成" }, { id: "old-open", title: "太早的待办", status: "待办" }],
    },
    "2026-11-12": {
      date: "2026-11-12",
      tasks: [
        { id: "t-1", title: "明天甲", status: "待办", ownerName: "花生" },
        { id: "t-2", title: "明天乙", status: "待办" },
      ],
      schedule: [{ id: "s", title: "不是任务" }],
    },
  };
  const shown = homeBoardScheduleTasks(docs, today);
  assert.deepEqual(shown.map((t) => t.id), ["t-1", "t-2"]);
  assert.equal(shown[0].date, "2026-11-12");
  assert.equal(shown[0].ownerName, "花生");
});

test("loadScheduleMap prefers the first base that has the file", async () => {
  const calls = [];
  const byDate = await loadScheduleMap({
    bases: ["../../data/schedule/", "./data/schedule/"],
    dates: ["2026-11-12"],
    fetchImpl: async (url) => {
      calls.push(url);
      if (url.startsWith("../../")) {
        return { ok: true, json: async () => ({ date: "2026-11-12", tasks: [{ id: "live", title: "本地", status: "待办" }] }) };
      }
      return { ok: true, json: async () => ({ date: "2026-11-12", tasks: [{ id: "mirror", title: "镜像", status: "完成" }] }) };
    },
  });
  assert.equal(byDate["2026-11-12"].tasks[0].id, "live");
  assert.deepEqual(calls, ["../../data/schedule/2026-11-12.json"]);
});

test("atomic write updates one task and leaves the other bot's entry", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "sw-schedule-"));
  const mirror = fs.mkdtempSync(path.join(os.tmpdir(), "sw-schedule-mirror-"));
  const original = {
    version: 1,
    date: "2026-11-12",
    timezone: "Asia/Shanghai",
    updatedAt: "2026-11-12T02:08:00+08:00",
    tasks: [
      { id: "t-1", title: "甲", status: "待办", note: "甲的备注", ownerBotId: "user" },
      { id: "t-2", title: "乙", status: "进行中", note: "乙的备注", ownerBotId: "other-bot", scratch: { n: 1 } },
    ],
    schedule: [],
    meta: { hasDailyReport: false, dailyReportSource: "bots/管理中枢/总结助手/deliverables/日报-2026-11-12.md" },
  };
  fs.writeFileSync(path.join(dir, "2026-11-12.json"), JSON.stringify(original, null, 2));
  fs.writeFileSync(path.join(dir, "2026-11.index.json"), JSON.stringify({ month: "2026-11", dates: ["2026-11-12"] }));
  fs.writeFileSync(path.join(mirror, "2026-11-12.json"), JSON.stringify(original));
  const outside = path.join(dir, "..", "nope.json");

  const doc = setTaskStatusOnDisk(dir, "2026-11-12", "t-1", true, new Date("2026-11-11T02:00:00Z"), mirror);
  assert.equal(doc.tasks[0].status, "完成");
  assert.equal(doc.tasks[1].status, "进行中");
  assert.deepEqual(doc.tasks[1].scratch, { n: 1 });
  assert.equal(doc.meta.dailyReportSource, original.meta.dailyReportSource);
  assert.equal(doc.updatedAt, "2026-11-11T10:00:00+08:00");

  const reread = JSON.parse(fs.readFileSync(path.join(dir, "2026-11-12.json"), "utf8"));
  assert.equal(reread.tasks[0].note, "甲的备注");
  assert.equal(reread.tasks[1].ownerBotId, "other-bot");
  assert.equal(JSON.parse(fs.readFileSync(path.join(mirror, "2026-11-12.json"), "utf8")).tasks[0].status, "完成");
  assert.equal(fs.readFileSync(path.join(dir, "2026-11.index.json"), "utf8").includes("2026-11-12"), true);
  assert.equal(fs.readdirSync(dir).some((name) => name.endsWith(".tmp")), false);
  assert.deepEqual(listDayDocs(dir).map((d) => d.date), ["2026-11-12"]);

  const untouched = fs.readFileSync(path.join(dir, "2026-11-12.json"), "utf8");
  assert.throws(() => setTaskStatusOnDisk(dir, "2026-11-12", "missing", true), /missing-task/);
  assert.equal(fs.readFileSync(path.join(dir, "2026-11-12.json"), "utf8"), untouched);
  assert.throws(() => setTaskStatusOnDisk(dir, "../evil", "t-1", true));
  assert.equal(fs.existsSync(outside), false);
  assert.throws(() => setTaskStatusOnDisk(dir, "2026-11-13", "t-1", true), /missing file/);
  assert.equal(fs.existsSync(path.join(dir, "2026-11-13.json")), false);

  const undone = setTaskStatusOnDisk(dir, "2026-11-12", "t-1", false, new Date("2026-11-11T03:00:00Z"));
  assert.equal(undone.tasks[0].status, "待办");
  assert.equal(undone.tasks[1].scratch.n, 1);
});

test("committed 2026-11-12 file is upcoming on 2026-11-11", () => {
  const file = path.join(repoRoot, "超级工作台应用/data/schedule/2026-11-12.json");
  const doc = JSON.parse(fs.readFileSync(file, "utf8"));
  assert.equal(doc.date, "2026-11-12");
  assert.ok(Array.isArray(doc.tasks) && doc.tasks.length >= 5);
  const shown = homeBoardScheduleTasks({ [doc.date]: doc }, today);
  assert.equal(shown.length, doc.tasks.length);
  assert.ok(shown.every((t) => t.date === "2026-11-12" && t.source === "schedule"));
});
