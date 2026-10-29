import Foundation

/// MagicHub CRM tabs shown in the outer 超级工作台 sidebar when 外贸工作台 is active.
/// Order matches crm-magichub App.vue `tabs` (驾驶舱 … Forwelike 专区). Settings is omitted from the primary list (reachable inside MagicHub).
struct MagicHubNavItem: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String

    static let all: [MagicHubNavItem] = [
        .init(id: "dashboard", name: "驾驶舱", icon: "square.grid.2x2"),
        .init(id: "schedule", name: "日程管理", icon: "calendar"),
        .init(id: "customers", name: "客户管理", icon: "person.2"),
        .init(id: "marketing", name: "智能营销", icon: "envelope"),
        .init(id: "opportunities", name: "商机管理", icon: "chart.line.uptrend.xyaxis"),
        .init(id: "followup", name: "跟进记录", icon: "bubble.left.and.bubble.right"),
        .init(id: "samples", name: "寄样跟进", icon: "shippingbox"),
        .init(id: "quotes", name: "报价记录", icon: "yensign.circle"),
        .init(id: "contracts", name: "订单合同", icon: "doc.text"),
        .init(id: "products", name: "产品管理", icon: "cube.box"),
        .init(id: "knowledge", name: "知识仓库", icon: "books.vertical"),
        .init(id: "company", name: "公司信息", icon: "building.2"),
        .init(id: "team", name: "团队管理", icon: "person.3"),
        .init(id: "agentRoom", name: "Agent 协同", icon: "sparkles"),
        .init(id: "forwelike", name: "Forwelike 专区", icon: "star.circle"),
        .init(id: "settings", name: "系统设置", icon: "gearshape")
    ]

    init(id: String, name: String, icon: String) {
        self.id = id
        self.title = name
        self.icon = icon
    }
}

extension Notification.Name {
    static let swMagicHubTabChanged = Notification.Name("swMagicHubTabChanged")
    static let swMagicHubPushTab = Notification.Name("swMagicHubPushTab")
}
