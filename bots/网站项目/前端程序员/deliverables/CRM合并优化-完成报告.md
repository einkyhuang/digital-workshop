# MagicHub CRM → 外贸工作台「客户管理」合并优化报告

**时间（Asia/Shanghai）**: 2026-10-30  
**源（只读）**: `/Users/ky/Desktop/网站标准/通用版外贸客户管理`  
**目标**: 超级工作台 · 外贸工作台 · 客户管理

## 1. 前后数据体量

| 项目 | 合并前 | 合并后（工作台侧） |
|------|--------|-------------------|
| 源目录总计 | **2.2G**（含 node_modules 541M + dist_electron 1.3G） | 不拷入仓 |
| 纳入私有数据 `data/private/crm` | — | **269M**（含 PDF 原件 189M、原图 34M、sqlite/分页/缩略图） |
| 源码参考 `crm-magichub/` | — | **3.8M**（无 node_modules/dist/大资源） |
| 公开索引 `data/crm/` | — | **20K** |
| 客户 JSON 全文 | 13.3MB / 19055 条一次加载 | 索引 ~1ms；单页 100 条 ~2ms；SQLite count ~19ms |
| 产品图 | 949 张 / 34M 原图 | WebP 缩略图 **949 张 / 10M**；原图按需 |
| PDF | 4 份 / ~189M 启动可读 | **仅索引**；打开条目才读原文 |

## 2. 打开/加载耗时（本机 stress）

见 `crm-stress-results.json`：

- 合并前加载 leads 全文 JSON：**104.6 ms**（且占 13MB 内存解析）
- 合并后加载 leads 索引：**1.1 ms**
- 合并后加载第 0 页（100 条）：**2.0 ms**
- 工作台 CRM 公开索引合计加载：**0.1 ms**
- PDF / 缩略图索引：**<1 ms**

结论：**工作台冷启动不再解析 1.9 万客户或大 PDF**；进入「客户管理」才分页拉取。

## 3. 升级特性清单

1. 客户数据 → **SQLite + 191 个分页 JSON**（pageSize=100），虚拟/分页列表
2. 产品图 → **WebP 缩略图**（最长边 320，q=72），原图懒加载
3. PDF → **仅索引**（名/大小/路径），点击再用系统打开原文
4. 产品 JSON → **products.sqlite** + 公开样例索引
5. 重计算（转码/建库）在合并脚本后台线程池完成，不进 UI 主路径
6. 私有与派生一律 `data/private/crm/`（gitignore）；Pages 不暴露明细
7. 外贸工作台新增模块 **客户管理**（`crmCustomers`）

## 4. Electron 专有、未并入工作台的能力

- 本地 ZIP 热更新 / `select-local-zip-and-update`
- `userData/settings` 双写与 `.bak` 恢复（工作台改用 private 目录）
- 安全模式 `get-secure-mode`、原生菜单、扫盘 `scan-directory`
- 完整 Vue 驾驶舱/AI 浮层/团队管理等重度交互（源码留在 `crm-magichub/` 供对照；未嵌 Electron runtime）

## 5. 路径（digital-workshop）

- 公开索引：`/workspace/digital-workshop/超级工作台应用/data/crm/`
- 私有（本机）：`…/超级工作台应用/data/private/crm/`
- 源码：`…/超级工作台应用/crm-magichub/`
- 说明：`…/超级工作台应用/docs/crm-magichub-merge.md`
- 指标：`bots/网站项目/前端程序员/deliverables/crm-*-*.json`

## 6. 分段切换（前置任务）截图

同目录：`mac-overview-*-segment.png`、`web-overview-*-segment.png`、`分段工作台切换-完成报告.md`
