# Formore Lighting SEO+GEO 双轨深度体检报告

## 一、受检目标与体检时间

- **受检站点**：https://www.formorelightings.com
- **站点定位**：Architectural LED Lighting Manufacturer / OEM ODM / China Sourcing Partner
- **体检时间**：2026-10-30 02:21（Asia/Shanghai）
- **技术栈**：React19 + Vite + SSR 预渲染（Vercel），线上 HTML 含 H1、正文与 Schema，非纯 CSR 空壳
- **数据来源说明**：
  - 自动化抓取与评分：SeoHub `audit.py`（得分、TTFB、字数、链接、Schema 抽取、robots、sitemap 等）
  - 人工复核：逐页核对导航结构、页脚链接、Schema 字段、压缩头、内容路径（含 `src/data/articles.tsx` 与 `content/insights` 的优先级确认）
  - 关键词与外链：Serpstat（via Treg）实测 US 词库与外链快照
  - 注：自动化脚本存在已知误报，详见「修正说明」

## 二、双轨评分卡

| 轨道 | 得分 | 判定 | 一句话结论 |
|---|---|---|---|
| 传统 SEO | **91.5 / 100** | 优秀（A-） | 抓取、架构、元数据、内容基础扎实，短板在外链与合规页 |
| GEO（生成式引擎优化） | **71.5 / 100** | 良好偏低（B-） | 机器可读基础尚可，但 llms.txt、sameAs、可引用性与 FAQ 结构化缺口明显 |
| **综合** | **81.5 / 100** | 良好 | 传统 SEO 已接近天花板，GEO 是下一阶段主战场 |

## 三、修正说明（自动化误报与人工复核结论）

1. **压缩误报**：audit 脚本报「Uncompressed」，实测响应头 `Content-Encoding: br`（Brotli 已生效），该项不计入扣分。
2. **导航误报**：About / Contact 在 Navbar 与 Footer 均存在可点击链接（/about、/contact），非缺失项。
3. **合规页真实缺陷**：页脚 Privacy 为**不可点击的 span**，且 `/privacy`、`/terms`、`/privacy-policy`、`/terms-of-service` 全部返回 404——此为真实问题，保留扣分。
4. **内容路径**：线上文章实际由 `src/data/articles.tsx`（React BlogPost）渲染，`content/insights` 的 Markdown 为次级/遗留模板，内容维护应以生产路径为准。

## 四、传统 SEO 六大维度

| 维度 | 状态 | 关键观测 | 备注 |
|---|---|---|---|
| 抓取与索引 | ✅ | robots `Allow: /` + `Sitemap: sitemap-index.xml`；sitemap 含 23 页 / 15 洞察 / 93 产品 / 案例 | 索引通路完整 |
| 站点架构 | ✅ | 首页 29 条内链，产品-案例-洞察三层清晰；About/Contact 可达 | 内链密度健康 |
| 性能 | ⚠️ | TTFB 923.9ms（偏高）；HTML 101.7KB；30 张图片 | CrUX/PSI 本次未测（见第八节） |
| 元数据 | ⚠️ | Title 77 字符（超建议长度）；H1 与正文正常 | 需缩短 Title |
| 内容 | ✅ | 首页 704 词；15 篇线上洞察；产品页与案例齐备 | 内容量达标，深度可再加强 |
| 外链 | ❌ | Serpstat：2 backlinks / 2 referring domains / DR 8 | 最大短板，见第七章 |

## 五、GEO 五大支柱明细

