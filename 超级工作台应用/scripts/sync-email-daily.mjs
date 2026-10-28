#!/usr/bin/env node
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, "../..");
const SRC = path.join(REPO, "bots/外贸营销/超级邮件助手/deliverables/email-daily");
const OUT = path.join(REPO, "超级工作台应用/data/email-daily.json");
const OUT_APP = path.join(REPO, "超级工作台应用/app/data/email-daily.json");

function loadAll() {
  if (!fs.existsSync(SRC)) return [];
  const files = fs.readdirSync(SRC).filter((f) => f.endsWith(".json")).sort().reverse();
  const items = [];
  for (const f of files) {
    try {
      const j = JSON.parse(fs.readFileSync(path.join(SRC, f), "utf8"));
      if (j && j.date) items.push(j);
    } catch (_) {}
  }
  items.sort((a, b) => String(b.date).localeCompare(String(a.date)));
  return items;
}

const items = loadAll();
const payload = { version: 1, updatedAt: new Date().toISOString(), count: items.length, items };
const text = JSON.stringify(payload, null, 2) + "\n";
fs.writeFileSync(OUT, text);
fs.mkdirSync(path.dirname(OUT_APP), { recursive: true });
fs.writeFileSync(OUT_APP, text);
console.log(JSON.stringify({ ok: true, count: items.length, dates: items.map((x) => x.date) }));
