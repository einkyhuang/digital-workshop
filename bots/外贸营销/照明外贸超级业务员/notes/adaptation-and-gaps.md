# 照明适配说明 / Gaps

## 源包读取摘要

- 安装包路径：`/workspace/uploads/ftpkg.tgz` → `/workspace/uploads/pkg/超级外贸助手-安装包`
- Skill：`foreign-trade-hub`（面料询盘、分层、话术、分章邮件、可选 API）
- 通用知识：`sales_scripts.json`、`customer_tier_rules.json`、`email_templates_by_chapter.json`（源邮件 PDF 实为跨品类外贸模板，含部分 LED 字样，已按照明重写结构）
- 面料知识：`fabric_specs_en.json`、`company_profile.json`（展发纺织）— **不用于照明报价**
- 源材料：Sale Smartly 话术 xlsx（MGOO/服装）、客户分星级 xls（MGOO 分层）、51 页开发跟进邮件 PDF

## 已产出（照明版）

见 `files/lighting-trade-hub/`：`SKILL.md`、`knowledge/*.json`、`references/knowledge-map.md`。

## 超级搜索 + 深度分析在照明流程中的用法（短述）

`global-trade-lead-search` 负责按产品与国家从公开黄页/B2B/搜索结果拉「可审计」的候选经销商、批发商、工程商名单（域名、来源 URL、验证状态），只做发现不做外发；筛出有价值对象后，用 `deep-client-analysis` 按模块做官网/联系人/产品/竞争/SWOT/开发建议并输出 Markdown+HTML 双报告（含 development 时必须先填我方照明公司信息）。本 `lighting-trade-hub` 再接手规格匹配、星级话术、询盘报价清单与英文草稿。三者串联：搜索获客 → 深度背调 → 照明话术与报价草稿 → 用户确认后再发。

## Gaps / 需用户确认

1. **真实照明公司档案**：名称、官网、产能、认证原件清单、MOQ、交期、付款与质保 — 当前均为 PLACEHOLDER。
2. **真实价目/型号库**：无用户灯具 PDF/Excel 价目，故 specs 不含 FOB 价。
3. **星级金额阈值**：沿用源包人民币年采量级作参考，是否与照明 CRM 一致需确认。
4. **目标市场与主销品类**：面板/工矿/路灯等主攻顺序未知。
5. **是否部署 lighting API**：源包 `api/server.py` 仍指向面料知识；未改服务端。
6. **未代发任何邮件**（按任务要求）。
