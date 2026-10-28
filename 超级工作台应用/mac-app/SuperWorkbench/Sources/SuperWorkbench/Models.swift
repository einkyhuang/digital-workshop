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
    var groupsOrder: [String]?
    var projects: [WorkbenchProject]?
    var websiteProjects: [WebsiteProject]?
    var smartplanSync: SmartplanSyncInfo?
}

struct Bot: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var code: String?
    var group: String?
    var groups: [String]?
    var folder: String?
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
        if let folder, !folder.isEmpty { return folder }
        switch id {
        case "chief": return "管理中枢/最强大脑"
        case "patrol": return "管理中枢/巡逻官"
        case "strategy": return "战略决策/战略官"
        case "critic": return "战略决策/反调官"
        case "strategist": return "战略决策/兵法策略师"
        case "coo": return "运营管理/COO"
        case "finance": return "运营管理/财务官"
        case "seo": return "网站项目/Super-SEO-Hub"
        case "lead-hunt": return "服装外贸/外贸客户挖掘"
        case "threadway": return "服装外贸/Threadway"
        case "designer": return "视觉设计/设计师"
        case "director": return "视觉设计/视频导演"
        case "intel": return "外贸营销/情报官"
        case "negotiator": return "外贸营销/谈判专家"
        case "mail": return "外贸营销/超级邮件助手"
        case "coach": return "个人成长/表达教练"
        case "writer": return "内容营销/主笔"
        case "knowledge": return "内容营销/知识官"
        case "hoppi": return "内容营销/小红书助理Hoppi"
        default: return name
        }
    }

    var displayGroup: String { group ?? "其他" }

    var displayGroups: [String] {
        if let groups, !groups.isEmpty { return groups }
        if let group, !group.isEmpty { return [group] }
        return ["其他"]
    }

    func belongs(to groupName: String) -> Bool {
        displayGroups.contains(groupName)
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

struct WorkbenchProject: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String
    var shortName: String?
    var category: String
    var status: String
    var summary: String
    var techStack: [String]
    var localPath: String
    var absolutePathHint: String?
    var run: ProjectRun?
    var readmePath: String?
    var pointerDoc: String?
    var ownerBotId: String
    var collabBotIds: [String]
    var relatedTaskHints: [String]?
}

struct ProjectRun: Codable, Equatable, Hashable {
    var command: String?
    var url: String?
    var notes: String?
}


struct WebsiteProject: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var name: String
    var category: String
    var status: String
    var localPath: String?
    var url: String?
    var framework: String?
    var description: String?
    var clientName: String?
    var clientCompany: String?
    var totalAmount: Double?
    var depositAmount: Double?
    var paidAmount: Double?
    var unpaidAmount: Double?
    var paymentStatus: String?
    var services: [String]?
    var serviceStartDate: String?
    var serviceEndDate: String?
    var deadline: String?
    var progress: Int?
    var ownerBotId: String?
    var lastModified: String?
    var createdAt: String?
    var updatedAt: String?
    var source: String?
    var dirty: Bool?
    var localOnly: Bool?

    var displayProgress: Int { progress ?? 0 }
    var displayClient: String {
        let a = clientName ?? ""
        let b = clientCompany ?? ""
        if !a.isEmpty && !b.isEmpty { return "\(a) · \(b)" }
        return a.isEmpty ? (b.isEmpty ? "—" : b) : a
    }
}

struct SmartplanSyncInfo: Codable, Equatable, Hashable {
    var lastSyncAt: String?
    var source: String?
    var count: Int?
    var direction: String?
    var note: String?
    var messages: [String]?
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
    case projects = "项目"

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
        case .projects: return "folder"
        }
    }

    var group: String {
        switch self {
        case .overview, .roster, .tasks: return "工作台"
        case .rooms, .routines: return "协作与运维"
        case .hiring, .rules: return "组织与规则"
        case .projects: return "项目"
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
