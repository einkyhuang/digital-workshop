# Formore Lighting 30 天 SEO+GEO 复盘报告（2026-11-28，Day 30）

| 项 | 内容 |
|---|---|
| 站点 | https://www.formorelightings.com |
| 周期 | 2026-10-30 至 2026-11-28（Asia/Shanghai） |
| 任务 | 30 天计划 Day 30：审稿 + 复盘（全站内链终检、SEO 95 自评、KPI 复盘、下月计划） |
| 性质 | **只读复盘**。今日未改站点代码/模板，未 push 站点 main，未发布文章，未外发外链清单。 |
| 证据 | 线上首包 HTML 抓取（不执行 JS），2026-11-28 08:47–08:55（Asia/Shanghai）；明细见 `raw/internal-link-check-2026-11-28.json`；日检 `formorelighting2.0/reports/seo/2026-11-28.md`（站点仓库 main 62bb33e，未提交） |
| 对照 | 10-30 基线（内部口径 SEO 91.5 / GEO 71.5）；11-23 周报；11-26 GEO 复核；11-27 外链台账 v2 |

> 数据原则：只写有证据的数字。没有 PSI_API_KEY，Core Web Vitals 为 **未测/无数据**。11-23 脚本给出的 97.0 / 72.0 已被证明方法有误、与 10-30 不可比，本报告**不采用**，也**不另估一个综合分**。

---

## 1. 一句话结论

30 天内完成了 **15 篇集群文章上线**（超出 +12 的数量目标）和 llms.txt / FAQ 页等 GEO 基础项；但**不能声称 SEO 95 或 GEO 85 已达成**：今日内链终检新发现 **30 条站内 404 链接**（28 条在 HTML 站点地图页 /sitemap，2 条在首页），枢纽页不向下链文章，Organization 无 sameAs，旧文与产品页无 FAQPage，7 个产品空壳 URL 仍在，外链净增未达标。自 11-14 起**连续 14 天无新文章上线**，四篇成稿卡在配图。

## 2. 关键要点（带证据）

1. **内容：+15 篇上线，数量目标达成，翻新未见证据。** sitemap-insights.xml 今日 30 条（10-30 基线 15 篇）。按页面 datePublished，15 篇发布于 2026-10-30 至 2026-11-14，15/15 带 Article + FAQPage + BreadcrumbList。计划中的「含 3 篇翻新」：旧 15 篇今日仍无 FAQPage，**无翻新完成的证据**。
2. **内链终检：30/164 个站内链接目标为 404，新发现。** 55 个来源页（首页 + 25 个页面 + 30 篇文章）共 164 个唯一站内目标，134 个 200，30 个 404，0 个跳转。28 条来自 /sitemap 页：它用 `slugify(article.title)` 拼文章 URL，而不是文章 slug（`pages/Sitemap.tsx` 第 86 行）。2 条来自首页产品预览：`src/data/homeProductPreviews.ts` 的旧 slug `advanced-2835-smd-led-strip` 和 `classic-ashape-led-bulb-e27b22`。此前报告未检出，今日定为**新 P1**；需用户批准后再改代码。
3. **孤页：文章 0 篇；产品空壳 7 个。** 30 篇文章都至少有 2 条来自其他文章的入链（最少的是 future-marketing，2 条）。但 /insights 索引页首包只链 7/30 篇，其余藏在 JS 按钮「Explore More」后面。/products、/sourcing、/oem-odm、/solutions、/cases 五个枢纽页首包链向文章数均为 **0**，所以「枢纽→支撑」这一段没有闭环。7 个产品空壳 URL 仅在 sitemap 中出现，站内无任何链接。
4. **GEO 结构项部分完成。** 新集群文章 15/30 有 FAQPage，旧文 15/30 没有（11-26 复核，今日复测相同）。/llms.txt 200（985 字节），/llms-full.txt 404。Organization 无 sameAs。产品页 86 个正常 PDP 中 0 个有 FAQPage（11-26 证据）。
5. **外链：未达标。** Serpstat（11-27）显示引荐域 3、DR 10（基线 2 / 8）。活跃列表中 4 条是低质量目录链接，**不计入优质净增**。目标为 ≥8（净增 ≥6），未达成。10 个外链目标已备好，尚未外发。

## 3. KPI 对照表

