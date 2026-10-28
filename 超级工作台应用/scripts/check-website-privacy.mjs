#!/usr/bin/env node
/**
 * Fail if tracked workspace.json (or staged) still contains unredacted
 * websiteProjects client/company/amounts/localPath.
 */
import fs from "fs";
import path from "path";
import { spawnSync } from "child_process";
import { fileURLToPath } from "url";
import { REPO, looksUnredacted, PRIVATE_FILE } from "./website-privacy.mjs";

const tracked = [
  "超级工作台应用/data/workspace.json",
  "超级工作台应用/app/data/workspace.json",
];

function checkFile(abs, label) {
  if (!fs.existsSync(abs)) return [];
  const d = JSON.parse(fs.readFileSync(abs, "utf8"));
  const bad = [];
  for (const p of d.websiteProjects || []) {
    if (looksUnredacted(p)) bad.push(`${label}:${p.id || p.name}`);
  }
  // also scan raw text for home paths under websiteProjects blob
  const raw = fs.readFileSync(abs, "utf8");
  if (raw.includes('"/Users/') && /"websiteProjects"\s*:/.test(raw)) {
    // already covered by looksUnredacted localPath; keep as belt
  }
  return bad;
}

const mode = process.argv.includes("--staged") ? "staged" : "working";
let errors = [];

if (mode === "staged") {
  for (const rel of tracked) {
    const r = spawnSync("git", ["show", `:${rel}`], { cwd: REPO, encoding: "utf8", maxBuffer: 30 * 1024 * 1024 });
    if (r.status !== 0) continue;
    try {
      const d = JSON.parse(r.stdout);
      for (const p of d.websiteProjects || []) {
        if (looksUnredacted(p)) errors.push(`staged:${rel}:${p.id || p.name}`);
      }
    } catch (e) {
      errors.push(`staged:${rel}:parse ${e.message}`);
    }
  }
  // Ensure private file is never staged
  const staged = spawnSync("git", ["diff", "--cached", "--name-only"], { cwd: REPO, encoding: "utf8" });
  const names = (staged.stdout || "").split("\n").filter(Boolean);
  for (const n of names) {
    if (n.includes("data/private/") || n.endsWith("websiteProjects.local.json")) {
      errors.push(`must-not-stage:${n}`);
    }
  }
} else {
  for (const rel of tracked) {
    errors = errors.concat(checkFile(path.join(REPO, rel), rel));
  }
}

if (errors.length) {
  console.error("Website privacy check FAILED:");
  for (const e of errors.slice(0, 40)) console.error(" -", e);
  if (errors.length > 40) console.error(` … +${errors.length - 40} more`);
  console.error("Full data belongs in", PRIVATE_FILE, "(gitignored).");
  process.exit(1);
}
console.log("Website privacy check OK (" + mode + ").");
