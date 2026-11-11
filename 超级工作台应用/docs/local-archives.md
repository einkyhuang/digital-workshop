# 本地客户档案与知识库

客户管理和知识库直接读本机 Markdown，不再为每一家客户或每一篇资料改 JSON、改代码。页面把 Markdown 渲染成 HTML。不读取、不生成 `深度分析.html` 这一类旁路文件。

## 客户档案

目录（已在 `.gitignore` 里，不要提交真实客户内容）：

```
超级工作台应用/data/private/客户档案/{照明|服装|布料}/客户/{公司名}/
  档案.md
  深度分析.md
  30天营销规划.md
  跟进记录.md          可选
```

分类：`照明` → 照明，`服装` → 服装，`布料` → 布料。其它分类文件夹也会出现在分类条上。打开「客户管理」时扫描这些文件夹，新客户排在列表最上方。点进客户后现读 Markdown。

已有的 `magichub_leads.json`（约一万九千条）只做叠加。保存时会丢掉档案客户和报告正文，按原来的库内顺序写回，避免和页面的自动保存互相覆盖。下一次打开再从文件夹读。

## 知识库

```
超级工作台应用/data/private/知识库/{产品参数|行业动态|开发采购|营销话术|业务技能}/{标题}.md
```

文件名或文首 `# 标题` 作为条目标题。可用文首 frontmatter：

```
---
title: 标题
category: products
date: 2026-11-11
---
```

未映射的文件夹会多出一个分类。点「阅读」时现读 Markdown。这些条目不写进 `magichub_knowledge_base.json`。

## 装到 Mac 上的超级工作台

网页在 `WKWebView` 里打开仓库里的 `超级工作台应用/app/magichub/`。扫文件夹和保存时剥离档案是 Swift 桥（`MagicHubBridge` / `LocalArchiveIndex`）做的，桥脚本打进 App 包。两处都要更新：

```bash
cd 超级工作台应用/crm-magichub
./build-for-workbench.sh

cd ../mac-app/SuperWorkbench
./build.sh
```

然后重新打开 `超级工作台.app`。只拉代码、不重新编译 App 的话，旧包里的桥没有 `list-customer-archives`，客户档案不会出现。只编译 App、不重建 `app/magichub` 的话，列表接口有了，但页面仍是旧界面，服装/布料、置顶和 Markdown 渲染不会出来。

浏览器走局域网服务时，同一套目录由 `超级工作台应用/lan/server.mjs` 提供，需要重启该服务。
