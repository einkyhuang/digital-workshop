# 本地数据 Feed 约定（Bot 只写文件 · 工作台自动读）

时区默认 **Asia/Shanghai**。Bot **不必改工作台代码 / 不必重建 app**：写好文件即可；Mac 用 FSEvents 防抖刷新，Web 读公开目录的 `index.json`。

## 目录

| 路径 | 谁读 | 可否进 git / Pages |
|------|------|-------------------|
| `超级工作台应用/data/feeds/<source>/YYYY-MM-DD.json`（或 `.md`） | Mac + 本地 Web | **公开**：勿写客户真名、密钥、未脱敏联系方式 |
| `超级工作台应用/data/feeds/<source>/index.json` | Web 按需列表 | 公开；由脚本或 Bot 更新 |
| `超级工作台应用/data/private/feeds/<source>/…` | **仅 Mac 本地** | **gitignore**，Pages 不可见 |
| `超级工作台应用/data/feeds-registry.json` | 工作台 | 注册 feed → 侧栏模块 |

`<source>` 建议小写短 id，如 `seo`、`daily-summary`、`email`。

Web 副本路径：`超级工作台应用/app/data/feeds/…`（与上面结构相同；Bot 可写主目录后跑索引脚本同步，或直接写 app/data）。

## 注册（接入新 Bot）

编辑 `超级工作台应用/data/feeds-registry.json`（并复制到 `app/data/`）：

```json
{
  "id": "seo",
  "title": "每日 SEO",
  "moduleId": "dailySeo",
  "botName": "搜搜-SEO专家",
  "publicDir": "超级工作台应用/data/feeds/seo",
  "privateDir": "超级工作台应用/data/private/feeds/seo",
  "indexFile": "超级工作台应用/data/feeds/seo/index.json",
  "cardStyle": "seo",
  "workbenches": ["general"]
}
```

然后：

1. 建目录 `data/feeds/<id>/`
2. 写入当日 `YYYY-MM-DD.json`
3. 运行 `node 超级工作台应用/scripts/rebuild-feeds-index.mjs`（更新 index + 同步到 app/data）
4. 若是新 `moduleId`，需工作台侧栏已认识该 id（`dailySeo` 已内置；全新模块才要发版）

**已内置模块**：`dailySeo`（每日 SEO）、`dailySummary`（每日总结，仍兼容 legacy 纪纪路径）。

## 日文件 Schema（JSON）

```json
{
  "version": 1,
  "feedId": "seo",
  "date": "2026-10-30",
  "timezone": "Asia/Shanghai",
  "updatedAt": "2026-10-30T18:00:00+08:00",
  "botId": "seo",
  "botName": "搜搜-SEO专家",
  "summary": "一句话当日摘要（公开）",
  "articles": [
    {
      "id": "slug",
      "title": "Article title",
      "url": "https://…",
      "status": "published",
      "primaryKeyword": "…",
      "secondaryKeywords": ["…"],
      "image": "https://…/cover.webp",
      "publishedAt": "2026-10-30",
      "notes": "可选"
    }
  ],
  "keywords": [
    { "term": "keyword", "intent": "informational", "priority": "high" }
  ],
  "images": [
    { "url": "https://…", "alt": "…", "ofArticleId": "slug" }
  ],
  "checks": [
    { "id": "sitemap", "name": "Sitemap", "status": "pass", "detail": "…" }
  ],
  "issues": [
    { "severity": "high", "title": "问题标题", "detail": "…" }
  ]
}
```

### 必填

| 字段 | 说明 |
|------|------|
| `version` | 当前 `1` |
| `feedId` | 与目录名 / registry `id` 一致 |
| `date` | 与文件名 `YYYY-MM-DD` 一致 |
| `summary` | 列表页展示用短摘要 |

`articles` / `keywords` / `checks` / `issues` 按 feed 类型可空数组。

### Markdown 日文件（可选）

`YYYY-MM-DD.md`：正文任意；工作台按「整页 Markdown 卡片」展示。纪纪日报亦可逐步改为 `feeds/daily-summary/YYYY-MM-DD.md`，在迁移完成前仍读 `bots/管理中枢/总结助手/deliverables/日报-*.md`。

## index.json（Web / 懒列表）

```json
{
  "version": 1,
  "feedId": "seo",
  "timezone": "Asia/Shanghai",
  "updatedAt": "2026-10-30T18:05:00+08:00",
  "dates": [
    { "date": "2026-10-30", "file": "2026-10-30.json", "summary": "…", "articleCount": 1, "issueCount": 1 }
  ]
}
```

`dates` **新→旧**。生成命令：

```bash
node 超级工作台应用/scripts/rebuild-feeds-index.mjs
# 可选：只重建某一源
node 超级工作台应用/scripts/rebuild-feeds-index.mjs seo
```

## Mac 行为

- 启动加载 registry；进入对应页时读该源 `index`（若无则扫目录）。
- FSEvents 监视 `data/feeds/<source>/` 与可选 `private/feeds/<source>/`，**防抖 ~400ms**，后台队列解析，只刷新**当前可见** feed/日期。
- 私有文件仅本地；不会上传 Pages。

## Web 行为

- 读 `./data/feeds/<source>/index.json`；点日期再 `fetch` 当日 JSON。
- GitHub Pages：**只发布公开 feeds**；`private/feeds` 不存在则静默跳过。

## 隐私

- 公开 JSON：**禁止** API Key、客户真名、合同金额、完整邮箱/电话。
- 敏感日检细节写 `data/private/feeds/<source>/YYYY-MM-DD.json`（gitignore）。
