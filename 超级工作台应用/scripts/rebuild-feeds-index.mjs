#!/usr/bin/env node
/**
 * Rebuild data/feeds/<source>/index.json and mirror into app/data/feeds/
 * Usage: node 超级工作台应用/scripts/rebuild-feeds-index.mjs [sourceId]
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const appRoot = path.resolve(__dirname, "..");
const repoHint = path.resolve(appRoot, "..");
const registryPath = path.join(appRoot, "data/feeds-registry.json");

function readJSON(p) {
  return JSON.parse(fs.readFileSync(p, "utf8"));
}

function listDayFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => /^\d{4}-\d{2}-\d{2}\.(json|md)$/.test(f))
    .sort()
    .reverse();
}

function summarize(filePath, date, file) {
  const ext = path.extname(file);
  if (ext === ".md") {
    const text = fs.readFileSync(filePath, "utf8");
    const first = text.split("\n").find((l) => l.trim()) || "";
    return {
      date,
      file,
      summary: first.replace(/^#\s*/, "").slice(0, 120),
      articleCount: 0,
      issueCount: 0,
    };
  }
  const doc = readJSON(filePath);
  return {
    date,
    file,
    summary: doc.summary || "",
    articleCount: Array.isArray(doc.articles) ? doc.articles.length : 0,
    issueCount: Array.isArray(doc.issues) ? doc.issues.length : 0,
  };
}

function rebuildOne(feed) {
  const publicDir = path.join(repoHint, feed.publicDir.replace(/^超级工作台应用\//, "超级工作台应用/").replace(/^\.\//, ""));
  // feeds-registry paths are repo-relative starting with 超级工作台应用/
  const dir = path.join(repoHint, feed.publicDir);
  const files = listDayFiles(dir);
  const dates = files.map((f) => {
    const date = f.replace(/\.(json|md)$/, "");
    return summarize(path.join(dir, f), date, f);
  });
  const index = {
    version: 1,
    feedId: feed.id,
    timezone: "Asia/Shanghai",
    updatedAt: new Date().toISOString().replace(/\.\d{3}Z$/, "+00:00"),
    dates,
  };
  const indexPath = path.join(dir, "index.json");
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(indexPath, JSON.stringify(index, null, 2) + "\n");
  // mirror to app/data
  const rel = feed.publicDir.replace(/^超级工作台应用\//, "");
  const appDir = path.join(appRoot, rel.replace(/^data\//, "app/data/").includes("app/data") ? rel : path.join("app", rel));
  // publicDir like 超级工作台应用/data/feeds/seo → app/data/feeds/seo
  const mirrorDir = path.join(appRoot, "app/data/feeds", feed.id);
  fs.mkdirSync(mirrorDir, { recursive: true });
  for (const f of fs.readdirSync(dir)) {
    if (f.startsWith(".")) continue;
    fs.copyFileSync(path.join(dir, f), path.join(mirrorDir, f));
  }
  console.log(`[feeds] ${feed.id}: ${dates.length} day(s) → ${indexPath}`);
}

const registry = readJSON(registryPath);
const only = process.argv[2];
for (const feed of registry.feeds || []) {
  if (only && feed.id !== only) continue;
  if (!feed.publicDir) continue;
  rebuildOne(feed);
}
console.log("done");
