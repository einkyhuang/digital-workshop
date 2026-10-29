# 交付报告：日程中心 · 每日总结 · 看板拖拽 · 多工作台

时间：2026-10-30（Asia/Shanghai）

## Commits

- `5f0099c` feat: 日程中心、每日总结、看板拖拽、多工作台切换
- `8bc29b9` fix(workbench): 工作台切换器移到总览标题行（非侧栏）

## 格式 / 配置文档

- 日程约定：`/workspace/digital-workshop/超级工作台应用/docs/schedule-format.md`（同目录 README：`超级工作台应用/data/schedule/README.md`）
- 多工作台：`/workspace/digital-workshop/超级工作台应用/docs/workbenches.md`
- 配置文件：`/workspace/digital-workshop/超级工作台应用/data/workbenches.json`（网页副本 `超级工作台应用/app/data/workbenches.json`）

### 如何新增工作台

编辑 `data/workbenches.json` 的 `workbenches[]`：填 `id/name/shortName/icon/description`、`botGroupIds`（`null`=全员）、`modules`（已实现模块 id 列表）。同步复制到 `app/data/`。切换入口在 **「工作台总览」标题行右侧下拉**（非侧栏）。

## 截图（deliverables）

Mac（窗口级）：

- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-mac-overview-workbenches.png`（标题行切换器已就位）
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-mac-schedule-center.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-mac-schedule-day-detail.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-mac-daily-summary.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-mac-kanban-dnd.png`

Web（本地 Playwright）：

- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-web-overview-workbenches.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-web-schedule-center.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-web-schedule-day-detail.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-web-daily-summary.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-web-kanban-dnd.png`
- `/workspace/digital-workshop/bots/网站项目/前端程序员/deliverables/sw-web-trade-workbench.png`

## 看板拖拽持久化

- **Mac**：拖到任意列 → `setTaskStatus` → `save()` 在后台线程编码并原子写入 `超级工作台应用/data/workspace.json`（及 app 副本）；刷新/重启后保留。
- **Web（含 GitHub Pages）**：无法写仓库文件；拖拽后 `updateTask` → 既有 `localStorage`（`digital-workshop-v2`）覆盖层，本机刷新保留；换浏览器/清缓存会丢，需导出 JSON 或 Mac 同步。

## 隐私决策

1. **邮件正文**：公开 `email-daily.json` 已剥离 `重要邮件`；完整内容仅 `bots/外贸营销/超级邮件助手/deliverables/email-daily/`。Pages 只显示有/无标记或计数。
2. **纪纪日报**：正文不进 `app/` / Pages；仅 `daily-reports-index.json` 日期列表。Pages「每日总结」隐私降级占位。样本日报含客户名，故不发布全文。
3. **外贸线索**：公开 `trade-leads-index.json` 仅聚合计数；明细样例在 gitignore 的 `data/private/trade-leads.local.json`。
4. **网站金额**：仍仅本地 private / 总览脱敏口径；切换器与配置不含客户名。

## Desktop 应用

- 已重建并替换 `~/Desktop/超级工作台.app`
- 旧包备份在 `bots/网站项目/前端程序员/files/超级工作台.app.bak-*`（不在 Desktop）