| 支柱 | 状态 | 实测证据 | 缺口 |
|---|---|---|---|
| AI 爬虫可访问性 | ⚠️ | robots 全站 Allow，无 AI 爬虫封禁；但 `/llms.txt` 返回 **404** | 缺 llms.txt 站点导航入口 |
| 机器可读性 | ✅ | SSR 预渲染，HTML 内含 H1/正文/Schema，非空壳；br 压缩 | 可进一步精简 DOM 与首屏载荷 |
| 结构化数据 | ⚠️ | 首页有 Organization / WebSite / BreadcrumbList；PDP 有 Product；Article 含作者组织与日期 | 缺 `sameAs`、缺首页 FAQPage、FAQ 页仅有 BreadcrumbList 无 FAQPage、Organization 缺 author/dateModified |
| 可引用性 | ❌ | 首页缺列表/表格、缺权威外链引用（首页外链 0）、BLUF（结论前置）不足 | AI 引用友好度低，需结构化摘要与对比表 |
| E-E-A-T | ⚠️ | 有 Organization 与 Article 作者组织 | 缺 Privacy/Terms 信任页、缺 sameAs 实体锚点、缺作者署名与资质明示 |

## 六、关键词与外链专章

### 6.1 Serpstat 实测关键词（US）

| 关键词 | 月搜索量 | 难度 | 意图 |
|---|---|---|---|
| solar street light | 8,100 | 1 | informational |
| commercial led lighting | 1,900 | 51 | informational |
| led lighting manufacturer | 1,000 | 59 | commercial |
| led linear light | 1,000 | 21 | informational |
| what is cri in lighting | 880 | 27 | informational |
| commercial track light | 590 | 27 | commercial |
| magnetic track lighting | 480 | 12 | informational |
| magnetic track light | 390 | 12 | informational |
| 3000k vs 4000k | 390 | 14 | informational |
| architectural led lighting | 260 | 19 | commercial |
| solar street light manufacturer | 260 | 19 | navigational |
| led flood light manufacturer | 260 | 29 | informational |
| commercial lighting suppliers | 260 | 61 | commercial |
| human centric lighting | 210 | 4 | informational |
| led lighting manufacturer china | 140 | 14 | commercial |
| beam angle lighting | 140 | 4 | informational |
| office lighting design | 140 | 6 | informational |
| cri 90 led | 90 | 10 | informational |
| retail lighting design | 50 | 16 | commercial |
| hotel lighting design | 30 | 8 | informational |
| led downlight manufacturer | 20 | 5 | informational |
| led panel light manufacturer | 20 | 22 | informational |
| china lighting factory | 10 | 3 | informational |
| led ugr | 10 | — | informational |
| ugr office lighting | 1 | 1 | — |

### 6.2 无 Serpstat 行的长尾词（建议自建追踪）

`oem led lighting manufacturer`、`odm lighting manufacturer`、`lighting sourcing agent`、`lighting sourcing agent in china`、`how to source led lights from china`、`architectural lighting supplier`、`lighting oem odm`、`oem vs odm lighting`、`magnetic track light supplier`、`led linear light manufacturer`、`factory audit lighting china`、`led downlight oem`、`track light system supplier`

> 这批词搜索量未被 Serpstat US 库覆盖，但商业意图更强、竞争更低，是 OEM/ODM 与 China Sourcing 定位的核心转化词，建议以专题页 + 对比表 + 报价 CTA 承接。

### 6.3 外链快照（Serpstat）

| 指标 | 数值 |
|---|---|
| Domain Rank | 8 |
| Backlinks | 2 |
| Referring Domains | 2 |
| Dofollow | 2 |
| Nofollow | 0 |

结论：外链资产近乎为零，DR 8 属新站水平，是当前 SEO 分数中最大的单点风险。

## 七、不可测项

- **CrUX / PageSpeed Insights**：本次运行无 API Key，且未鉴权请求返回 403，**未测**。TTFB 923.9ms 仅来自单次抓取，CWV（LCP/INP/CLS）结论待补。
- 建议补测方式：申请 PSI API Key 后按 URL 批量拉取，或接入 CrUX BigQuery 数据集做 28 天滚动。

## 八、Top 5 问题（一行一条）

1. `/llms.txt` 404，AI 搜索引擎缺少站点级导航入口。
2. Organization Schema 无 `sameAs`，品牌实体未接入知识图谱。
3. 外链极弱（2 backlinks / 2 referring domains / DR 8），域名权威度不足。
4. GEO 可引用性不足：首页缺列表/表格与权威外链引用、BLUF 不足，FAQ 页无 FAQPage Schema。
5. 合规与信任缺口叠加技术细节：Privacy/Terms 404、首页 Title 77 字符过长、TTFB ~924ms 偏高。

