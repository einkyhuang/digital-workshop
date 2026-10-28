import Foundation

/// 网站业绩 KPI — 与 `bots/运营管理/财务官/files/calc_website_dashboard.py` 同口径。
enum OverviewMetrics {
    struct TargetsFile: Codable {
        var version: Int?
        var currency: String?
        var timezone: String?
        var websiteProjects: WPTargets?
        struct WPTargets: Codable {
            var yearly: YearTarget?
            var monthly: [MonthTarget]?
        }
        struct YearTarget: Codable {
            var year: Int?
            var contractTarget: Double?
            var collectionTarget: Double?
            var note: String?
        }
        struct MonthTarget: Codable {
            var year: Int?
            var month: Int?
            var contractTarget: Double?
            var collectionTarget: Double?
            var note: String?
        }
    }

    struct QualityHint: Identifiable {
        var id: String { kind }
        var kind: String
        var count: Int
        var label: String
    }

    struct KPI {
        var asOf: String
        var amountsAvailable: Bool
        // portfolio (stock)
        var portfolioContract: Double
        var portfolioPaid: Double
        var portfolioUnpaid: Double
        var portfolioOverdue: Double
        // year slice
        var yearContract: Double
        var yearPaid: Double
        var yearUnpaid: Double
        var yearOverdue: Double
        // month slice
        var monthContract: Double
        var monthPaid: Double
        // targets
        var yearContractTarget: Double?
        var yearCollectionTarget: Double?
        var monthContractTarget: Double?
        var monthCollectionTarget: Double?
        // aux
        var pricedCount: Int
        var zeroPlaceholderCount: Int
        var projectCount: Int
        var quality: [QualityHint]
        var overdueRiskCount: Int

        var yearContractRate: Double? {
            guard let t = yearContractTarget, t > 0 else { return nil }
            return yearContract / t
        }
        var yearCollectionRate: Double? {
            guard let t = yearCollectionTarget, t > 0 else { return nil }
            return yearPaid / t
        }
    }

    struct EmailDaily: Codable, Identifiable {
        var id: String { date }
        var date: String
        var source: String?
        var 新邮件数: Int?
        var 已清理数: Int?
        var 清理分类: [String: Int]?
        var 待回复数: Int?
        var 重要邮件: [EmailImportant]?
        var 话题标签: [String]?
        var countNew: Int { 新邮件数 ?? 0 }
        var countCleaned: Int { 已清理数 ?? 0 }
        var pendingReplies: Int { 待回复数 ?? 0 }
        var important: [EmailImportant] { 重要邮件 ?? [] }
        var tags: [String] { 话题标签 ?? [] }
        var cleanupCategories: [String: Int] { 清理分类 ?? [:] }
    }

    struct EmailImportant: Codable, Identifiable {
        var id: String { "\(发件方 ?? "")|\(主题 ?? "")" }
        var 发件方: String?
        var 主题: String?
        var 摘要: String?
        var 待办: String?
        var 紧急度: String?
        var company: String { 发件方 ?? "—" }
        var subject: String { 主题 ?? "—" }
        var summary: String { 摘要 ?? "" }
        var todo: String { 待办 ?? "" }
        var urgency: String { 紧急度 ?? "" }
    }

    struct SmartPlanTask: Identifiable, Hashable {
        var id: String
        var title: String
        var status: String
        var priority: String?
        var dueDate: String?
        var source: String
    }

    static func currency(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return "¥" + (f.string(from: NSNumber(value: v)) ?? "\(Int(v))")
    }

    static func pct(_ n: Double, _ d: Double?) -> String {
        guard let d, d > 0 else { return "—" }
        return String(format: "%.1f%%", (n / d) * 100)
    }

    private static func toNum(_ v: Double?) -> Double {
        v ?? 0
    }

