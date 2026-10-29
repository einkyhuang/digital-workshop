# MagicHub 完整内嵌 · 完成报告

**时间（Asia/Shanghai）**: 2026-10-30

## 对 Desktop 生产包的说明（重要）

MagicHub 联调期间**确实多次**替换/重启了 `~/Desktop/超级工作台.app`，导致用户侧反复重启。记录如下：

| 时刻（Asia/Shanghai） | 动作 |
|----------------------|------|
| ~01:12–01:41 | 分段切换任务：多次 `build.sh` + ditto 覆盖 Desktop + `open`（备份 011242 / 012942 / 013119 / 014058） |
| ~02:22 | MagicHub：再次 ditto 覆盖 Desktop（备份 `超级工作台.app.bak-20261030-022211`；二进制 mtime **02:22:10**） |
| ~02:22–02:25 | 模块截图循环：对**同一生产包**约 **15 次** `pkill` + `open ~/Desktop/超级工作台.app`（按 tab 切换） |

**即刻起**：不再 quit/覆盖/打开生产 Desktop；自测改用 `/tmp/超级工作台-dev.app`（bundle id `com.ky.superworkbench.dev`），生产包仅在全部自测通过后**一次性**替换。

## 方案

外贸工作台 → 整页 MagicHub（WKWebView + MagicHubBridge）；顶部保留分段切换。原 Desktop MagicHub 目录只读。

## 路径

- 对照表：`bots/网站项目/前端程序员/deliverables/MagicHub完整内嵌-功能对照表.md`
- 截图：`…/deliverables/magichub-modules/mac-mh-*.png`
- 提交：`0d859d4`（后续再推脱敏/dev 构建脚本）
