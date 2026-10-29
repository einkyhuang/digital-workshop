# 超级工作台 · 全局 Agent 方案（设计稿）

> 仅方案，不含实现。基于当前代码：`WorkspaceStore`（任务/看板/工作台切换/日程与日报打开）、`SidebarSection` 导航、`MagicHubBridge`（WKWebView IPC：读写 private CRM、settings）、MagicHub `App.vue` 底部悬浮 AI 栏 + 多 Provider OpenAI 兼容网关、网页版 `app.js`（Pages 静态 + `localStorage` 覆盖）。  
> 现有快捷键：⌘R 刷新、⌘⇧S 同步 —— **⌘K / ⌘J 均未占用**；建议默认 **⌘K** 唤起（与「命令面板」心智一致），⌘J 作备选或「仅聚焦输入」。

---

## 1. 目标与交互

- 底部 AI 对话**默认隐藏**；**⌘K**（或右下角浮动按钮）唤起全屏/半屏「全局 Agent」面板，再按一次或 Esc 收起。
- Agent 像无限画布助手：能**读/写/操控**工作台（任务、日程、看板、切工作台、开页面、操作 MagicHub 客户/报价等），**每一步 tool 调用在聊天里可见**（名称、参数摘要、成功/失败、耗时）。
- Mac 为能力完整端；网页版能力子集 + 明确降级提示。

## 2. 架构

```
用户 → Agent UI（流式对话 + 步骤时间线）
     → LLM（OpenAI-compatible chat/completions + tools）
     → ActionRegistry（跨端同一套 typed actions）
     → Executor
          ├─ Mac: WorkspaceStore / Navigation / MagicHubBridge(+evaluateJS 调 CRM)
          └─ Web: 内存 state + localStorage（不能写仓库/不能真发信）
     → AuditLog + UndoStack（本地）
```

- **Tool-calling 循环**：system 注入当前上下文（activeWorkbench、当前 SidebarSection、可见任务摘要、CRM 是否已加载）；模型返回 `tool_calls` → 注册表校验 → 风险门控 → 执行 → 把 `tool` 结果塞回消息 → 再续写，直到无 tool 或达步数上限（建议单轮 ≤12）。
- **Typed Action Registry**（JSON Schema，Mac/Web 共享一份 `actions.schema.json`）：`name / params / risk / undoable / platforms`。Swift 与 JS 各生成薄适配层，禁止两端各写一套字符串协议。
- **Mac 执行**：读操作走 Store 快照；写操作走已有 API（`addTask` / `updateTask` / `setTaskStatus` / `deleteTask` / `switchWorkbench` / `openDailySummary` 等）并 `save()`；导航设 `selectedSection`；MagicHub 优先经 Bridge 扩展「具名 CRM 动作」，复杂 UI 操作再 `evaluateJavaScript` 调页面导出 API（避免裸 `write-file` 成为默认工具）。
- **Web 执行**：同源 Action 名；持久化仅 `localStorage`（与现看板拖拽一致）；**不能** git 写回、**不能**真发邮件/外呼；CRM 只读公开索引或提示「请用 Mac App」。
- **Undo / 审计**：每次写动作入 `AuditLog`（时间、action、params 摘要、前后快照指针）；可 undo 的写进 `UndoStack`（任务 CRUD、状态变更优先）；不可 undo 的外发类只审计。日志落 `data/private/agent-audit/`（gitignore），永不进公开仓库。

## 3. 可控动作清单（初版）

| Action | 主要参数 | 风险 |
|---|---|---|
| `nav.open_section` | sectionId | L0 安全 |
| `nav.switch_workbench` | workbenchId | L0 |
| `context.get_snapshot` | scope | L0 |
| `task.create` | title, note, executor, reviewer, status? | L1 可逆写 |
| `task.update` | id, fields | L1 |
| `task.set_status` | id, status | L1 |
| `task.delete` | id | L2 破坏性 |
| `schedule.open_day` / `daily.open_report` | date | L0 |
| `crm.search_customers` | query, page | L0（private 只本地） |
| `crm.open_customer` | customerId | L0 |
| `crm.upsert_followup` | customerId, note | L1 |
| `crm.create_quote` | customerId, draft fields | L2 |
| `crm.send_email` / `external.publish` | … | L3 外发/不可逆 |
| `agent.undo_last` | — | L1 |

（后续按模块扩展：招聘标记、网站项目 private 字段等，一律带 risk。）

## 4. 确认策略

| 风险 | 策略 |
|---|---|
| L0 | 直接执行，聊天里打步骤 |
| L1 | 默认可自动执行；设置项可改为「先确认」 |
| L2 | **必须**确认对话框（删任务、写报价草稿、批量改） |
| L3 | **必须**确认 + 复述关键字段（收件人/渠道/将发出的摘要）；取消则不调用 |

外发、发布、删除、清空、覆盖 private 大文件、任何离开本机的网络写 —— 一律 L3。确认 UI 展示 action 名与参数，用户点「执行」后才进 Executor。

## 5. 模型与密钥

- **多 Provider**：复用 MagicHub 已有思路（DeepSeek、通义/百炼、硅基流动及任意 OpenAI 兼容 Base URL）；工作台全局 Agent 独立配置面板，可导入 MagicHub `magichub_ai_providers`（经 Bridge loadSettings），但键位命名空间分开（`sw_global_agent_providers`）。
- **默认模型可切换**；支持自定义 Base URL + Key + model id。
- **密钥存储**：Mac → **Keychain**（Key 本体）+ UserDefaults/本地 json 只存非机密（baseUrl、model、enabled）；Web → `localStorage` **并强警告「明文、勿用生产密钥」**，或可选「本机小代理」只在 localhost 持有 Key。**禁止**写入 git / `workspace.json` / Pages 产物。
- **流式**：SSE/`stream: true`；UI 逐 token；tool_calls 常在流结束的 delta 里拼装 —— 适配层需缓冲 arguments。
- **兼容性**：统一 OpenAI tools 协议；若某网关不支持 tools，降级为「JSON 动作块」解析（次优）；极密模式沿用 MagicHub：禁止外网 Provider。

## 6. 分期与风险

| 阶段 | 交付 |
|---|---|
| P0 | 隐藏底栏 + ⌘K/浮动钮；只读 snapshot + 导航/切工作台；单 Provider 流式对话 |
| P1 | 任务/看板 CRUD + 确认框 + 审计/撤销；Mac 落盘 |
| P2 | MagicHub 具名 CRM 工具（查客户、跟进、报价草稿）；确认策略 L2/L3 |
| P3 | Web 子集对齐；多 Provider 设置；导入 MagicHub 网关列表 |

**风险**：模型误删/误发（靠 L2/L3 + undo）；Pages 用户误以为已写入仓库；CRM 大 JSON 经 Bridge 的性能（沿用现有大包落盘回复）；tools 不兼容网关；快捷键与系统/输入法抢占（可设置项改键）。隐私：Agent 上下文默认脱敏客户名/金额，除非用户在 Mac 显式「允许本会话使用明文客户字段」。

---

*文档日期：2026-10-30（Asia/Shanghai）。下一步需用户拍板快捷键默认值与 P0 是否先做 Mac-only。*