    private static func parseDay(_ s: String?) -> DateComponents? {
        guard let s, !s.isEmpty else { return nil }
        let head = String(s.prefix(10))
        let parts = head.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]) else { return nil }
        return DateComponents(year: y, month: m, day: d)
    }

    private static func shanghaiToday() -> DateComponents {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let now = Date()
        let c = cal.dateComponents([.year, .month, .day], from: now)
        return c
    }

    private static func dayLessThan(_ a: DateComponents, _ b: DateComponents) -> Bool {
        let ay = a.year ?? 0, am = a.month ?? 0, ad = a.day ?? 0
        let by = b.year ?? 0, bm = b.month ?? 0, bd = b.day ?? 0
        if ay != by { return ay < by }
        if am != bm { return am < bm }
        return ad < bd
    }

    static func compute(projects: [WebsiteProject], targets: TargetsFile?) -> KPI {
        let asOf = shanghaiToday()
        let year = asOf.year ?? 2026
        let month = asOf.month ?? 1

        let allNil = projects.isEmpty || projects.allSatisfy {
            $0.totalAmount == nil && $0.paidAmount == nil && $0.unpaidAmount == nil && $0.depositAmount == nil
        }
        if allNil {
            return KPI(
                asOf: String(format: "%04d-%02d-%02d", year, month, asOf.day ?? 1),
                amountsAvailable: false,
                portfolioContract: 0, portfolioPaid: 0, portfolioUnpaid: 0, portfolioOverdue: 0,
                yearContract: 0, yearPaid: 0, yearUnpaid: 0, yearOverdue: 0,
                monthContract: 0, monthPaid: 0,
                yearContractTarget: nil, yearCollectionTarget: nil,
                monthContractTarget: nil, monthCollectionTarget: nil,
                pricedCount: 0, zeroPlaceholderCount: 0, projectCount: projects.count,
                quality: [], overdueRiskCount: 0
            )
        }

        var zeroN = 0, pricedN = 0, overdueRisk = 0
        var qZero = 0, qFallback = 0, qMissingDate = 0, qRisk = 0
        var portfolioC = 0.0, portfolioP = 0.0, portfolioU = 0.0, portfolioO = 0.0
        var yC = 0.0, yP = 0.0, yU = 0.0, yO = 0.0
        var mC = 0.0, mP = 0.0

        for p in projects {
            let t = toNum(p.totalAmount)
            let pd = toNum(p.paidAmount)
            let u: Double = {
                if let raw = p.unpaidAmount { return raw }
                return max(t - pd, 0)
            }()
            if t == 0 && pd == 0 { zeroN += 1; qZero += 1 }
            if t > 0 { pricedN += 1 }

            // contract date
            var cYear: Int? = nil
            var cMonth: Int? = nil
            if let sd = parseDay(p.serviceStartDate) {
                cYear = sd.year; cMonth = sd.month
            } else if let cd = parseDay(p.createdAt) {
                cYear = cd.year; cMonth = cd.month
                qFallback += 1
            } else {
                qMissingDate += 1
            }

            let end = parseDay(p.deadline) ?? parseDay(p.serviceEndDate)
            let overdue = u > 0.01 && end != nil && dayLessThan(end!, asOf)
            let ps = p.paymentStatus ?? ""
            let risk = u > 0.01 && end == nil && p.status == "delivered" && ps != "fully_paid"
            if risk { overdueRisk += 1; qRisk += 1 }

            portfolioC += t; portfolioP += pd; portfolioU += u
            if overdue { portfolioO += u }

            if let cy = cYear, cy == year {
                yC += t; yP += pd; yU += u
                if overdue { yO += u }
                if let cm = cMonth, cm == month {
                    mC += t; mP += pd
                }
            }
        }

        var yCT: Double? = nil, yColT: Double? = nil, mCT: Double? = nil, mColT: Double? = nil
        if let yp = targets?.websiteProjects?.yearly, yp.year == year {
            yCT = yp.contractTarget
            yColT = yp.collectionTarget
        }
        if let rows = targets?.websiteProjects?.monthly {
            for row in rows where row.year == year && row.month == month {
                mCT = row.contractTarget
                mColT = row.collectionTarget
            }
        }

        var quality: [QualityHint] = []
        if qZero > 0 { quality.append(.init(kind: "zero_amount_placeholder", count: qZero, label: "零金额占位")) }
        if qFallback > 0 { quality.append(.init(kind: "date_fallback_createdAt", count: qFallback, label: "缺 serviceStartDate（回退 createdAt）")) }
        if qMissingDate > 0 { quality.append(.init(kind: "date_missing", count: qMissingDate, label: "无合同归属日")) }
        if qRisk > 0 { quality.append(.init(kind: "overdue_risk_no_end_date", count: qRisk, label: "待收无截止日期（逾期风险）")) }

        return KPI(
            asOf: String(format: "%04d-%02d-%02d", year, month, asOf.day ?? 1),
            amountsAvailable: true,
            portfolioContract: portfolioC,
            portfolioPaid: portfolioP,
            portfolioUnpaid: portfolioU,
            portfolioOverdue: portfolioO,
            yearContract: yC,
            yearPaid: yP,
            yearUnpaid: yU,
            yearOverdue: yO,
            monthContract: mC,
            monthPaid: mP,
            yearContractTarget: yCT,
            yearCollectionTarget: yColT,
            monthContractTarget: mCT,
            monthCollectionTarget: mColT,
            pricedCount: pricedN,
            zeroPlaceholderCount: zeroN,
            projectCount: projects.count,
            quality: quality,
            overdueRiskCount: overdueRisk
        )
    }

    static func mapSmartStatus(_ s: String) -> String {
        switch s {
        case "todo": return TaskColumn.todo.rawValue
        case "in_progress": return TaskColumn.doing.rawValue
        case "done", "archived": return TaskColumn.done.rawValue
        case "review", "验收", "审核": return TaskColumn.review.rawValue
        default:
            if TaskColumn(rawValue: s) != nil { return s }
            return TaskColumn.todo.rawValue
        }
    }
}
