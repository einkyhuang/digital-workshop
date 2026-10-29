import SwiftUI
import AppKit

/// Tokens from 画眉 design-spec.md → bots/视觉设计/设计师/deliverables/workbench-ui/
/// Field rules from 搜搜 → bots/网站项目/Super-SEO-Hub/deliverables/网站项目字段规范.md
enum SWTheme {
    static let pageBg = Color(red: 246/255, green: 247/255, blue: 248/255) // #F6F7F8
    static let card = Color.white
    static let sidebarBg = Color(red: 240/255, green: 241/255, blue: 243/255)
    static let overlay = Color(red: 15/255, green: 17/255, blue: 21/255).opacity(0.45)
    static let border = Color.black.opacity(0.08)
    static let borderSoft = Color.black.opacity(0.06)
    static let borderGroup = Color.black.opacity(0.10)
    static let text = Color(red: 17/255, green: 17/255, blue: 17/255)
    static let textSecondary = Color(red: 115/255, green: 115/255, blue: 115/255)
    static let textMuted = Color(red: 138/255, green: 138/255, blue: 142/255)
    static let accent = Color(red: 17/255, green: 17/255, blue: 17/255)
    static let focus = Color(red: 59/255, green: 130/255, blue: 246/255)
    static let bg = pageBg
    static let muted = Color.secondary
    static let sidebarWidth: CGFloat = 280

    // Overview v2
    static let shadowElevated = Color.black.opacity(0.06)
    static let radiusKPI: CGFloat = 18
    static let radiusSection: CGFloat = 24
    static let ringTrack = Color(red: 232/255, green: 236/255, blue: 240/255)
    static let ringContract = Color(red: 59/255, green: 130/255, blue: 246/255)
    static let ringPaid = Color(red: 16/255, green: 185/255, blue: 129/255)
    static let urgencyHigh = Color(red: 239/255, green: 68/255, blue: 68/255)
    static let urgencyMid = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let urgencyLow = Color(red: 148/255, green: 163/255, blue: 184/255)
    static let gradBlueTop = Color.white
    static let gradBlueBot = Color(red: 240/255, green: 246/255, blue: 1)
    static let gradGreenBot = Color(red: 240/255, green: 253/255, blue: 246/255)
    static let gradAmberBot = Color(red: 1, green: 248/255, blue: 237/255)
    static let gradRoseBot = Color(red: 1, green: 241/255, blue: 242/255)
    static let gradVioletBot = Color(red: 245/255, green: 243/255, blue: 1)

    enum Radius {
        static let card: CGFloat = 28
        static let group: CGFloat = 20
        static let panel: CGFloat = 16
        static let modal: CGFloat = 20
        static let badge: CGFloat = 8
    }


    enum Typography {
        /// Sidebar nav (千问参考 ~14–15pt)
        static let nav: CGFloat = 14.5
        static let navIcon: CGFloat = 16
        static let navLine: CGFloat = 1.4
        static let navRowMin: CGFloat = 40
        /// Group subheadings ~12pt
        static let groupTitle: CGFloat = 12
        /// Body copy (团队日报等) 15–16pt
        static let body: CGFloat = 15.5
        static let bodyLine: CGFloat = 1.62
        static let h1: CGFloat = 26
        static let h2: CGFloat = 20
        static let h3: CGFloat = 17
        static let caption: CGFloat = 13
        static let captionLine: CGFloat = 1.45
        /// Segment control
        static let segment: CGFloat = 13
    }

    enum Space {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s8: CGFloat = 32
    }

    static let projProgressFill = Color(red: 0.859, green: 0.918, blue: 0.996) // #DBEAFE
    static let projProgressFg = Color(red: 0.114, green: 0.306, blue: 0.847)
    static let projHoldFill = Color(red: 1.0, green: 0.929, blue: 0.835) // #FFEDD5


    enum Roster {
        static let groupMinWidth: CGFloat = 340
        static let groupGap: CGFloat = 16
        static let groupPadding: CGFloat = 12
        static let cardMinWidth: CGFloat = 160
        static let cardGap: CGFloat = 12
        /// Compact avatar (design-spec: outer 92 / inner 84) — do not shrink further
        static let avatarOuter: CGFloat = 92
        static let avatarInner: CGFloat = 84
        static let cardMinHeight: CGFloat = 240
    }

