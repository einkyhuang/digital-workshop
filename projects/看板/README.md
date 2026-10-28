# 看板项目：数字工坊 · 工作台

静态网页工作台，共 7 个分页：总览 / 员工档案 / 任务看板 / 群聊协作 / 定时巡检 / 招聘规划 / 规则与文档。

- 代码：`app/`（index.html + assets/），双击就能在本地打开，不用开服务器
- 数据：`data/workspace.json`（网页会优先读这个文件；用 file:// 打开读不到时，改用页面里内置的同一份数据）
- 页面上的改动先存在浏览器 localStorage → 用「导出 JSON」覆盖 `data/workspace.json` → 运行 `scripts/sync.sh` 同步到云端
- 原型：Grok Bot Canvas「数字工坊 · 工作台」
