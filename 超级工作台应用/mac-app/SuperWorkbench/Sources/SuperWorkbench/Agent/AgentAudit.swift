import Foundation

struct AgentAuditEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var at: Date
    var action: String
    var paramsSummary: String
    var ok: Bool
    var detail: String
    var undoable: Bool
    /// Serialized before-snapshot for undo (task list slice)
    var beforeJSON: String?
    var afterJSON: String?
}

@MainActor
final class AgentAuditLog {
    private(set) var entries: [AgentAuditEntry] = []
    private var undoStack: [AgentAuditEntry] = []
    private let dir: URL

    init(repoRoot: URL) {
        dir = repoRoot.appendingPathComponent("超级工作台应用/data/private/agent-audit")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    func record(_ e: AgentAuditEntry) {
        entries.append(e)
        if e.undoable && e.ok { undoStack.append(e) }
        persist(e)
    }

    func popUndo() -> AgentAuditEntry? {
        undoStack.popLast()
    }

    private func persist(_ e: AgentAuditEntry) {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let name = "\(fmt.string(from: e.at).replacingOccurrences(of: ":", with: "-"))_\(e.action).json"
        let url = dir.appendingPathComponent(name)
        if let data = try? JSONEncoder().encode(e) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