| 维度 | 指标 | 10-30 基线 | 30 天目标 | 2026-11-28 实测/证据 | 判定 |
|---|---|---|---|---|---|
| SEO | 站内 SEO 健康分（内部口径） | 91.5 | 95 | **未复测出可比分数**（脚本 97.0 方法有误、不可比）；见 §4 清单 | 不能声称达成 |
| GEO | GEO 就绪分（内部口径） | 71.5 | 85 | **未打分**；11-26 清单验收：sameAs 未过、FAQPage 覆盖 15/30、CWV 无数据 | 不能声称达成 |
| 外链 | 引荐域 | 2 | ≥8 | 3（Serpstat 11-27），含低质量目录 | 未达成 |
| 外链 | Domain Rank | 8 | 保持/提升 | 10（Serpstat 11-27） | 数值上升，质量存疑 |
| 内容 | 新增/翻新 Insights | 15 篇 | +12（含 3 翻新） | +15 新增（sitemap 30）；翻新 0 有证据 | 新增达成；翻新未达成 |
| 内链 | 集群内链闭环 | 未系统化 | 5 簇闭环 | 文章→商业页、文章↔文章有链接；枢纽→文章 0；30 条 404 | 未达成 |
| 技术 | 结构化数据覆盖 | 部分 | 产品/文章/FAQ/Organization 全覆盖 | 文章 Article 30/30；FAQPage 15/30；产品 Product 86/93；产品 FAQPage 0；Organization 无 sameAs | 未达成 |
| 抓取 | llms.txt + robots + sitemap | 待建/待核 | 100% 上线 | llms.txt 200、robots.txt 200（放行）、sitemap-index 4 子表、sitemap.xml 154 loc | 达成（llms-full.txt 404 为可选） |
| 性能 | Core Web Vitals | — | 计划要求复核 | **未测/无数据**（缺 PSI_API_KEY） | 无法验收 |

## 4. SEO 95 自评（清单式，不打综合分）

| 检查项 | 结果 | 证据 |
|---|---|---|
| 核心页 200 | 通过 | /、/insights、/products、/contact、/oem-odm、/solutions、/sourcing、/faq、/about、/privacy、/terms、/cases、/sitemap 今日均为 200 |
| robots / sitemap | 通过 | robots.txt 200；sitemap-index 4 子表；insights 30、products 93、pages 25；sitemap.xml 154 |
| 文章 title / H1 / canonical | 通过 | 30/30 篇 200、各 1 个 H1、canonical 等于自身 URL |
| 站内断链 | **未通过（新 P1）** | 30 个 404 目标（28 个在 /sitemap，2 个在首页） |
| 空壳 / 薄页 | **未通过（已知 P1）** | 7 个产品短 slug 200、31954 字节、无 title |
| 页脚链接可抓取 | 未通过（P2） | Privacy / Terms / FAQ / Sitemap 是 button，不是链接 |
| 枢纽页内链 | 未通过 | 五个枢纽页首包均不链文章；/insights 首包只链 7 篇 |
| 性能 | 无数据 | 缺 PSI_API_KEY |

**自评结论：** 技术底座稳定（无全站 noindex/5xx，抓取文件齐全）。但存在新发现的站内断链、空壳 URL、枢纽内链缺口，**不能认定达到内部口径 95**。按清单看，修完断链和空壳后才值得重新打分。

## 5. 全站内链终检明细

方法：抓取首页、sitemap-pages 25 个页面、sitemap-insights 30 篇文章的首包 HTML（去重后 55 页），提取全部站内 `<a href>`，逐一请求并记录状态码。

| 指标 | 数值 |
|---|---|
| 来源页 | 55（全部 200） |
| 唯一站内链接目标 | 164 |
| 200 | 134 |
| 404 | **30** |
| 3xx 跳转 | 0 |
| 无入链的文章（孤页） | 0 |
| 产品 sitemap 中站内有链接的 | 86/93（缺的正是 7 个空壳） |

**404 链接来源：**

- **/sitemap（28 条）**：文章链接全部按标题生成。例如 `/insights/hotel-lighting-design-a-b2b-buyers-guide`（实际是 `/insights/hotel-lighting-design-guide`）、`/insights/what-is-ugr-in-office-lighting`（实际是 `/insights/ugr-office-lighting-explained`）。/sitemap 页共列 30 篇，只有 beam-angle-guide-for-commercial-lighting 和 how-to-source-led-lights-from-china 两篇的标题恰好与 slug 一致。根因：`pages/Sitemap.tsx` 第 86 行 `slugify(article.title)`。
- **首页（2 条）**：`/products/advanced-2835-smd-led-strip`（现产品 slug 为 `ultra-bright-2835-smd-led-strip`）、`/products/classic-ashape-led-bulb-e27b22`。根因：`src/data/homeProductPreviews.ts` 第 119、126 行。

**集群链接：**

- 新集群文章（15 篇）站内链向其他文章 5–19 条；链向商业页（含导航）11–19 条，说明正文里有回流商业页的链接。
- 旧文（15 篇）链向其他文章 4–5 条；链向商业页 9 条，即只有导航。
- 枢纽页向下链文章：首页 3 篇；/insights 7 篇；/products、/sourcing、/oem-odm、/solutions、/cases 均为 0。

**修复建议（须用户批准后再改站点）：**

1. Sitemap.tsx 改用文章真实 slug（P1，改动小）。
2. 首页产品预览的两个 slug 改为真实产品 slug，或改为从产品数据读取（P1）。
3. 7 个空壳 URL：从 sitemap 移除，或返回 404/301 到正确产品（P1）。
4. 枢纽页各加 3–6 条同簇文章链接；/insights 首包输出全部文章链接，或做分页链接（P2）。

