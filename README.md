# 数字工坊（digital-workshop）

业务内容（`bots/`、`projects/`）与**应用本体**分开存放。

## 应用本体
全部在 **`超级工作台应用/`**：
- `app/` 静态工作台网页
- `data/` 主数据 JSON
- `scripts/sync.sh` 同步
- `mac-app/数字工坊.app` Mac 启动器

详见 [`超级工作台应用/README.md`](超级工作台应用/README.md)。

## 公网预览
**https://einkyhuang.github.io/digital-workshop/**

> **仓库为 Public**（免费计划无法给私有仓开 Pages）。内含岗位职责与测试用公开买家信息，**无** Token/密钥。请勿提交密钥。

仓库：https://github.com/einkyhuang/digital-workshop

## 目录结构
```
超级工作台应用/     ← 工作台应用（网页、数据、Mac App、同步脚本）
bots/<名字>/        ← 每个 Bot：profile + deliverables/files/notes/memory
projects/           ← 项目说明（看板、服装客户开发、超级工作台应用…）
index.html          ← 本地跳转到 超级工作台应用/app/
```

## 推荐本地位置
- iCloud：`~/Library/Mobile Documents/com~apple~CloudDocs/超级工作台/`
- 桌面：`~/Desktop/超级工作台/`

然后打开 `超级工作台应用/mac-app/数字工坊.app`，或双击 `超级工作台应用/app/index.html`。

## 同步
```bash
cd 超级工作台应用 && ./scripts/sync.sh
```
