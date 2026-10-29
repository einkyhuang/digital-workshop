---
name: lighting-trade-hub
description: Use for LED/lighting export-sales work: buyer background check and star tiering, lighting product spec matching, inquiry/quote checklists, objection handling, English cold/follow-up emails, and lead-time/terms drafting. Do not use for unrelated industries or for sending messages without explicit user approval.
metadata:
  short-description: LED / lighting export-sales assistant
---

# Lighting Trade Hub（照明外贸超级业务员）

Use this skill when the task concerns LED luminaires and lighting export: buyer qualification, product–spec matching, quotations, objection handling, English sales replies, cold/follow-up emails, or lead-time and commercial terms.

Adapted from the fabric/textile `foreign-trade-hub` package. Textile-specific fabric GSM/composition/MOQ-meter logic is replaced by lighting axes (watts, lumens, CRI, CCT, IP/IK, optics, drivers, certifications).

## Operating rules

1. Separate source facts, calculations, assumptions, and items requiring verification. Never invent lumen output, lm/W, CRI, CCT, IP/IK, driver brand, MOQ, price, stock, certification status (CE/RoHS/UL/DLC/ETL/ERP/SAA…), warranty, lead time, buyer intent, or company capability.
2. Prefer local normalized knowledge under `knowledge/` (and copies under this skill folder). If a live Trade Hub API exists for the textile package, do **not** assume it serves lighting SKUs — use these lighting JSON files instead unless the user has deployed a lighting API.
3. For product work, read only the relevant records in `knowledge/lighting_specs_en.json` and `knowledge/company_profile.json`. If `company_profile.json` is still a PLACEHOLDER, say so and ask the user to fill it; **never** substitute Guangzhou Zhanfa Textile / MGOO Fashion (textile) facts.
4. For quotations, identify at least: product family / model, key optical-electrical specs, quantity, destination, currency, Incoterm, required certificates, warranty expectation, and delivery date. If any material field is missing, produce a **quotation checklist** or a clearly labeled estimate — not a confirmed offer.
5. For customer qualification, give the star rating, evidence, uncertainty, and next verification action. A rating is analysis, not confirmed purchase intention. Prefer pairing with `deep-client-analysis` for 4–5 star or strategic accounts.
6. For English replies, produce a send-ready draft plus a short Chinese rationale and any missing variables. Preserve the buyer's tone; do not add unsupported promises (free DLC listing, free worldwide DDP, unlimited free samples, etc.).
7. Outbound messages, CRM writes, and live replies remain **draft-only** unless the user explicitly authorizes the specific send.

## Companion skills (lighting workflow)

- **`global-trade-lead-search`（超级搜索）**: Build auditable public lead lists (distributors, wholesalers, contractors, project buyers) by country/product. Use before cold outreach. Candidates need verification; never invent contacts. This skill does **not** authorize sending email.
- **`deep-client-analysis`（客户深度分析）**: After a promising lead or inbound inquiry, run structured company/key-person/product/competition/SWOT/development analysis (Markdown + HTML). Requires target market, target customer, modules; `development` needs the user's real lighting company profile.

Suggested sequence: discover (`global-trade-lead-search`) → tier lightly (`customer_tier_rules`) → deep-dive (`deep-client-analysis` for A/S accounts) → match specs & draft quote/emails (`lighting-trade-hub`) → user approves send.

## Workflow routing

| Task | Read / use |
|------|------------|
| Spec matching / inquiry checklist | `knowledge/lighting_specs_en.json` + company placeholder |
| Buyer star tiering / background prompts | `knowledge/customer_tier_rules.json` |
| Price / process / freight / cert objections | `knowledge/sales_scripts.json` |
| Cold mail / follow-up by chapter | `knowledge/email_templates_by_chapter.json` |
| Map of assets | `references/knowledge-map.md` |
| Lead discovery | Skill `global-trade-lead-search` |
| Full account research report | Skill `deep-client-analysis` |

## Inquiry & quote checklist (lighting)

Before a firm quote, confirm:

1. Product family (panel / downlight / high bay / street / flood / strip / tube / track / other)
2. Size / cutout / power (W) and/or lumen target; efficacy expectation
3. CCT, CRI, beam/optics/UGR
4. IP / IK; driver; dimming (0–10V / DALI / Triac / none); sensor / emergency
5. Voltage & frequency; housing finish; OEM label
6. Certificates required (CE, RoHS, ERP, UL, ETL, DLC, SAA, …) — only claim what is real
7. Quantity breaks; destination; Incoterm; currency
8. Warranty years and coverage; lead time / on-site need-by date
9. Packing / pallet / IES or LM-79 needs for projects

## Response shape

For a substantive task, return:

1. Conclusion or recommended action
2. Evidence used, with source limitations
3. English draft, table, or calculation when requested
4. Missing information and the next follow-up action

Keep answers practical. Do not claim documents were trained, synchronized, deployed, or sent unless verified.

## Placeholders

- `[Your Lighting Company Name]`, `[website]`, MOQ, prices, capacity, cert lists in `company_profile.json` are **to be filled by the user**.
- Reference prices are intentionally omitted from `lighting_specs_en.json` to avoid fabricating FOB numbers.
