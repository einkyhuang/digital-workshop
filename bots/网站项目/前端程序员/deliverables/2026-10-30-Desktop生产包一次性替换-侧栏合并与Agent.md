# Desktop 生产包一次性替换（侧栏合并 + 全局 Agent P2/P3）

时间：2026-10-30（Asia/Shanghai）  
用户原话（经大可可）：「同意现在替换桌面上的超级工作台.app，侧栏合并和全局 Agent P2/P3 一起上」

## 操作

| 步骤 | 结果 |
|---|---|
| 构建来源 | `main` @ `9e93e83`（含侧栏合并 + Agent P2/P3） |
| 自检 | `./build.sh` 成功；二进制含 `jsonSafe` 文案、`MagicHubNav`/`驾驶舱`/`Forwelike 专区`/`AgentCRM`/`GlobalAgentPanel`；bridge 含 `sw-mh-embed` |
| 旧 PID | **30137**（`kill -TERM` 精确 PID，无名称 pkill） |
| 备份 | `/tmp/超级工作台.app.bak-20261030-033703`（旧 exe mtime 03:05） |
| 替换 | **一次** `ditto` → `~/Desktop/超级工作台.app` + ad-hoc codesign |
| 启动 | **一次** `open`；新 PID **40812** |
| PID 稳定性 | 40812 连续 **≥90s**（etime 实测 01:32+）不变 |
| 新 exe mtime | **2026-10-30 03:37** Asia/Shanghai |
| 外贸侧栏 | 外层仅 MagicHub 菜单（驾驶舱…）；AX 未见「总览/员工/看板」；MH aside 嵌入隐藏 |
| ⌘K | 菜单/FAB 打开「全局 Agent P2 · CRM + 确认」面板（截图可见）；本地只读示例指令「搜客户 …」 |
| MagicHub 存盘 | `data/private/crm/settings/magichub_*.json` 于 **03:38 / 03:41** 写入；进程未退 |
| 崩溃 | 替换后 **无新增** `DiagnosticReports/超级工作台*.ips`（仅 Retired 旧报告） |

## 截图（deliverables，非 Desktop）

- `desktop-prod-trade-unified-sidebar.png`
- `desktop-prod-cmdk-agent-panel.png`
- `desktop-prod-cmdk-agent-answer.png`

## 红线遵守

- 未使用名称 `pkill`；备份不在 Desktop；仅一次替换、一次 `open`。
