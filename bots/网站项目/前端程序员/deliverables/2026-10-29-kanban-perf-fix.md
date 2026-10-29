# 超级工作台 · 看板打不开/慢 · 修复说明

时间：2026-10-29～30（Asia/Shanghai）

## 现象
用户反馈看板「打不开或打开很慢」。原生 Mac App（`~/Desktop/超级工作台.app`）进程能起来，但窗口长时间不可见；网页版总览加载沉闷。

## 修复前基线
- **Mac**：`open` 后 System Events 连续采样约 **30s+ windows=0**（进程存活）。iCloud 路径上同步读盘/`os.walk(bots)` 多次卡住（>30s）。
- **Web（https://einkyhuang.github.io/digital-workshop/）**：
  - HTML TTFB ≈ 0.09–0.15s，≈19.8KB
  - 头像目录合计 ≈ **12.35MB**（单张最高约 1.1MB）
  - 启动串行 fetch `data/private/*` 与多级相对路径 → GitHub Pages 上 404 风暴

## 根因
1. **Mac 主线程阻塞**：`onAppear` 同步 `store.load()`（iCloud JSON + 邮件日报枚举 + `sqlite3 waitUntilExit`）；花名册 `NSImage(contentsOf:)` 同步读 iCloud 头像。
2. **窗口在屏幕外**：多显示器残留 frame（曾观测到 x≈-1.2e7）；Dock 有进程但看不见。
3. **Web**：过大 PNG 头像 + private/多路径 404 + 等 JSON 才首屏。

## 改动
### 性能
- Mac：`loadAsync()` 后台解码/sqlite（4s 上限）；启动多次强制居中到鼠标所在屏；关闭窗口恢复；`AvatarCache`/`BotAvatarView` 异步缩小头像。
- Web：Pages 跳过 private；减少候选 URL；embedded 先首屏再刷新；头像 `loading=lazy`；`app/avatars/*.png` 压到 256px（**12.35MB → 2.49MB**，路径不变）。

### 改名（同提交）
- `阿哨-巡逻官` → `超级茉莉-巡逻官`
- 文件：`超级工作台应用/data/workspace.json`、`超级工作台应用/app/data/workspace.json`、`超级工作台应用/app/index.html`（嵌入）、`bots/管理中枢/巡逻官/profile.md`
- **未改**头像文件/路径（仍 `patrol` / `avatars/patrol.png`）

## 修复后耗时
- **Mac**：窗口出现约 **1.4–3.2s**（修复前 30s+ 仍为 0）；截图可见总览已加载 workspace。
- **Web（本地 8766 验证）**：index TTFB ≈3ms；25 张头像合计 2.49MB、串行下载 ≈0.02s。Pages 已上线：HTML TTFB≈0.085s；`avatars/patrol.png`≈93KB（修复前同目录单张可达 ~0.3–1.1MB）；线上截图 `sw-web-live-after.png`。

## 截图
- Mac：`bots/网站项目/前端程序员/deliverables/sw-mac-after.png`
- Web（修复后本地）：`bots/网站项目/前端程序员/deliverables/sw-web-after.png`

## 桌面约定
临时文件勿放 `~/Desktop`；仅保留 `超级工作台.app`。临时物放 `/tmp` 或 `bots/网站项目/前端程序员/files/桌面临时文件/`。
