# MagicHub 完整内嵌 · 功能对照表（原版 vs 外贸工作台）

**时间（Asia/Shanghai）**: 2026-10-30  
**原版（只读）**: `/Users/ky/Desktop/网站标准/通用版外贸客户管理`  
**内嵌入口**: 超级工作台 →「外贸工作台」分段 → 全屏 MagicHub（WKWebView）

| # | 模块 / 能力 | 原版 | 内嵌 | 状态 | 截图 |
|---|-------------|------|------|------|------|
| 1 | 驾驶舱 | ✓ | ✓ | 对齐 | magichub-modules/mac-mh-dashboard-驾驶舱.png |
| 2 | 日程管理 | ✓ | ✓ | 对齐 | mac-mh-schedule-日程管理.png |
| 3 | 客户管理 | ✓ | ✓ | 对齐 | mac-mh-customers-客户管理.png |
| 4 | 智能营销 | ✓ | ✓ | 对齐 | mac-mh-marketing-智能营销.png |
| 5 | 商机管理 | ✓ | ✓ | 对齐 | mac-mh-opportunities-商机管理.png |
| 6 | 跟进记录 | ✓ | ✓ | 对齐 | mac-mh-followup-跟进记录.png |
| 7 | 寄样跟进 | ✓ | ✓ | 对齐 | mac-mh-samples-寄样跟进.png |
| 8 | 报价记录 | ✓ | ✓ | 对齐 | mac-mh-quotes-报价记录.png |
| 9 | 订单合同 | ✓ | ✓ | 对齐 | mac-mh-contracts-订单合同.png |
| 10 | 产品管理 | ✓ | ✓ | 对齐 | mac-mh-products-产品管理.png |
| 11 | 知识仓库 | ✓ | ✓ | 对齐 | mac-mh-knowledge-知识仓库.png |
| 12 | 公司信息 | ✓ | ✓ | 对齐 | mac-mh-company-公司信息.png |
| 13 | 团队管理 | ✓ | ✓ | 对齐 | mac-mh-team-团队管理.png |
| 14 | Agent 协同 | ✓ | ✓ | 对齐 | mac-mh-agentRoom-Agent协同.png |
| 15 | 系统设置 | ✓ | ✓ | 对齐 | mac-mh-settings-系统设置.png |
| 16 | 顶栏 AI 网关 / 极密模式 | ✓ | ✓ | 对齐/桥接 | UI+Swift get-secure-mode |
| 17 | 底栏 AI 指令（深度搜索） | ✓ | ✓ | 对齐 | MagicHub 自带 |
| 18 | settings 持久化 | userData | private/crm/settings | 对齐 | gitignore |
| 19 | 读写下/扫盘/openPath | Electron | Swift bridge | 对齐 | |
| 20 | ZIP 热更新 | ✓ | 降级提示 | **差异** | 改用 git pull+重建 |
| 21 | Pages 完整客户库 | N/A | 不发布 | **有意** | 隐私降级文案 |

## 未对等

1. ZIP 热更新：内嵌于宿主进程，不能热换 Desktop.app。  
2. Pages：故意无客户明细。  
3. AI Key：源码已脱敏；请在系统设置写入，存 private，勿提交。
