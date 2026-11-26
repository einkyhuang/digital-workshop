# Formore Lighting 全站 GEO 复核报告（2026-11-26，Day 28）

| 项 | 内容 |
|---|---|
| 站点 | https://www.formorelightings.com |
| 日期 | 2026-11-26（Asia/Shanghai） |
| 任务 | 30 天计划 Day 28：全站 GEO 复核（FAQPage / sameAs / llms.txt / BLUF 抽检 + Core Web Vitals） |
| 性质 | **只读复核**。今日未改站点、未开 PR、未发布文章。 |
| 对照 | 2026-10-30 完整报告（内部口径 SEO 91.5 / GEO 71.5）；2026-11-23 周报（脚本 97.0 / 72.0 **方法不可直接复现为趋势**，本报告不另打综合分） |
| 方法 | 对线上首包 HTML 做 gzip 抓取与解析，不执行 JavaScript。证据：同目录 live-evidence-summary.json。 |
| 日检 | npm run seo:daily 已跑，站点仓库 main 62bb33e，报告 formorelighting2.0/reports/seo/2026-11-26.md（未提交站点仓库） |

> 本报告不编造 Core Web Vitals / CrUX 分数（缺少 PSI_API_KEY，与 11-23、11-24、11-25 相同）。也不把 10-30 的 71.5 与 11-23 脚本的 72.0 写成「上升/下降 x 分」。85 分目标只按清单验收，不另估一个不可复核的分数。

## 1. 结论（相对 71.5→85 目标）

**不能声称已达到内部口径 GEO 85。** 10-30 之后最实质的进步仍在文章层：15 篇日更集群 Insights 普遍具备 Article + FAQPage + 直接开篇结论（BLUF）+ 列表/表格；/llms.txt 与 /faq 的 FAQPage（10 问）保持可用。挡住 85 分验收的，仍是 11-23 已记录、今日复测未变的结构性缺口：

1. Organization **没有 sameAs**（知识图谱 P1，须先有可验证的对外档案 URL）。
2. Insights **30 篇中仍有 15 篇没有 FAQPage**（多为 10-30 之前的旧文；含 CRI 文与 beam angle 文——可见问答或可见结构与 schema 不一致）。
3. 产品详情页 **86 个正常预渲染 PDP 均无 FAQPage**（抽样页有可见 “Questions buyers usually ask”），另有 **7 个空壳短 slug** 仍无 title / H1 / canonical / JSON-LD。
4. 新集群文章末尾的 **路灯 CTA 套话**仍在（road class / sun hours / pole height / target autonomy），对非路灯主题不友好。
5. **没有**可引用的 LCP / INP / CLS 数据，Core Web Vitals 项无法验收。

今日相对 11-23 / 11-25：**无新的 P0/P1，无新增线上文章**（sitemap-insights 仍为 30 条）。四篇待发稿仍缺配图，未上线。

## 2. 核心页面与抓取

以下地址今日均为 **HTTP 200**（除非另注）：/、/robots.txt、/sitemap.xml、/sitemap-index.xml、/sitemap-insights.xml、/sitemap-pages.xml、/sitemap-products.xml、/sitemap-cases.xml、/llms.txt、/insights、/products、/contact、/oem-odm、/solutions、/sourcing、/faq、/about、/privacy、/terms、/cases、/download。

- /llms-full.txt：**404**（11-23 已记为可选增强，不是严重问题）。
- 待发布 4 个 slug 仍为 **404**（符合预期）：commercial-lighting-suppliers-guide、led-panel-light-manufacturer-guide、led-downlight-manufacturer-guide、factory-audit-lighting-china-guide。

Sitemap 计数：sitemap-index.xml 4 个子文件；sitemap-pages.xml 25；sitemap-insights.xml **30**（与 11-23 至 11-25 一致）；sitemap-products.xml **93**；sitemap-cases.xml 6；汇总 sitemap.xml 154，与分表之和一致。

