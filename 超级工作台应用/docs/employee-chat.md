# 员工实时对话（Employee Chat）

## 私有存储（不进 git）

会话与工作摘要写在 macOS Application Support，与全局模型配置同级：

```
~/Library/Application Support/超级工作台/conversations/<botId>/
  prefs.json                 # 该员工默认 providerId / model / defaultSkillIds
  工作摘要.md                 # 会话结束后追加的中文摘要
  sessions/
    YYYY-MM-DD-HHMM.jsonl    # 每轮会话一行 JSON（role/content/ts…）
```

- **不要**把对话写进仓库里的 `bots/<部门>/<员工>/对话/`（已在 `.gitignore` 忽略，以防误放）。
- Grok Bot / 日常同步可自行从 Application Support 拷贝 `工作摘要.md` 到对应 bot 目录（由你在 Mac 上配置）。

## botId → 文件夹映射

| 用途 | 键 | 示例 |
|------|-----|------|
| 会话目录名 | `workspace.json` → `bots[].id` | `chief` → `…/conversations/chief/` |
| 人设 / persona | `bots[].folder`（或 `Bot.folderName`） | `chief` → 仓库 `bots/管理中枢/最强大脑/persona.md`（无则 `profile.md`） |

UUID 形式的 id 会原样用作目录名（仅保留字母数字与 `-_`）。

## 行为摘要

- 打开：员工档案详情「对话」、卡片右键「对话」、详情「打开对话」。
- 模型：员工 prefs → 全局 `activeProviderId`（默认偏好通义千问）→ 首个已启用网关。
- 人设：name/role/duty/skills/memory + `persona.md`/`profile.md` + 选中 Skills 的 SKILL.md（有体积上限）。
- 上下文：最近约 12 轮（最多 24 条 user/assistant）。
- 结束：关窗 /「结束并总结」/ 闲置 10 分钟 → 调该员工模型写 ≤150 字中文摘要，追加到 `工作摘要.md`。

## Web

Web 端仅提供入口说明；完整能力在 Mac「超级工作台」App。


## 全局对话 = 大可可总调度（chief）

全局 Agent 面板默认以 `bots[].id == chief`（大可可-最强大脑）身份对话，并可用：

- `list_employees` — 列出员工 id / 姓名 / 简介
- `delegate_to_employee(botId, task)` — 用该员工的模型与人设跑子对话，写入
  `~/Library/Application Support/超级工作台/conversations/<botId>/sessions/*.jsonl`
  并追加 `工作摘要.md`；同一轮最多并行 3 个；每条用户消息最多 6 轮工具往返。

浏览器 / 邮件 / 发帖仍应交给 Grok Bot App 里的大可可。

- `crm_stats` — 客户库统计（总数 / 国家 / 阶段 / 星级 / 来源）；总数与「客户管理」同源：`leads-index.json` 的 `total`（优先 private）
- `system_overview` — 客户 / 员工 / 任务 / 项目 / deliverables 总览
- `crm.search_customers` — 模糊匹配 company/country/product/notes；返回 `matchTotal`；`countOnly=true` 只计数

每轮 system prompt 注入一行实时快照（仅 totals）。问数量先看快照或 `crm_stats` / `system_overview`，禁止翻页扫全库。客户明细只读本地 private CRM，不入库。

## 面板双选项卡

- **全局对话**：系统工具 + `crm_stats` / `semantic_search_customers`，不委派。
- **大可可**：总调度，可 `list_employees` / `delegate_to_employee`；会话写入 `conversations/chief/`。

各选项卡独立保留 transcript / 模型 / 技能；记忆上次选项卡。向量索引位于 `~/Library/Application Support/超级工作台/vectors/`（不进 git）；全局设置可选向量模型并「重建索引」。