## 九、Action Plan

### P0（1–2 周内，立即执行）

**1) 新建 `/llms.txt`（业务定位必须为 Architectural LED / OEM ODM / China Sourcing，禁止写入 outdoor gear 等无关品类）**

```
# Formore Lighting
> Architectural LED lighting manufacturer and OEM/ODM sourcing partner based in China.

## Core Business
- Architectural LED lighting (linear, track, downlight, panel, flood)
- OEM / ODM manufacturing for lighting brands and specifiers
- China sourcing partner: factory audit, sampling, QC, consolidation

## Key Pages
- /about
- /contact
- /products
- /cases
- /insights
- /privacy
- /terms

## Contact
- Sourcing & OEM inquiries: /contact
```

**2) 为 Organization 补 `sameAs`（接入知识图谱实体）**

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Formore Lighting",
  "url": "https://www.formorelightings.com",
  "logo": "https://www.formorelightings.com/logo.png",
  "sameAs": [
    "https://www.linkedin.com/company/formore-lighting",
    "https://www.alibaba.com/showroom/formore-lighting.html",
    "https://twitter.com/formorelighting",
    "https://www.youtube.com/@formorelighting"
  ]
}
```

**3) 上线 Privacy / Terms 真实页面**，并将页脚 span 改为可点击链接（/privacy、/terms），保持内容可被索引。

**4) 缩短首页 Title（≤60 字符）**

```
原：Architectural LED Lighting Manufacturer & Sourcing Partner | Formore Lighting（77）
改：Architectural LED Lighting Manufacturer | Formore（48）
```

**5) TTFB 治理**：Vercel Edge Cache / ISR 策略 + 首屏图片懒加载与 AVIF/WebP，目标 TTFB < 400ms。

### P1（3–6 周）

**6) FAQ 页补 FAQPage Schema**

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is the difference between OEM and ODM lighting?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "OEM lighting is built to your specification and brand; ODM lighting is a manufacturer-designed product you rebrand. Formore supports both models with factory audit, sampling and QC."
      }
    },
    {
      "@type": "Question",
      "name": "How do I source architectural LED lighting from China?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Define spec (CCT, CRI, UGR, beam angle), request samples, audit the factory, and lock QC milestones. Formore acts as your sourcing partner across these steps."
      }
    }
  ]
}
```

**7) 首页与关键页提升可引用性**：增加对比表（OEM vs ODM、3000K vs 4000K、CRI 80 vs 90）、要点列表与 BLUF 摘要段；每页加入 2–3 条权威外链引用（IES、CIE、ENERGY STAR、UL）。

**8) 为 Organization 补 `author` / `dateModified`**，Article 统一署名作者组织，强化 E-E-A-T。

**9) 长尾专题页建设**：围绕 6.2 节 13 个长尾词建立 OEM/ODM/Sourcing 专题页，每页配对比表、报价 CTA 与 FAQ 区块。

### P2（7–12 周）

**10) 外链获取**：目标 90 天内 referring domains 从 2 提升至 30+。路径：行业目录（ArchDaily、Dezeen 供应商库）、照明协会会员页、B2B 平台店铺互链、客座文章与工厂探访报道。

**11) CWV 正式测量**：接入 PSI API Key 与 CrUX 数据集，建立月度 CWV 看板。

**12) 内容升级**：15 篇线上洞察按「问题—数据—结论」重构，附表格与引用，提升 AI 引用命中率。

## 十、技术栈备注

线上为 React19 + Vite + SSR 预渲染（Vercel），抓取到的 HTML 已包含 H1、正文与 Schema，**非纯 CSR 空壳**，AI 爬虫与搜索引擎可直接解析，这是当前 GEO 得分能达 71.5 的基础。后续优化应在保持 SSR 预渲染的前提下进行，避免回退到客户端渲染。
