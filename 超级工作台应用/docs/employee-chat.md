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
