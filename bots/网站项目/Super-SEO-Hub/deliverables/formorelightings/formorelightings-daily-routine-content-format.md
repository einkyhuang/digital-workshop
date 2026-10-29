# Formore Lighting 每日 SEO 例程规范（草稿目录 · 内容格式 · 日检命令）

> 适用站点：https://www.formorelightings.com  
> 源码仓库：`einkyhuang/formorelighting2.0`（本机克隆可放 `/workspace/formorelighting2.0`）  
> 约束：**禁止自动合并到 `main`、禁止自动部署/上线**；发布须用户明确批准。  
> 协作：SEO 专家出关键词简报 → 墨墨-主笔写英文文章 → SEO 专家审稿并转成站点格式 → 用户批准后才合并。

---

## 1. 草稿存放位置（分支 + 目录）

| 项 | 约定 |
|---|---|
| Git 分支 | **`seo-drafts`**（从最新 `main` 拉取创建；长期存在，不直接推生产） |
| Markdown 草稿目录 | **`content/insights/drafts/`**（按日期+slug 命名） |
| 简报目录（可选） | `content/insights/briefs/YYYY-MM-DD-<slug>.brief.md` |
| 日检报告目录 | 仓库内 `reports/seo/YYYY-MM-DD.md`（由 `daily-seo-check.mjs` 写出） |
| 工作台交付归档 | `超级工作台/bots/网站项目/Super-SEO-Hub/deliverables/formorelightings/` |

### 草稿文件命名

```text
content/insights/drafts/YYYY-MM-DD-<slug>.md
# 例：content/insights/drafts/2026-11-04-what-is-cri-in-lighting.md
```

`slug` 须与上线后 URL `/insights/<slug>` 一致（小写、连字符）。

### 从草稿到生产的路径（重要）

线上 Insights **实际渲染源**是：

- **主路径（生产）**：`src/data/articles.tsx` 中的 `ARTICLES` 数组（`BlogPost`，`content` 为 React 节点）
- **本地回退**：`utils/contentLookup.ts` → `getLocalArticles()` 读上述数组
- **可选远程 CMS**：`services/cmsApi.ts`（`VITE_ENABLE_REMOTE_CMS`）；字段见下文 CmsArticle
- **遗留/辅助**：`content/insights/{tech,design,trends}/*.md` + `_TEMPLATE.md`（模板仍有效，但**不能**单独靠放 md 就上线）

因此每日流程是：

1. 墨墨在 `seo-drafts` 分支写 Markdown 草稿（见第 2 节 frontmatter）。
2. SEO 专家审稿通过后，把定稿 **转换/写入** `src/data/articles.tsx`（或经用户批准的 CMS），并补 Related Products / 商业回流模块。
3. 跑 `npm run sitemap`（或完整 `npm run build` 中的 generate-sitemap）更新 sitemap。
4. **开 PR → 用户批准 → 合并 main → 部署**。未批准不得推 main、不得发布。

---

## 2. 文章必须遵守的内容格式

### 2.1 Markdown 草稿 Frontmatter（必填）

与 `content/insights/_TEMPLATE.md` 对齐，并扩展 SEO 字段：

```yaml
---
title: "Article Title Here"           # H1 / SERP 标题基础，建议 ≤60 字符含主词
author: "Formore Research"            # 或具体人名；须与 Schema author 一致
date: "YYYY-MM-DD"                    # 发布日
category: "Technical"                 # Trends | Design | Technical | Projects | Company News
readTime: "7 min"
image: "/insights image/insights feature images/<file>.webp"
excerpt: "120–160 字符摘要，含主关键词与行动主张"
tags: ["Tag1", "Tag2", "Tag3"]
featured: false
# —— 以下为 SEO 例程扩展字段（草稿必填；转入 articles.tsx 时同步）——
slug: "what-is-cri-in-lighting"       # = id；URL /insights/<slug>
primaryKeyword: "what is cri in lighting"
secondaryKeywords: ["cri 90 led", "color rendering index"]
searchIntent: "informational"         # informational | commercial | transactional | navigational
internalLinks:
  - anchor: "LED linear lights"
    url: "/products"
  - anchor: "China lighting sourcing"
    url: "/sourcing"
businessReturnUrl: "/products"        # 商业回流页
faq:
  - q: "What is CRI in lighting?"
    a: "CRI measures how accurately a light source reveals colors compared with daylight."
schemaType: "Article"                 # Article | FAQPage (附加) | HowTo
status: "draft"                       # draft | review | approved | published
---
```

正文要求（GEO）：