    enum Website {
        static let cardMinWidth: CGFloat = 220
        static let cardMinHeight: CGFloat = 220
        static let cardCorner: CGFloat = 28
        static let iconSize: CGFloat = 64
        static let detailWidth: CGFloat = 920
        static let detailMaxHeight: CGFloat = 860
        static let closeBtn: CGFloat = 32
    }

    static let iconGradients: [(Color, Color)] = [
        (Color(red: 0.231, green: 0.510, blue: 0.965), Color(red: 0.545, green: 0.361, blue: 0.965)),
        (Color(red: 0.024, green: 0.714, blue: 0.831), Color(red: 0.231, green: 0.510, blue: 0.965)),
        (Color(red: 0.961, green: 0.620, blue: 0.043), Color(red: 0.937, green: 0.267, blue: 0.267)),
        (Color(red: 0.063, green: 0.725, blue: 0.506), Color(red: 0.020, green: 0.588, blue: 0.412)),
        (Color(red: 0.925, green: 0.286, blue: 0.600), Color(red: 0.545, green: 0.361, blue: 0.965))
    ]

    static func statusColor(_ status: String) -> Color {
        switch status {
        case "在线": return Color(red: 0.133, green: 0.773, blue: 0.369)
        case "忙碌": return Color(red: 0.961, green: 0.620, blue: 0.043)
        case "空闲": return Color(red: 0.612, green: 0.639, blue: 0.686)
        default: return .secondary
        }
    }

    static func websiteStatusColor(_ status: String) -> Color {
        switch status {
        case "in_progress": return Color(red: 0.114, green: 0.306, blue: 0.847) // #1D4ED8
        case "delivered": return Color(red: 0.082, green: 0.502, blue: 0.239)
        case "infrastructure": return Color(red: 0.427, green: 0.157, blue: 0.851)
        default: return Color(red: 0.761, green: 0.255, blue: 0.047)
        }
    }

    static func websiteStatusFill(_ status: String) -> Color {
        switch status {
        case "in_progress": return Color(red: 0.859, green: 0.918, blue: 0.996)
        case "delivered": return Color(red: 0.863, green: 0.988, blue: 0.906)
        case "infrastructure": return Color(red: 0.929, green: 0.914, blue: 0.996)
        default: return Color(red: 1.0, green: 0.929, blue: 0.835)
        }
    }

    static func columnColor(_ col: TaskColumn) -> Color {
        switch col {
        case .todo: return .blue
        case .doing: return .orange
        case .review: return .purple
        case .done: return .green
        }
    }

    static func layerColor(_ layer: String) -> Color {
        if layer.contains("幕僚") { return .indigo }
        if layer.contains("Studio") || layer.contains("执行") { return .blue }
        if layer.contains("生活") { return .teal }
        return .gray
    }
}

/// 搜搜 field spec + workbench-side extensions (do not ALTER SmartPlan without asking)
enum WebsiteFieldConfig {
    static let omitKeys: Set<String> = [
        "client_phone", "client_wechat", "client_email", "assets_credentials",
        "clientPhone", "clientWechat", "clientEmail"
    ]

    /// List columns §1 order
    static let listColumns: [(key: String, title: String, width: CGFloat?)] = [
        ("name", "项目名称", nil),
        ("status", "状态", 88),
        ("client", "客户", 130),
        ("url", "网址", 140),
        ("framework", "框架", 72),
        ("services", "服务", 140),
        ("progress", "进度", 100),
        ("payment", "付款", 80),
        ("deadline", "服务截止", 100),
        ("owner", "负责人", 72),
        ("updated", "最近更新", 100)
    ]

    /// Detail sections §2
    static let detailSections: [(id: String, title: String)] = [
        ("basic", "基本信息"),
        ("client", "客户"),
        ("hosting", "域名和主机"),
        ("seo", "SEO 状态"),
        ("progress", "进度和里程碑"),
        ("notes", "备注和链接")
    ]

    static let statusOptions: [(status: String, category: String, label: String, progress: Int)] = [
        ("infrastructure", "功能基础建设", "筹建中", 25),
        ("in_progress", "进行中", "进行中", 55),
        ("delivered", "已交付", "已交付", 100),
        ("inactive", "已暂停/挂了", "挂起", 0)
    ]

