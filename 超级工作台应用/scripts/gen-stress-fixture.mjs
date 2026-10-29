#!/usr/bin/env node
/**
 * Generate synthetic 10x workspace overlay for local stress tests.
 * Output: /tmp/sw-stress-workspace.json (NEVER commit).
 * Usage: node 超级工作台应用/scripts/gen-stress-fixture.mjs [--bots 100] [--projects 200]
 */
import fs from "fs";
import path from "path";

const args = process.argv.slice(2);
function arg(name, def) {
  const i = args.indexOf(name);
  return i >= 0 ? Number(args[i + 1]) : def;
}
const nBots = arg("--bots", 100);
const nProjects = arg("--projects", 200);
const out = process.env.SW_STRESS_OUT || "/tmp/sw-stress-workspace.json";

const groupsOrder = [
  "管理中枢", "网站项目", "服装外贸", "运营管理", "战略决策",
  "视觉设计", "短剧组", "外贸营销", "个人成长", "内容营销",
];
const statuses = ["在线", "空闲", "忙碌"];
const layers = ["幕僚室", "Studio执行层", "生活层", "系统"];
const webStatus = ["in_progress", "delivered", "infrastructure", "inactive"];
const cats = ["进行中", "已交付", "筹建", "挂起"];
const frameworks = ["React", "Next.js", "Vue", "WordPress", "静态站"];

const bots = [];
for (let i = 0; i < nBots; i++) {
  const g = groupsOrder[i % groupsOrder.length];
  const id = i < 3 ? ["chief", "seo", "patrol"][i] : `stress-bot-${String(i).padStart(3, "0")}`;
  bots.push({
    id,
    code: i < 10 ? `S${i}` : `X${i}`,
    name: `压测员工${i}-角色${i % 7}`,
    layer: layers[i % layers.length],
    role: `角色${i % 7}`,
    duty: "合成压测数据，非真实员工。",
    status: statuses[i % statuses.length],
    tools: "synthetic",
    progress: (i * 7) % 100,
    token: "待接入",
    okr: "压测",
    lastDelivery: "暂无",
    testCases: "—",
    archive: "stress",
    knowledge: "—",
    skills: "—",
    memory: "synthetic",
    weekly: "压测周",
    emoji: "🤖",
    group: g,
    folder: `${g}/压测${i}`,
    groups: [g],
  });
}

const websiteProjects = [];
for (let i = 0; i < nProjects; i++) {
  const st = webStatus[i % webStatus.length];
  websiteProjects.push({
    id: `stress-web-${String(i).padStart(3, "0")}`,
    name: `压测站点 ${i}`,
    category: cats[i % cats.length],
    status: st,
    localPath: "",
    url: `https://example-stress-${i}.test/`,
    framework: frameworks[i % frameworks.length],
    description: "合成压测项目（假数据）",
    clientName: "",
    clientCompany: "",
    totalAmount: null,
    depositAmount: null,
    paidAmount: null,
    unpaidAmount: null,
    paymentStatus: ["fully_paid", "deposit_paid", "pending"][i % 3],
    services: ["网站搭建"],
    serviceStartDate: "2026-01-01",
    serviceEndDate: "2026-12-31",
    deadline: "2026-12-31",
    progress: (i * 3) % 100,
    ownerBotId: bots[i % bots.length].id,
    lastModified: "2026-10-30 00:00",
    createdAt: "2026-10-01T00:00:00.000Z",
    updatedAt: `2026-10-${String((i % 28) + 1).padStart(2, "0")}T12:00:00.000Z`,
    source: "stress",
    dirty: false,
  });
}

const doc = {
  version: 5,
  updatedAt: new Date().toISOString(),
  timezone: "Asia/Shanghai",
  bots,
  tasks: [],
  vacancies: [],
  groups: [],
  routines: [],
  rules: [],
  groupsOrder,
  websiteProjects,
  _stress: true,
  _note: "LOCAL ONLY — do not commit",
};

fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, JSON.stringify(doc));
console.log(JSON.stringify({ out, bots: bots.length, websiteProjects: websiteProjects.length, bytes: fs.statSync(out).size }, null, 2));
