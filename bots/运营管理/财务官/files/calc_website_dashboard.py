#!/usr/bin/env python3
"""网站项目经营看板实算脚本（金算盘）。

数据：超级工作台应用/data/private/websiteProjects.local.json（gitignore）
目标：超级工作台应用/data/private/targets.local.json（gitignore，可缺）
输出：超级工作台应用/data/private/网站业绩看板实算.local.md（gitignore）

口径见：bots/运营管理/财务官/deliverables/网站业绩看板口径.md
不编造金额；目标未填则完成率为 null。
"""
from __future__ import annotations

import json
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo

TZ = ZoneInfo("Asia/Shanghai")
REPO = Path(__file__).resolve().parents[4]  # digital-workshop
PRIVATE_DIR = REPO / "超级工作台应用" / "data" / "private"
PROJECTS_FILE = PRIVATE_DIR / "websiteProjects.local.json"
TARGETS_FILE = PRIVATE_DIR / "targets.local.json"
OUT_FILE = PRIVATE_DIR / "网站业绩看板实算.local.md"


def today_shanghai() -> date:
    return datetime.now(TZ).date()


def to_num(v):
    if v is None or v == "":
        return None
    try:
        return float(v)
    except (TypeError, ValueError):
        return None


def parse_date(s):
    if not s:
        return None
    try:
        s = str(s)
        if "T" in s:
            dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
            return dt.astimezone(TZ).date()
        return date.fromisoformat(s[:10])
    except Exception:
        return None


def contract_date(p: dict) -> tuple[date | None, str]:
    """返回 (归属日, 来源标记)。优先 serviceStartDate，否则 createdAt。"""
    sd = parse_date(p.get("serviceStartDate"))
    if sd:
        return sd, "serviceStartDate"
    cd = parse_date(p.get("createdAt"))
    if cd:
        return cd, "createdAt_fallback"
    return None, "missing"


def end_date(p: dict) -> date | None:
    return parse_date(p.get("deadline")) or parse_date(p.get("serviceEndDate"))


def money(v: float | None) -> str:
    if v is None:
        return "—"
    return f"{v:,.2f}"


def pct(n, d) -> str:
    if d is None or d == 0 or n is None:
        return "—"
    return f"{(n / d) * 100:.1f}%"


@dataclass
class Issues:
    items: list = field(default_factory=list)

    def add(self, kind: str, detail: str):
        self.items.append((kind, detail))


def load_projects() -> list[dict]:
    if not PROJECTS_FILE.exists():
        raise SystemExit(f"缺少私有数据：{PROJECTS_FILE}")
    raw = json.loads(PROJECTS_FILE.read_text(encoding="utf-8"))
    projects = raw.get("projects")
    if not isinstance(projects, list):
        raise SystemExit("websiteProjects.local.json 缺少 projects[]")
    return projects, raw


def load_targets() -> dict | None:
    if not TARGETS_FILE.exists():
        return None
    try:
        return json.loads(TARGETS_FILE.read_text(encoding="utf-8"))
    except Exception:
        return None


def target_for(targets: dict | None, year: int, month: int | None):
    """返回 (contractTarget, collectionTarget)。未配置为 (None, None)。"""
    if not targets:
        return None, None
    wp = (targets.get("websiteProjects") or {})
    if month is None:
        y = wp.get("yearly") or {}
        if y.get("year") == year:
            return y.get("contractTarget"), y.get("collectionTarget")
        return None, None
    for row in wp.get("monthly") or []:
        if row.get("year") == year and row.get("month") == month:
            return row.get("contractTarget"), row.get("collectionTarget")
    return None, None