    /// Status sort secondary: in_progress → infrastructure → delivered → inactive
    static func statusRank(_ status: String) -> Int {
        switch status {
        case "in_progress": return 0
        case "infrastructure": return 1
        case "delivered": return 2
        case "inactive": return 3
        default: return 9
        }
    }

    static let p0CheckIds = [
        "robots_txt", "ai_crawler_allow", "sitemap_xml", "ssr_readable",
        "title_h1_meta", "canonical", "https_status"
    ]

    static let seoChecklistTemplate: [(id: String, name: String, track: String, priority: String)] = [
        ("robots_txt", "robots.txt 可访问", "SEO+GEO", "P0"),
        ("ai_crawler_allow", "AI 搜索爬虫放行", "GEO", "P0"),
        ("sitemap_xml", "sitemap.xml 有效", "SEO+GEO", "P0"),
        ("ssr_readable", "首包机器可读正文", "GEO", "P0"),
        ("title_h1_meta", "Title / H1 / Meta", "SEO+GEO", "P0"),
        ("canonical", "自引用 Canonical", "SEO+GEO", "P0"),
        ("https_status", "HTTPS 与主文档状态", "SEO", "P0"),
        ("json_ld", "JSON-LD 结构化数据", "GEO", "P1"),
        ("same_as", "实体 sameAs", "GEO", "P1"),
        ("og_twitter", "Open Graph / Twitter", "SEO+GEO", "P1"),
        ("lang", "html lang", "SEO+GEO", "P1"),
        ("llms_txt", "llms.txt", "GEO", "P1"),
        ("cwv", "Core Web Vitals", "SEO", "P1"),
        ("heading_hierarchy", "标题层级与 BLUF", "GEO", "P2"),
        ("alt_internal_links", "图片 Alt 与内链", "SEO", "P2"),
        ("gsc_submitted", "GSC Sitemap 提交", "SEO", "P2"),
        ("index_coverage", "索引/发现健康", "SEO", "P2"),
        ("backlinks_baseline", "外链基线", "SEO", "P2")
    ]

    static func paymentLabel(_ s: String?) -> String {
        switch s {
        case "fully_paid": return "已结清"
        case "deposit_paid": return "已付定金"
        default: return "待付款"
        }
    }

    static func hasSeoService(_ services: [String]?) -> Bool {
        (services ?? []).contains { $0.uppercased().contains("SEO") || $0.uppercased().contains("GEO") }
    }

    /// Returns nil if OK, else block reason
    static func canTransition(from: String, to: String, project: WebsiteProject, adminOverride: Bool = false) -> String? {
        if from == to { return nil }
        if from == "infrastructure" && to == "delivered" { return "禁止从筹建直接已交付，须经进行中" }
        if from == "inactive" && to == "delivered" { return "禁止从挂起直接已交付，须先回到进行中" }
        if to == "delivered" && hasSeoService(project.services) && !adminOverride {
            let failed = p0FailedCount(project)
            if failed > 0 { return "含 SEO/GEO 服务：尚有 \(failed) 项 P0 未通过，不可标为已交付" }
        }
        if to == "inactive" { return nil } // reason required in UI
        return nil
    }

    static func p0FailedCount(_ project: WebsiteProject) -> Int {
        let checklist = project.seoChecklist ?? [:]
        return p0CheckIds.filter { id in
            guard let item = checklist[id] else { return true } // missing = fail
            return item.pass != true
        }.count
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SWTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SWTheme.Radius.panel, style: .continuous)
                    .stroke(SWTheme.border, lineWidth: 1)
            )
    }
}

extension View {
    func swCard() -> some View { modifier(CardModifier()) }
}

struct TagChip: View {
    let text: String
    var color: Color = .blue
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct StatusPill: View {
    let status: String
    let category: String
    var progress: Int? = nil
    var body: some View {
        let fg = SWTheme.websiteStatusColor(status)
        let bg = SWTheme.websiteStatusFill(status)
        let label: String = {
            if let p = progress { return "\(shortLabel) · \(p)%" }
            return shortLabel
        }()
        return Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }
    private var shortLabel: String {
        switch status {
        case "in_progress": return "进行中"
        case "delivered": return "已交付"
        case "infrastructure": return "筹建中"
        default: return "挂起"
        }
    }
}

struct MetricCard: View {
    let value: String
    let label: String
    let detail: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.system(size: 28, weight: .bold, design: .rounded))
            Text(label).font(.subheadline.weight(.semibold))
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .swCard()
    }
}
