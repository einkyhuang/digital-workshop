# 多工作台配置

路径：`超级工作台应用/data/workbenches.json`（网页副本：`超级工作台应用/app/data/workbenches.json`）

## 切换入口

工作台切换器在 **「工作台总览」标题行**：横向分段按钮（由 `workbenches.json` 渲染，当前项高亮），不在侧栏、不用下拉。总览页不再展示「工作台卡片」切换区。

## 如何新增一个工作台

1. 在 `workbenches` 数组追加一项，填写唯一 `id`、`name`、`shortName`、`icon`（SF Symbol 名 / 网页用 emoji 映射）、`description`。
2. `botGroupIds`：`null` 表示全员；否则为 `workspace.json` 里 bot 的 `group` / `groups[]` 名称列表。
3. `modules`：侧栏模块 id 列表，须是应用已实现的模块（见下表）。未列出的模块不显示。
4. 可选 `data`：私有/索引数据路径（线索等）。**客户名与金额只写 private（gitignore）**；公开仓/Pages 只用 `*-index.json` 聚合计数。
5. 同步复制到 `app/data/workbenches.json` 后提交。Mac 应用与网页启动时读取该文件，无需改代码即可加台（新模块 id 若未实现会显示占位卡）。

## 已实现模块 id

| id | 名称 |
|--|--|
| overview | 总览 |
| roster | 员工档案 |
| tasks | 任务看板 |
| scheduleCenter | 任务与日程中心 |
| dailySummary | 每日总结 |
| rooms | 群聊协作 |
| routines | 定时巡检 |
| projects | 网站项目 |
| hiring | 招聘规划 |
| rules | 规则与文档 |
| tradeLeads | 客户与线索 |
| tradePipeline | 开发进度 |
| tradeQuotes | 询盘与报价 |

## 隐私

- Pages / 公开仓：工作台切换与模块列表可公开；线索只暴露 `trade-leads-index.json` 计数。
- `data/private/trade-leads.local.json` 已 gitignore，可含客户名/金额。
