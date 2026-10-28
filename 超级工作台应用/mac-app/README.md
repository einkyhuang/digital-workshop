# 超级工作台 · 原生 Mac App

真正的 SwiftUI 原生应用（不是打开网页的启动器）。

## 打开
- 桌面：`~/Desktop/超级工作台.app`
- 或：`超级工作台应用/mac-app/超级工作台.app`
- 第一次若被拦截：右键 → 打开（ad-hoc 签名）

## 数据（文件为唯一真相）
读写：
`~/Library/Mobile Documents/com~apple~CloudDocs/超级工作台/超级工作台应用/data/workspace.json`

员工详情还会列出 `bots/<名字>/{deliverables,files,notes,memory}`，并可「在 Finder 中显示」。

工具栏「同步」会在本仓库执行 `git pull --rebase` / commit / push。

## 从源码构建
```bash
cd 超级工作台应用/mac-app/SuperWorkbench
./build.sh
# 产物：../超级工作台.app
# bundle id: com.ky.superworkbench
```

## UI
浅色侧栏 + 分组导航 + 角标；大标题；⌘K 搜索；同步；黑色「新建」；员工卡片网格；看板；底部浮动指令条。