robots.txt 内容为 User-agent: * 与 Allow: /，并指向 sitemap-index。未单独声明 AI 爬虫规则；当前为全站放行，不是阻断。

页脚 **Privacy Policy / Terms of Service 仍是无 href 的 button**，首页源码中没有指向 /privacy、/terms 的 a 链接。两个页面本身 200，title / H1 / canonical 正确，且已写入 sitemap-pages 与 llms.txt。这与 11-23「部分修复、页脚仍不可抓取、P2」一致。

## 3. GEO 专项清单验收

### 3.1 llms.txt — 通过（有一处可选缺口）

- /llms.txt **200**，纯文本 985 字节，定位仍是 Architectural LED / OEM·ODM / China sourcing。
- Key Pages 含首页、about、contact、products、cases、insights、sourcing、oem-odm、faq、privacy、terms，与站点现况一致。
- 计划验收写的五簇枢纽里，**/solutions 未写入 Key Pages**（11-23 周报已按当时列表视为通过；今日仍视为可选补强，不升为新的严重问题）。
- /llms-full.txt 仍 404。

### 3.2 Organization sameAs — 未通过（已知 P1）

首页 JSON-LD 为 **Organization + WebSite + BreadcrumbList**。Organization 有 name / url / logo / email / telephone / address，**没有 sameAs 字段**。在有核实的 LinkedIn、YouTube、Google Business 等官方档案 URL 并经用户确认之前，不应写入。今日未改站点。

### 3.3 FAQPage 抽检 — 未达到「抽检 10 页全部通过」

| 抽检页 | 结果 | 说明 |
|---|---|---|
| /faq | 通过 | FAQPage，**10** 条 Question + BreadcrumbList |
| /insights/hotel-lighting-design-guide | 通过 | Article + FAQPage(5) + BreadcrumbList，canonical 正确 |
| /insights/retail-lighting-design-guide | 通过 | 同上，FAQPage(5) |
| /insights/human-centric-lighting-guide | 通过 | 同上，FAQPage(5) |
| /insights/led-lighting-manufacturer-guide | 通过 | 同上，FAQPage(5) |
| /insights/3000k-vs-4000k-led | 通过 | 同上，FAQPage(5) |
| /insights/what-is-cri-in-lighting | 未通过 | 可见 “Is CRI 80 good enough?” 等问答，JSON-LD 仅 Article + BreadcrumbList，**无 FAQPage** |
| /insights/beam-angle-guide-for-commercial-lighting | 未通过 | Article + BreadcrumbList，无 FAQPage |
| /insights/how-to-source-led-lights-from-china | 未通过 | Article + BreadcrumbList，无 FAQPage |
| /products/linear-bar-office-suspended-light | 未通过 | 有 Product schema，正文有 “Questions buyers usually ask…”，**无 FAQPage** |

全量统计（今日首包）：

- Insights **30/30** 为 200，均有 Article 与 BreadcrumbList，均有 datePublished。
- 其中 **15/30** 有 FAQPage（14 篇 5 问，UGR 文 3 问）。这 15 篇均是 10-30 之后的日更集群稿（含 UGR）。
- **15/30** 无 FAQPage，均为较早旧文，名单：2026-lighting-trends、beam-angle-guide-for-commercial-lighting、beam-angle-secrets、color-temperature-guide、cri-explained、dimming-guide、future-marketing、how-to-source-led-lights-from-china、led-terminology-guide、lumens-vs-watts、minimalism、navigating-shenzhen、outdoor-lighting、understanding-cri、what-is-cri-in-lighting。
- 产品 sitemap **93/93** 为 200；**86** 个有 Product schema，**0** 个有 FAQPage；**7** 个短 slug 空壳依旧（约 31954 字节，无 title / H1 / canonical / JSON-LD）：/products/solar-panel、/products/inverter、/products/battery、/products/mounting-support、/products/cable、/products/connector、/products/toolkits。

补 FAQPage 或修空壳属于模板/存量改动，**须用户批准**，今日未改。

