# 超级工作台应用

本文件夹集中存放「数字工坊 · 工作台」的**应用本身**（网页、数据、同步脚本、Mac App），与仓库根目录的 `bots/`、`projects/` 业务内容分开。

## 内容
```
app/                 静态网页（index.html + assets + 内置数据兜底）
  data/workspace.json  网页读取的数据副本
data/workspace.json  主数据（Bot / 任务 / 群聊 / 巡检 / 招聘 / 规则）
scripts/sync.sh      云端 ↔ 本地同步
mac-app/数字工坊.app  Mac 启动器（未签名）
```

## 打开方式
- **公网**：https://einkyhuang.github.io/digital-workshop/
- **本地**：双击 `app/index.html`
- **Mac App**：打开 `mac-app/数字工坊.app`（第一次请右键 → 打开）

推荐把整个仓库放到：
- `~/Library/Mobile Documents/com~apple~CloudDocs/超级工作台/`（iCloud）
- 或 `~/Desktop/超级工作台/`

启动器会优先找：`…/超级工作台/超级工作台应用/app/index.html`

## 同步
在网页里改完 →「导出 JSON」→ 覆盖本目录 `data/workspace.json` → 运行：

```bash
./scripts/sync.sh
```

脚本会把 `data/workspace.json` 复制到 `app/data/`，再 git pull / commit / push（在仓库根目录执行）。

请勿把 API Key、Token、密码放进本文件夹或仓库。