1. **单一 H1**（可用 frontmatter title；正文勿再重复第二 H1）。
2. **BLUF**：每个 H2 下第一段 40–60 词直接给结论/定义。
3. **疑问句式 H2** 至少 2 个（匹配 AI Prompt）。
4. **原生列表或表格**至少 1 组；**权威外链引用**至少 2 条（IES / CIE / ENERGY STAR / DLC / UL 等）。
5. 篇幅建议 **800–1800 英文词**（可抽取区间）。
6. 文末含 Related Products / CTA 指向 `businessReturnUrl`。

### 2.2 生产格式：`src/data/articles.tsx`（BlogPost）

```ts
export interface BlogPost {
  id: string;                 // = slug，如 'what-is-cri-in-lighting'
  title: string;
  excerpt: string;
  content: React.ReactNode;   // JSX：h2/p/ul/ol/table
  author: string;
  date: string;               // 展示用，如 "Apr 13, 2026"
  category: string;           // Technical | Design | Trends | ...
  readTime: string;           // "7 min"
  image: string;              // 资产路径或 R2 URL
  tags: string[];
  featured: boolean;
}
```

`getLocalArticles()` 会把 `id` 映射为 `slug`。路由：`/insights/:slug`（见 `App.tsx`）。

### 2.3 CMS 映射（若启用远程 CMS）

`CmsArticle` 字段：`id, slug, title, excerpt, content, author, date, category, readTime, image, tags, featured`。  
远程条目需 `status === 1` 才会展示。

### 2.4 交给墨墨的「文章简报」最小模板

每天例程为当日关键词生成一份简报（可放 `content/insights/briefs/`）：

```markdown
# Brief: <primaryKeyword>
- 日期：YYYY-MM-DD
- 目标 URL：/insights/<slug>
- 主关键词 / 次关键词 / 意图
- 建议 Title（≤60）与 Meta Description（120–160）
- H2 大纲（4–7 个，含疑问句）
- 必须内链（锚文本 → URL，2–3 条）
- 商业回流页
- FAQ（≥3）
- Schema 要求（Article + FAQPage）
- 需引用的权威来源
- 禁忌：禁止合并 main / 禁止自行部署
```

---

## 3. 每日 SEO 检查如何跑

### 3.1 仓库脚本

```bash
cd /workspace/formorelighting2.0   # 或本机仓库路径
# 可选：导出 PSI_API_KEY 后才有真实 Lighthouse 分数；无 Key 会 skipped
export SITE_URL=https://www.formorelightings.com
export SEO_TASK_DATE=$(date +%F)          # Asia/Shanghai 日历日
# export PSI_API_KEY=...                  # 有则填；无则报告标注 skipped
npm run seo:daily
# 等价：node scripts/daily-seo-check.mjs
```

输出：`reports/seo/<SEO_TASK_DATE>.md`  
检查 URL：`/`、`/products`、`/sourcing`、`/insights`。  
阈值 95 分以下时进程 `exitCode=1`（用于例程告警，不代表自动修复）。

将 Markdown 转 HTML 报告（可选）：

```bash
npm run seo:report-html -- reports/seo/<date>.md
```

### 3.2 双轨深度体检（SeoHub，按需/周更）

```bash
python3 /home/box/agent-data/workflows/seohub/scripts/audit.py \
  https://www.formorelightings.com \
  --output-dir /workspace/超级工作台/bots/网站项目/Super-SEO-Hub/deliverables/formorelightings
```

### 3.3 例程每日标准动作清单

1. `git fetch` + 在 `seo-drafts` 上工作（或从 main 开当日短分支再并回 `seo-drafts`）。
2. 跑 `npm run seo:daily`，把报告复制/摘要到工作台 deliverables（可选）。
3. 按《SEO+GEO 优化计划》当日排期：选关键词 → 写 Brief → 发给墨墨。
4. 收到英文稿后审稿（关键词、内链、FAQ、schema、BLUF、外链引用）。
5. 定稿写入 `content/insights/drafts/`；批准上线时再写入 `src/data/articles.tsx` 并开 PR。
6. **停止点**：开 PR 后等待用户批准；不合并、不部署。

---

## 4. 与优化计划的衔接

- 30 日关键词与每日任务见同目录：`formorelightings-seo-geo-optimization-plan.md` §5。
- 体检基线见：`formorelightings-seo-geo-audit-report.md`（SEO 91.5 / GEO 71.5）。
- P0 技术项（llms.txt、sameAs、Privacy/Terms、Title 缩短）优先于纯内容日，可占用 Day1–2 / Day13 / Day28。

---

## 5. 变更记录

| 日期 | 说明 |
|---|---|
| 2026-10-30 | 初版：确定 `seo-drafts` + `content/insights/drafts/`、articles.tsx 生产格式、daily-seo-check 用法 |
