# Formore CTA 与产品页 FAQPage 改稿方案（不上线）

> **需用户批准后才能上线。** 本文只是改稿方案，未改动 `/workspace/formorelighting2.0` 仓库，未开 PR，也未发布到 https://www.formorelightings.com 。

- **日期**：2026-11-13（Asia/Shanghai）
- **问题来源**：`bots/网站项目/Super-SEO-Hub/notes/daily-seo-check/2026-11-13.md`；既有计划见 `bots/网站项目/Super-SEO-Hub/deliverables/formorelightings/formorelightings-seo-geo-optimization-plan.md`（Day13：2026-11-11「产品页 Product schema + FAQPage 批量补齐」，到期未做）。
- **线上抽检时间**：2026-11-13 晚间，curl 打开下列页面，均为 HTTP 200：
  - https://www.formorelightings.com/insights/office-lighting-design-guide
  - https://www.formorelightings.com/insights/led-flood-light-manufacturer-guide
  - https://www.formorelightings.com/insights/solar-street-light-manufacturer-guide
  - https://www.formorelightings.com/products/linear-bar-office-suspended-light
- **站点仓库**：`/workspace/formorelighting2.0`，当时 `main` 在 `c9e5f04`（只读，未提交、未推送）。

---

## 1. Insights 文章 CTA：路灯模板残留

### 1.1 线上现状

三篇已发布 Insights 页的 CTA 正文都是同一句（办公室设计、投光灯制造商、太阳能路灯制造商皆如此）：

> Tell us your road class, sun hours, pole height, and target autonomy — or browse matching models and request a sample.

标题为 “Ready to Specify Your Project?”，按钮为 Contact us / Browse products。  
这对太阳能路灯文章勉强说得通，但出现在《Office Lighting Design》和投光灯制造商指南里，会让买家以为 Formore 在推销太阳能路灯参数（道路等级、日照小时、灯杆高度、目标续航），和站点主业（建筑/商业 LED）不一致。

办公室文章页本身的 JSON-LD 已有 Article + FAQPage + BreadcrumbList，问题出在可见 CTA 文案，不是文章 FAQ。

### 1.2 文案写在哪里

主因不在单篇 Markdown，而在增强函数把 CTA **统一覆盖成路灯默认句**。

文件：`/workspace/formorelighting2.0/utils/enhanceArticleHtml.ts`

- 约第 141–144 行：初始默认值就是这句 `road class, sun hours, pole height, and target autonomy`。
- 约第 174–198 行：若正文里出现 “Ready to specify your project?” 或 “Next step” 小节，函数会先尝试清洗正文，随即**无条件再赋值为同一句路灯文案**（注释写 “Prefer clean CTA copy”）。因此即使稿件已写过适合建筑/商业项目的收尾，线上仍会显示路灯句。

页面渲染：`/workspace/formorelighting2.0/pages/Article.tsx` 中的 `ArticleCtaBox` 直接输出 `enhanced.ctaText`。

对照：`/workspace/formorelighting2.0/scripts/lib/markdown-article.mjs` 约第 418 行，生成稿里的 CTA 已是较中性的句子：

> Share your project details with Formore Lighting, or browse matching models and request a sample.

这句随后被 `enhanceArticleHtml.ts` 盖掉，所以发布流水线里「稿件 CTA」和「线上 CTA」不一致。

### 1.3 建议替换（默认句，适用于绝大多数建筑/商业文章）

建议把上述两处默认值（初始值 + 无条件覆盖）改成同一句，语气与现有 B2B 询盘习惯一致，去掉路灯参数：

**标题（可保留）**：Ready to specify your project?

**正文（建议）**：

> Tell us the application, mounting type, visual targets (lux, UGR, CCT/CRI), and dimming or control protocol — or browse matching models and request a sample.

按钮仍指向 `/contact` 与 `/products`，不必改结构。

备选更短句（若希望与 `markdown-article.mjs` 对齐）：

> Share your project type, mounting condition, and specification targets with Formore Lighting, or browse matching models and request a sample.

### 1.4 太阳能路灯文章的例外（建议，可选）

https://www.formorelightings.com/insights/solar-street-light-manufacturer-guide 目前也是同一句。若希望太阳能稿保留道路参数，应做成**按文章或标签分支**，而不是继续用全局默认：

- 默认：上一节的建筑/商业 LED 文案。
- 仅当文章 slug/标签属于 solar street light 时，才使用 road class / sun hours / pole height / target autonomy。

不要再让办公室、磁吸轨道、筒灯、制造商指南去借用路灯参数。

### 1.5 建议改动范围（批准前不动手）

1. 修改 `utils/enhanceArticleHtml.ts` 的默认值，并删除或改写第 197–198 行附近的无条件覆盖；若要保留清洗逻辑，应采用清洗后的正文，只有在正文过短时才回退到新的默认句。
2. 如需与生成脚本一致，同步 `scripts/lib/markdown-article.mjs`。
3. 用办公室文章、投光灯文章、太阳能路灯文章各抽检一次可见 CTA 与源码。
4. **仍需用户批准后再提交 PR 并发布。**

---

## 2. 产品页 FAQPage JSON-LD（Day13 未完成项）

### 2.1 线上现状（以 Linear Bar 为例）

