import Foundation

struct WorkspaceData: Codable, Equatable {
    var version: Int?
    var updatedAt: String?
    var timezone: String?
    var bots: [Bot]
    var tasks: [WorkbenchTask]
    var vacancies: [Vacancy]
    var groups: [GroupRoom]
    var routines: [Routine]
    var rules: [RuleItem]
}

struct Bot: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var code: String?
    var name: String
    var layer: String
    var role: String
    var duty: String
    var status: String
    var tools: String
    var progress: Int
    var token: String
    var okr: String
    var lastDelivery: String
    var testCases: String
    var archive: String
    var knowledge: String
    var skills: String
    var memory: String
    var weekly: String
    var emoji: String?

    var displayCode: String { code ?? "—" }

    var displayEmoji: String {
        if let emoji, !emoji.isEmpty { return emoji }
        switch id {
        case "chief": return "🧠"
        case "strategy": return "♟️"
        case "coo": return "📋"
        case "finance": return "💹"
        case "critic": return "⚔️"
        case "director": return "🎬"
        case "knowledge": return "📚"
        case "designer": return "🎨"
        case "writer": return "✍️"
        case "hoppi": return "📕"
        case "negotiator": return "🤝"
        case "strategist": return "🗺️"
        case "intel": return "🕵️"
        case "lead-hunt": return "🔍"
        case "threadway": return "🧵"
        case "seo": return "📈"
        case "mail": return "✉️"
        case "coach": return "🎙️"
        case "patrol": return "🛡️"
        default: return "🤖"
        }
    }

    var folderName: String {
        switch id {
        case "chief": return "最强大脑"
        case "strategy": return "战略官"
        case "coo": return "COO"
        case "finance": return "财务官"
        case "critic": return "反调官"
        case "director": return "视频导演"
        case "knowledge": return "知识官"
        case "designer": return "设计师"
        case "writer": return "主笔"
        case "hoppi": return "小红书助理Hoppi"
        case "negotiator": return "谈判专家"
        case "strategist": return "兵法策略师"
        case "intel": return "情报官"
        case "lead-hunt": return "外贸客户挖掘"
        case "threadway": return "Threadway"
        case "seo": return "Super-SEO-Hub"
        case "mail": return "超级邮件助手"
        case "coach": return "表达教练"
        case "patrol": return "巡逻官"
        default: return name
        }
    }

    var avatarURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/超级工作台/bots")
            .appendingPathComponent(folderName)
            .appendingPathComponent("avatar.png")
    }

    var layerShort: String {
        if layer.contains("Studio") || layer.contains("执行") { return "Studio" }
        if layer.contains("幕僚") { return "幕僚室" }
        if layer.contains("生活") { return "生活层" }
        if layer.contains("系统") { return "系统" }
        return layer
    }
}

struct WorkbenchTask: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var title: String
    var status: String
    var note: String
    var executor: String
    var reviewer: String
}

struct Vacancy: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String
    var layer: String
    var duty: String
    var toolNote: String
    var priority: Bool?
    var confirmed: Bool
}

struct GroupRoom: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String
    var members: [String]
    var date: String
    var steps: [GroupStep]
}

struct GroupStep: Codable, Equatable, Hashable {
    var title: String
    var detail: String
}

struct Routine: Codable, Equatable, Identifiable, Hashable {
    var name: String
    var when: String
    var who: String
    var what: String
    var status: String?
    var id: String { name }
}

struct RuleItem: Codable, Equatable, Identifiable, Hashable {
    var text: String
    var meta: String
    var id: String { text }
}

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case overview = "总览"
    case roster = "员工档案"
    case tasks = "任务看板"
    case rooms = "群聊协作"
    case routines = "定时巡检"
    case hiring = "招聘规划"
    case rules = "规则与文档"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .roster: return "person.2"
        case .tasks: return "rectangle.split.3x1"
        case .rooms: return "bubble.left.and.bubble.right"
        case .routines: return "clock.arrow.2.circlepath"
        case .hiring: return "person.badge.plus"
        case .rules: return "checklist"
        }
    }

    var group: String {
        switch self {
        case .overview, .roster, .tasks: return "工作台"
        case .rooms, .routines: return "协作与运维"
        case .hiring, .rules: return "组织与规则"
        }
    }
}

enum TaskColumn: String, CaseIterable, Identifiable {
    case todo = "待办"
    case doing = "进行中"
    case review = "验收"
    case done = "完成"
    var id: String { rawValue }
    var colorName: String {
        switch self {
        case .todo: return "blue"
        case .doing: return "orange"
        case .review: return "purple"
        case .done: return "green"
        }
    }
}
