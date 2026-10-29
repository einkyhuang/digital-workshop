# MagicHub CRM 合并进外贸工作台（优化版）

## 原则

- **不拖慢工作台启动**：不嵌入 Electron 整包；启动不读 1.9 万客户全文 / 大 PDF / 原图。
- **私有数据**在 `超级工作台应用/data/private/crm/`（gitignore）；派生缩略图/分页亦然。
- **公开仓**仅 `超级工作台应用/data/crm/*-index.json` 与脱敏样例。

## 目录

| 路径 | 内容 |
|------|------|
| `crm-magichub/` | 源码参考（无 node_modules / dist / 大图 / 大 PDF / leads_seed） |
| `data/private/crm/leads/` | `leads.sqlite` + `page-XXXX.json` |
| `data/private/crm/products/` | 原图 + `products.sqlite` |
| `data/private/crm/thumbs/products/` | WebP 缩略图（原图按需） |
| `data/private/crm/pdfs/` | 原 PDF + 索引 |
| `data/crm/` | 公开索引 |

## 入口

- 模块 id：`crmCustomers` →「客户管理」（外贸工作台）