打开 https://www.formorelightings.com/products/linear-bar-office-suspended-light 后，JSON-LD 只有：

- `BreadcrumbList`
- `Product`（含 Brand `Formore Lighting`，sku `239`，category `Pendant Light`）

**没有 `FAQPage`。** 这与 11-13 日检和优化计划 Day13 的描述一致。

页面底部已有可见模块 “Buyer FAQ / Questions buyers usually ask before sampling or ordering”，当前两问来自默认画像，不是该 SKU 的专用问答：

1. Can this product be customized for OEM or ODM projects?  
   In most cases, yes. Packaging, finish, selected specs, and branding can be adjusted once the target market and order scope are defined.
2. What should a buyer confirm before production?  
   Confirm the approved sample, specification sheet, compliance target, packaging, and delivery timeline before paying the production deposit.

可见 FAQ 与 JSON-LD 不同步：人能看到问答，搜索引擎结构化数据里没有 FAQPage。

### 2.2 代码已具备、但未接线

| 位置 | 现状 |
|---|---|
| `/workspace/formorelighting2.0/src/seo/schema.ts` 中 `buildFaqPageSchema` | 已存在，文章页已在用。 |
| `/workspace/formorelighting2.0/pages/ProductDetail.tsx` 约 123–141 行 | `schema` 只组装 BreadcrumbList + Product，**未调用** `buildFaqPageSchema`。 |
| 同文件约 488–503 行 | 若有 `seoProfile`，会渲染可见 Buyer FAQ。 |
| `/workspace/formorelighting2.0/src/data/productSeoProfiles.ts` | 约 10 个具体产品有专用 `faq` 数组；`linear-bar-office-suspended-light` **不在**其中，走到 `DEFAULT_PROFILE`（只有上面两问）。`getProductSeoProfile()` 对所有产品都会返回画像，所以默认 FAQ 会出现在大量未单独配置的产品页上。 |

也就是说：Day13 要补的不是从零写 schema 函数，而是把已有 FAQ 接入产品页 JSON-LD，并为主力 SKU 补上至少 3 组与可见内容一致的问答。优化计划要求「每个产品线页至少 3 组 Q&A，FAQPage 与可见内容一致」。

### 2.3 建议改法（批准前不改仓库）

1. 在 `ProductDetail.tsx` 的 `schema` 中，当 `seoProfile.faq` 非空时追加 `buildFaqPageSchema(seoProfile.faq)`，并补上 `buildFaqPageSchema` 的 import。
2. 把 `DEFAULT_PROFILE.faq` 扩到 3–5 问，避免未单独配置的产品页只有两问、也缺乏产品语境。
3. 为办公线性吊灯等主力产品增加专用 profile（slug：`linear-bar-office-suspended-light`），问答必须与页面可见文本逐字一致。
4. 抽检：`/products/linear-bar-office-suspended-light` 以及已有专用 profile 的一款筒灯/轨道灯，确认 Product + FAQPage + BreadcrumbList 同时存在，且问答与可见模块一致。
5. **需用户批准后再开 PR 上线。**

### 2.4 办公线性吊灯 FAQ 草稿（供写入专用 profile）

以下为建议稿，上线前需与产品规格再核对，避免写成未经验证的性能承诺。可见模块与 JSON-LD 使用同一组文本。

1. **What is a linear bar office suspended light used for?**  
   It is typically specified as the ambient layer over open-plan workstations or long desk rows. Direct/indirect options can be considered when the brief calls for both downward task lighting and some upward ceiling light.

2. **Which specification items should be confirmed before sampling?**  
   Confirm mounting type and suspension length, length/wattage configuration, CCT and CRI, glare or UGR target, dimming protocol, and whether IES or LM photometric files are required for the layout.

3. **Can this fixture be customized for OEM or ODM projects?**  
   In most cases, yes. Finish, length configuration, CCT, optics, driver/dimming options, and packaging or labeling can be reviewed once the project and order scope are defined.

4. **What should a buyer confirm before production?**  
   Confirm the approved sample, specification sheet, compliance documents for the target market, packaging, and delivery timeline before paying the production deposit.

5. **Where can I see application guidance?**  
   For zoning and fixture-family context, see the office lighting design guide and the LED linear light guide, then request a sample or a quotation from the contact page.

（第 5 问若采用，页面可见区需同时给出对应内链，避免 schema 里有、正文没有。）

默认 profile 可在现有两问之外补两问，例如 “Do you provide photometric files?” 与 “What information should be included in an RFQ?”，表述保持「按项目提供 / 需在下单前确认目标市场」，不要编造认证或交期数字。现有专用 profile 里的交期、MOQ 表述若要进入 FAQ，应先与业务口径核对。

---

## 3. 验收清单（上线后由巡逻官或搜搜抽检）

- 办公室 Insights：CTA 不再出现 road class / sun hours / pole height / target autonomy。
- 太阳能路灯 Insights：若批准保留分支，参数句只出现在该类文章。
- 产品页：Product schema 仍在；新增 FAQPage；问答数量 ≥3；与 Buyer FAQ 可见文本一致。
- 不在未批准的情况下改直播站点或强制合并。

## 4. 结论

两项都是已知低优先级技术债，根因清楚、改动面小，但都涉及线上文案与结构化数据，**必须用户批准后再上线**。本方案不构成已实施变更。