def main():
    as_of = today_shanghai()
    # Allow override for reproducible docs
    if len(sys.argv) > 1:
        as_of = date.fromisoformat(sys.argv[1])

    projects, meta = load_projects()
    targets = load_targets()
    issues = Issues()

    year, month = as_of.year, as_of.month

    # Normalize per project
    rows = []
    for p in projects:
        name = p.get("name") or p.get("id") or "?"
        total = to_num(p.get("totalAmount"))
        paid = to_num(p.get("paidAmount"))
        deposit = to_num(p.get("depositAmount"))
        unpaid_f = to_num(p.get("unpaidAmount"))
        ps = p.get("paymentStatus")

        if total is None and p.get("totalAmount") not in (None, ""):
            issues.add("non_numeric", f"{name}.totalAmount={p.get('totalAmount')!r}")
        if paid is None and p.get("paidAmount") not in (None, ""):
            issues.add("non_numeric", f"{name}.paidAmount={p.get('paidAmount')!r}")

        t = total if total is not None else 0.0
        pd = paid if paid is not None else 0.0
        # 待收：优先字段；否则总额−已付（≥0）
        if unpaid_f is not None:
            unpaid = unpaid_f
            if abs((t - pd) - unpaid) > 0.01:
                issues.add(
                    "unpaid_mismatch",
                    f"{name}: unpaid={unpaid} vs total-paid={t-pd}",
                )
        else:
            unpaid = max(t - pd, 0.0)
            issues.add("unpaid_missing", f"{name}: 用 total-paid 推算")

        if ps == "fully_paid" and t > 0 and pd + 0.01 < t:
            issues.add("fully_paid_short", f"{name}: paid={pd} < total={t}")
        if ps == "fully_paid" and unpaid > 0.01:
            issues.add("fully_paid_with_unpaid", f"{name}: unpaid={unpaid}")
        if ps == "pending" and pd > 0.01:
            issues.add("pending_with_paid", f"{name}: paid={pd}")
        if ps == "deposit_paid" and pd <= 0:
            issues.add("deposit_paid_zero", name)
        if t == 0 and pd == 0:
            issues.add("zero_amount_placeholder", f"{name} status={p.get('status')} ps={ps}")

        cdate, csrc = contract_date(p)
        if csrc == "createdAt_fallback":
            issues.add("date_fallback_createdAt", name)
        elif csrc == "missing":
            issues.add("date_missing", name)

        ed = end_date(p)
        overdue = unpaid > 0.01 and ed is not None and ed < as_of
        overdue_risk = (
            unpaid > 0.01
            and ed is None
            and p.get("status") == "delivered"
            and ps != "fully_paid"
        )
        if overdue_risk:
            issues.add("overdue_risk_no_end_date", f"{name}: unpaid={unpaid}")

        rows.append(
            {
                "name": name,
                "total": t,
                "paid": pd,
                "deposit": deposit if deposit is not None else 0.0,
                "unpaid": unpaid,
                "ps": ps,
                "status": p.get("status"),
                "cdate": cdate,
                "csrc": csrc,
                "end": ed,
                "overdue": overdue,
                "overdue_risk": overdue_risk,
            }
        )

    def in_year(r):
        return r["cdate"] and r["cdate"].year == year

    def in_month(r):
        return r["cdate"] and r["cdate"].year == year and r["cdate"].month == month

    # Metric cards
    portfolio_contract = sum(r["total"] for r in rows)
    portfolio_paid = sum(r["paid"] for r in rows)
    portfolio_unpaid = sum(r["unpaid"] for r in rows)
    portfolio_overdue = sum(r["unpaid"] for r in rows if r["overdue"])

    y_contract = sum(r["total"] for r in rows if in_year(r))
    y_paid = sum(r["paid"] for r in rows if in_year(r))
    # 本年已收：按合同归属年汇总已付（非收款流水日；字段无收款日）
    y_unpaid = sum(r["unpaid"] for r in rows if in_year(r))
    y_overdue = sum(r["unpaid"] for r in rows if in_year(r) and r["overdue"])

    m_contract = sum(r["total"] for r in rows if in_month(r))
    m_paid = sum(r["paid"] for r in rows if in_month(r))
    m_unpaid = sum(r["unpaid"] for r in rows if in_month(r))
    m_overdue = sum(r["unpaid"] for r in rows if in_month(r) and r["overdue"])

    # 存量待收 / 逾期不按「本月新签」过滤：全库未结清
    stock_unpaid = portfolio_unpaid
    stock_overdue = portfolio_overdue

    y_ct, y_colt = target_for(targets, year, None)
    m_ct, m_colt = target_for(targets, year, month)

    priced = [r for r in rows if r["total"] > 0]
    zero_n = sum(1 for r in rows if r["total"] == 0 and r["paid"] == 0)

    lines = []
    lines.append("# 网站业绩看板实算（本地私有）")
    lines.append("")
    lines.append("> **LOCAL ONLY — 含金额，禁止提交公开仓库。**")
    lines.append(f"> 基准日：{as_of.isoformat()}（Asia/Shanghai）")
    lines.append(f"> 数据源：`{PROJECTS_FILE.relative_to(REPO)}`")
    lines.append(f"> 私有 updatedAt：{meta.get('updatedAt')}")
    lines.append(f"> 项目数：{len(rows)}；有金额(>0)项目：{len(priced)}；零金额占位：{zero_n}")
    lines.append(f"> 币种假设：CNY（源数据无 currency 字段）")
    lines.append(f"> 口径文档：`bots/运营管理/财务官/deliverables/网站业绩看板口径.md`")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## 指标卡（实算）")
    lines.append("")
    lines.append("| 指标 | 数值 (CNY) | 说明 |")
    lines.append("|---|---:|---|")
    lines.append(f"| 本年合同额 | {money(y_contract)} | 合同归属年={year} |")
    lines.append(f"| 本年已收 | {money(y_paid)} | 同年合同的 paidAmount 合计 |")
    lines.append(f"| 本年待收 | {money(y_unpaid)} | 同年合同的待收合计 |")
    lines.append(f"| 本年逾期 | {money(y_overdue)} | 同年合同且 endDate < 基准日 |")
    lines.append(f"| 本年合同目标 | {money(y_ct) if y_ct is not None else '—（未填）'} | targets.yearly.contractTarget |")
    lines.append(f"| 本年合同目标完成率 | {pct(y_contract, y_ct) if y_ct not in (None, 0) else '—'} | 合同额/目标 |")
    lines.append(f"| 本年回款目标 | {money(y_colt) if y_colt is not None else '—（未填）'} | targets.yearly.collectionTarget |")
    lines.append(f"| 本年回款目标完成率 | {pct(y_paid, y_colt) if y_colt not in (None, 0) else '—'} | 已收/回款目标 |")
    lines.append(f"| 本月合同额 | {money(m_contract)} | 归属 {year}-{month:02d} |")
    lines.append(f"| 本月已收 | {money(m_paid)} | 同月合同 paid 合计 |")
    lines.append(f"| 本月待收 | {money(m_unpaid)} | 同月合同待收 |")
    lines.append(f"| 本月逾期 | {money(m_overdue)} | 同月合同且逾期 |")
    lines.append(f"| 本月合同目标 | {money(m_ct) if m_ct is not None else '—（未填）'} | targets.monthly |")
    lines.append(f"| 本月合同目标完成率 | {pct(m_contract, m_ct) if m_ct not in (None, 0) else '—'} | |")
    lines.append(f"| 本月回款目标 | {money(m_colt) if m_colt is not None else '—（未填）'} | |")
    lines.append(f"| 本月回款目标完成率 | {pct(m_paid, m_colt) if m_colt not in (None, 0) else '—'} | |")
    lines.append(f"| 全库合同额 | {money(portfolio_contract)} | 含零金额项目（贡献 0） |")
    lines.append(f"| 全库已收 | {money(portfolio_paid)} | |")
    lines.append(f"| 全库待收（存量） | {money(stock_unpaid)} | 看板「待收」主卡建议用此 |")
    lines.append(f"| 全库逾期（存量） | {money(stock_overdue)} | 看板「逾期」主卡建议用此 |")
    lines.append("")
    lines.append("## 有金额项目明细")
    lines.append("")
    lines.append("| 项目 | 合同额 | 已付 | 待收 | 付款状态 | 状态 | 归属日 | 归属来源 | 截止 | 逾期 |")
    lines.append("|---|---:|---:|---:|---|---|---|---|---|---|")
    for r in sorted(priced, key=lambda x: -x["total"]):
        lines.append(
            f"| {r['name']} | {money(r['total'])} | {money(r['paid'])} | {money(r['unpaid'])} | "
            f"{r['ps']} | {r['status']} | {r['cdate']} | {r['csrc']} | {r['end'] or '—'} | "
            f"{'是' if r['overdue'] else ('风险' if r['overdue_risk'] else '否')} |"
        )
    lines.append("")
    lines.append("## 数据质量")
    lines.append("")
    by = Counter(k for k, _ in issues.items)
    lines.append("| 问题类型 | 条数 |")
    lines.append("|---|---:|")
    for k, n in by.most_common():
        lines.append(f"| {k} | {n} |")
    lines.append("")
    lines.append("### 非占位类问题明细")
    lines.append("")
    for k, d in issues.items:
        if k == "zero_amount_placeholder" or k == "date_fallback_createdAt":
            continue
        lines.append(f"- `{k}`: {d}")
    fb = sum(1 for k, _ in issues.items if k == "date_fallback_createdAt")
    lines.append("")
    lines.append(f"- `date_fallback_createdAt`: {fb} 条（serviceStartDate 缺失，合同月/年退回 createdAt；当前全部 createdAt 为导入日 2026-10-10，**本月/本年合同额会几乎等于全库**，待补真实开工/签约日）。")
    lines.append(f"- `zero_amount_placeholder`: {zero_n} 条（total=paid=0；paymentStatus 多为 pending，不计入有效合同额）。")
    lines.append("")
    lines.append("## 分布摘要")
    lines.append("")
    lines.append(f"- paymentStatus: {dict(Counter(r['ps'] for r in rows))}")
    lines.append(f"- status: {dict(Counter(r['status'] for r in rows))}")
    lines.append("")
    lines.append("*由 `bots/运营管理/财务官/files/calc_website_dashboard.py` 生成。*")

    PRIVATE_DIR.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_FILE}")
    print(
        json.dumps(
            {
                "as_of": as_of.isoformat(),
                "count": len(rows),
                "priced": len(priced),
                "y_contract": y_contract,
                "y_paid": y_paid,
                "stock_unpaid": stock_unpaid,
                "stock_overdue": stock_overdue,
                "m_contract": m_contract,
                "m_paid": m_paid,
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