### 3.4 BLUF — 新集群文章达到「具备直接开篇结论」

抽取每篇 .article-content 中第一条实质正文（跳过作者 byline、目录 “In this guide”、全站页头套话 “From harnessing solar power…” 以及配图说明）。计划口径是首段约 40–60 词、先给结论。

- **15/15** 篇日更集群文章都有直接开篇结论（不是 “In this article will…” 式软开头）。
- 其中 **14/15** 词数在 43–63，落在或紧贴 40–60 词带宽。
- /insights/ugr-office-lighting-explained 首段为 **25** 词，仍是直接定义式结论，但短于 40–60 词目标。
- 15 篇旧文里，多数也有短而直接的开头；4 篇首段不足 25 词（beam-angle-secrets、cri-explained、led-terminology-guide、outdoor-lighting），更偏口号而非完整 BLUF。

示例（酒店文首段，46 词）：Hotel lighting design is a layered specification process that balances guest comfort, brand identity, and operational efficiency. …

### 3.5 列表 / 表格

- Insights **30/30** 至少有 1 个列表（ul 或 ol）。
- **12/30** 有 table，几乎都在日更集群稿中。部分设计/旧科普文只用列表，没有参数对比表。计划「每篇 ≥1 表或 ≥1 列表」按此口径 **30/30 通过**。

### 3.6 权威引用与 Core Web Vitals

- 今日未逐条复测 IES / CIE / ENERGY STAR 等外链状态（11-23 也未对每条外链重测）。不在本报告里声称「全部外链 200」。
- npm run seo:daily 对首页、/products、/sourcing、/insights 的 PSI 均跳过：Missing PSI_API_KEY。与昨日报告相比仅日期变化。**不给出任何 LCP / INP / CLS 或性能分数。**

## 4. 已上线文章抽检（schema / 标题 / canonical）

抽检酒店、零售、人因照明等已上线日更文：HTTP 200，title 与 canonical 正确（canonical 与地址一致），首包含 Article + FAQPage + BreadcrumbList。30 篇 Insights 的 canonical 全部与自身 URL 对齐。

完整 title（含 “ | Formore”）超过 60 个字符的旧题仍在，例如 what-is-cri-in-lighting（77）、2026-lighting-trends（70）、color-temperature-guide（71）等。11-23 已列为 P2「过长 Title」；今日未改标题。日更集群稿去掉站名后缀后，标题本身均在 60 字符以内。

15 篇日更文（以及 UGR）源码中仍能匹配路灯 CTA 套话，与既有日检记录一致，改模板须批准。

## 5. 建议（均须批准，今日不动站点）

按 11-23 周计划排队，不与发文混在同一个未批准 PR 里：

1. **P1 空壳产品 URL**：处理或从 sitemap 移除上述 7 个短 slug。
2. **P1 sameAs**：用户提供或确认真实对外档案 URL 后再写入 Organization。
3. **P2**：产品页可见 FAQ 补 FAQPage；旧 Insights（优先 CRI、beam angle、China sourcing）补 FAQPage；页脚 Privacy/Terms 改为可抓取的链接；非路灯文章去掉路灯 CTA 套话；过长 Title；配置 PSI 密钥以便验收 CWV。
4. 可选：llms.txt 补上 /solutions；视需要增加 /llms-full.txt。

内容侧：四篇成稿（11-19 供应商、11-20 面板、11-22 筒灯、11-23 验厂）仍待配图，无合格配图不发布，也不新开第五篇独立文章，不复活已取消的 led-lighting-manufacturer-china-guide。11-20 合审时须把 category 从 Sourcing 改为 Technical。

## 6. 文件

| 文件 | 说明 |
|---|---|
| 本文件 | Markdown 报告 |
| formorelightings-geo-review.html | 同内容 HTML 版 |
| live-evidence-summary.json | 今日首包抓取摘要（核心页、30 篇 Insights、产品计数与空壳、BLUF 摘录） |
