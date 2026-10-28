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

    var emoji: String {
        switch id {
        case "chief": return "🧠"
        case "lead-hunt": return "🔍"
        case "threadway": return "🧵"
        case "seo": return "📈"
        case "hoppi": return "📕"
        case "mail": return "✉️"
        default: return "🤖"
        }
    }

    var folderName: String {
        switch id {
        case "chief": return "最强大脑"
        case "lead-hunt": return "外贸客户挖掘"
        case "threadway": return "Threadway"
        case "seo": return "Super-SEO-Hub"
        case "hoppi": return "小红书助理Hoppi"
        case "mail": return "超级邮件助手"
        default: return name
        }
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
