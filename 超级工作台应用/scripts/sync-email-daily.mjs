#!/usr/bin/env node
/**
 * Aggregate bots/.../email-daily/*.json → public email-daily.json (redacted).
 * Full bodies stay only under bots/…/email-daily/ (Mac app reads there).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, "../..");
const SRC = path.join(REPO, "bots/外贸营销/超级邮件助手/deliverables/email-daily");
const OUT = path.join(REPO, "超级工作台应用/data/email-daily.json");
const OUT_APP = path.join(REPO, "超级工作台应用/app/data/email-daily.json");

function redactItem(j) {
  return {
    date: j.date,
    source: "信鸽-邮件助手（正文仅本地 bots/…/email-daily）",
    新邮件数: j["新邮件数"],
    已清理数: j["已清理数"],
    待回复数: j["待回复数"],
    清理分类: j["清理分类"],
    话题标签: j["话题标签"],
    重要邮件: [],
    meta: { hasEmailSummary: true, bodiesPrivate: true },
  };
}

function loadAll() {
  if (!fs.existsSync(SRC)) return [];
  const files = fs.readdirSync(SRC).filter((f) => f.endsWith(".json")).sort().reverse();
  const items = [];
  for (const f of files) {
    try {
      const j = JSON.parse(fs.readFileSync(path.join(SRC, f), "utf8"));
      if (j && j.date) items.push(redactItem(j));
    } catch (_) {}
  }
  items.sort((a, b) => String(b.date).localeCompare(String(a.date)));
  return items;
}

const items = loadAll();
const payload = {
  version: 1,
  updatedAt: new Date().toISOString(),
  count: items.length,
  privacy: "重要邮件正文已剥离；完整内容见 bots/外贸营销/超级邮件助手/deliverables/email-daily/",
  items,
};
const text = JSON.stringify(payload, null, 2) + "\n";
fs.writeFileSync(OUT, text);
fs.mkdirSync(path.dirname(OUT_APP), { recursive: true });
fs.writeFileSync(OUT_APP, text);
console.log(JSON.stringify({ ok: true, count: items.length, dates: items.map((x) => x.date), redacted: true }));