## 6. 30 天执行回顾

| 阶段 | 完成 | 未完成 / 偏差 |
|---|---|---|
| 技术（D1/D2/D13/D28） | llms.txt、FAQ 页 FAQPage、文章 Article/FAQPage/BreadcrumbList、Privacy/Terms 页面上线 | sameAs、产品 FAQPage、页脚链接、CWV 数据 |
| 内容（D3–D27） | 15 篇集群文章上线（10-30 至 11-14） | 11-19、11-20、11-22、11-23 四篇成稿因无配图未上线；3 篇翻新未做 |
| 内链（D7/D18/D30） | 新文章正文内链与商业页回流 | 枢纽→文章、/insights 分组、/sitemap 断链 |
| 外链（D15/D29） | 11-27 台账 v2 与 10 个目标 | D15 目录提交未执行；未外发；优质引荐域无净增证据 |

**主要瓶颈：配图链路。** qwen-image 今日 401；llm（qwen）401，deepseek 402。11-14 之后没有文章上线。

## 7. 四篇待发成稿状态（2026-11-28）

| 稿件 | 位置 | 配图 | 线上 |
|---|---|---|---|
| commercial-lighting-suppliers-guide（11-19） | 主笔 formore-articles，commit cd2581e | 未到 | 404 |
| led-panel-light-manufacturer-guide（11-20） | 主笔 formore-articles，commit b6ec3f8；category 需由 Sourcing 改为 Technical | 未到 | 404 |
| led-downlight-manufacturer-guide（11-22） | workbench PR #7，未合并 | 未到 | 404 |
| factory-audit-lighting-china-guide（11-23） | workbench PR #8，未合并 | 未到 | 404 |

检查范围：/workspace/design-drafts/（最新目录为 11-14）、画眉 formore-articles 目录（最新为 11-06）、站点仓库、PR #7/#8 分支（各只含 1 个 md 文件）。没有一篇配图齐全，今日未跑 publish:article 校验。

## 8. 下月计划建议（2026-11-29 起，均需用户批准的项已标注）

**优先级 1：先修站点硬伤（需用户批准，建议一个小 PR）**

1. /sitemap 页改用真实 slug，首页两个产品 slug 修正。验收：内链终检 404 = 0。
2. 7 个产品空壳 URL：从 sitemap 移除，或返回 404/301。验收：sitemap-products 全部有 title/H1/canonical。
3. 页脚 Privacy/Terms/FAQ/Sitemap 改成真实链接。

**优先级 2：打通配图，清掉积压**

4. 请用户选一条配图来源：修复 DashScope 密钥/额度、给 deepseek 充值，或批准替代方案（实拍图库/设计师手作）。配图到位后，按 11-19 → 11-20 → 11-22 → 11-23 顺序合审，并按既有自动发布许可校验上线。
5. 积压清掉前不开新简报。

**优先级 3：GEO 补强（需用户批准模板改动）**

6. 旧 15 篇按「可见问答 → FAQPage」翻新 3–5 篇（优先 what-is-cri-in-lighting、beam-angle-guide-for-commercial-lighting、how-to-source-led-lights-from-china）。
7. 用户提供可验证的官方档案 URL（LinkedIn/YouTube 等）后补 Organization sameAs。
8. 产品页 FAQPage 模板化；Insight CTA 路灯套话改为按主题匹配。
9. 枢纽页加同簇文章链接；/insights 首包输出全量文章链接。

**优先级 4：度量与外链**

10. 配置 PSI_API_KEY，拿到 LCP/INP/CLS 实测；更新 daily-seo-check 的任务映射（仍是四月排期）。
11. 外链：用户确认后，从 11-27 台账的 3 个客座目标开始外发；每月复测 Serpstat 引荐域，低质量目录单列不计。
12. 修完优先级 1 后，用同一套清单重新做 SEO/GEO 自评，届时再判断是否达到 95/85。

## 9. 工具与日检（2026-11-28）

| 项 | 状态 |
|---|---|
| /home/box/tools/llm qwen | HTTP 401 Unauthorized |
| /home/box/tools/llm deepseek | HTTP 402 Payment Required |
| /home/box/tools/qwen-image | HTTP 401 Unauthorized |
| npm run seo:daily | exit 0；与 11-27 报告除日期外无差异；PSI 跳过 |

## 10. 证据清单

- `raw/internal-link-check-2026-11-28.json`：内链终检汇总（来源页、目标状态、404 列表、文章入链数、每篇 schema/canonical）。
- `../2026-11-26-geo-review/`：GEO 清单验收与 live-evidence-summary.json。
- `../2026-11-23-seo-geo-audit/`：周报、脚本基线，以及 97.0/72.0 不可比的说明。
- `../2026-11-27-outreach/formorelightings-outreach-ledger-v2.md`：Serpstat 引荐域快照。
- `../../../notes/daily-seo-check/2026-11-28.md`：当日日检与线上抽检。
