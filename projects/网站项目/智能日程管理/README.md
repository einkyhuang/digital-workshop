# 智能日程管理（SmartPlan Hub）

> 源码位置（未移动，因含 node_modules/dist 约 883MB）：仓库根目录 `智能日程管理/`

## 是什么
macOS 向的智能项目管理与日程系统：AI 自然语言建日程、与「提醒事项」双向同步、Kanban/日历、客户定制网站档案。技术栈 **Electron + Express + better-sqlite3 + Vite/React/Tailwind**。本地访问 `http://localhost:3300`。

## 启动
```bash
cd 智能日程管理
./start.sh
# 或 npm run build && npm start / npm run dev
```

## 工作台匹配
- 负责人：搜搜-SEO专家（网站项目）
- 协作：画眉-设计师（UI）、墨墨-主笔（文案）、小运-COO（进度）

## 注意
勿提交 `.env`、API Key、本地 `*.db`。Keys 存在本机 SQLite settings，不进 Git。
