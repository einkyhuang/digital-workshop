# Formore Lighting — Insights publish pipeline

For **搜搜-SEO专家** daily routine and 墨墨 / frontend handoff.

## Goal

Turn an approved Markdown draft in `content/insights/drafts/` into a prerendered, SEO-complete Insights page, without deploying until the user explicitly approves a `main` push.

## Draft location & naming

```text
content/insights/drafts/YYYY-MM-DD-<slug>.md
```

Frontmatter must follow:

`超级工作台/bots/网站项目/Super-SEO-Hub/deliverables/formorelightings/formorelightings-daily-routine-content-format.md`

Required fields include: `title` (≤60), `slug`, `excerpt`, `date`, `category`, `author`, `image`, `faq`, `internalLinks`, `businessReturnUrl`, `status`.

## What the pipeline does

```bash
npm run publish:article -- <slug>
```

1. Parses the draft frontmatter + body  
2. Converts Markdown → HTML  
3. Upserts `src/data/publishedArticles.json` (merged ahead of hand-written `src/data/articles.tsx` entries)  
4. Runs `npm run build` (sitemap + Vite client build + SSR + prerender)  
5. Validates local prerendered HTML:
   - file present (local “200”)
   - title length / uniqueness
   - meta description, canonical, OG tags
   - single H1, ≥2 H2
   - Article + BreadcrumbList JSON-LD (and FAQPage when FAQ exists)
   - image alt attributes
   - internal links resolve against `dist/`
6. Writes `reports/publish/<slug>.json`

### Git / deploy safety

| Command | Effect |
|---|---|
| `npm run publish:article -- <slug>` | Convert + build + validate only |
| `… --commit` | Also creates a **local** git commit |
| `… --commit --push` | **Refused** unless `PUBLISH_ALLOW_MAIN=1` and branch is `main` |

Production host is **Vercel** (`www.formorelightings.com`). Pushing `main` triggers the live deploy. Preview deploys may appear for non-`main` branches depending on the Vercel project setting.

**Never** set `PUBLISH_ALLOW_MAIN=1` without the user’s explicit approval to go live.

## After user approval (go live)

```bash
git checkout main
git merge seo-publish-pipeline   # or merge the PR
PUBLISH_ALLOW_MAIN=1 npm run publish:article -- <slug> --commit --push
# or: merge PR → push main once validation already passed on the branch
```

Live URL shape:

```text
https://www.formorelightings.com/insights/<slug>
```

## Sample used in this branch

- Draft: `content/insights/drafts/2026-10-30-ugr-office-lighting-explained.md`
- Slug: `ugr-office-lighting-explained`
- Intended live URL (after main deploy): `https://www.formorelightings.com/insights/ugr-office-lighting-explained`

## Related technical SEO fixes on this branch

- `/llms.txt`
- Organization `sameAs` wiring (empty until real profile URLs exist in repo/site)
- FAQ page `FAQPage` JSON-LD
- `/privacy` + `/terms` (draft copy marked for legal review)
- Shorter homepage `<title>` via `SITE_NAME_SHORT`
- `vercel.json` cache headers for static assets / HTML SWR
