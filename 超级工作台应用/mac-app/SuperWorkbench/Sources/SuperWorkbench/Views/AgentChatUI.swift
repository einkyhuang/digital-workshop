import SwiftUI
import Foundation

// MARK: - Shared transcript building

enum AgentTranscriptBuilder {
    enum Item: Identifiable {
        case user(AgentChatMessage)
        case assistant(AgentChatMessage)
        case toolGroup([AgentChatMessage])

        var id: String {
            switch self {
            case .user(let m), .assistant(let m):
                return m.id.uuidString
            case .toolGroup(let tools):
                return "tools:" + tools.map { $0.id.uuidString }.joined(separator: "|")
            }
        }
    }

    static func items(from messages: [AgentChatMessage]) -> [Item] {
        var out: [Item] = []
        var toolBuf: [AgentChatMessage] = []
        func flush() {
            guard !toolBuf.isEmpty else { return }
            out.append(.toolGroup(toolBuf))
            toolBuf = []
        }
        for msg in messages {
            switch msg.role {
            case .user:
                flush()
                out.append(.user(msg))
            case .assistant:
                flush()
                let trimmed = msg.content.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }
                out.append(.assistant(msg))
            case .tool:
                // Keep each delegation as its own compact row (not buried in a group).
                if msg.toolName == "delegate_to_employee" {
                    flush()
                    out.append(.toolGroup([msg]))
                } else {
                    toolBuf.append(msg)
                }
            case .system:
                continue
            }
        }
        flush()
        return out
    }
}

enum AgentMarkdown {
    static func text(_ raw: String) -> Text {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        if let attr = try? AttributedString(markdown: raw, options: options) {
            return Text(attr)
        }
        return Text(raw)
    }
}

struct AgentUserBubble: View {
    let content: String
    var body: some View {
        HStack(alignment: .top) {
            Spacer(minLength: 48)
            Text(content)
                .font(.system(size: SWTheme.Typography.body))
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct AgentAssistantMarkdown: View {
    let content: String
    var isActive: Bool = false
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            GlassOrbView(size: 22, isActive: isActive)
                .padding(.top, 2)
            AgentMarkdown.text(content)
                .font(.system(size: SWTheme.Typography.body))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 16)
        }
        .padding(.vertical, 2)
    }
}

struct AgentTypingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            GlassOrbView(size: 22, isActive: true)
            Text("正在思考…")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AgentTranscriptView: View {
    let messages: [AgentChatMessage]
    var isStreaming: Bool = false

    var body: some View {
        let items = AgentTranscriptBuilder.items(from: messages)
        LazyVStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                row(item).id(item.id)
            }
            if isStreaming {
                AgentTypingIndicator().id("typing")
            }
        }
    }

    @ViewBuilder
    private func row(_ item: AgentTranscriptBuilder.Item) -> some View {
        switch item {
        case .user(let msg):
            AgentUserBubble(content: msg.content)
        case .assistant(let msg):
            AgentAssistantMarkdown(content: msg.content)
        case .toolGroup(let tools):
            ToolCallGroupView(tools: tools)
        }
    }
}

// MARK: - Codex-style collapsible tool rows

struct ToolCallGroupView: View {
    let tools: [AgentChatMessage]
    @State private var groupExpanded = false

    var body: some View {
        if tools.count == 1, let only = tools.first {
            ToolCallRowView(msg: only)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { groupExpanded.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("已调用 \(tools.count) 个工具")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        Image(systemName: groupExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                if groupExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(tools) { msg in
                            ToolCallRowView(msg: msg)
                        }
                    }
                    .padding(.leading, 8)
                }
            }
        }
    }
}

struct ToolCallRowView: View {
    let msg: AgentChatMessage
    @State private var expanded = false

    private var tool: String { msg.toolName ?? "tool" }

    private var expandedBody: String {
        if tool == "delegate_to_employee" {
            if let data = msg.content.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let output = obj["output"] as? String,
               !output.isEmpty {
                return output
            }
        }
        return AgentToolPresentation.prettyJSON(msg.content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.12)) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: AgentToolPresentation.iconName(tool))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                    Text(AgentToolPresentation.summary(tool: tool, detail: msg.content, argsSummary: msg.toolArgsSummary))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(expanded ? 3 : 1)
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                    Spacer(minLength: 0)
                    if let ms = msg.ms {
                        Text("\(ms)ms")
                            .font(.system(size: 10).monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            if expanded {
                ScrollView(.vertical, showsIndicators: true) {
                    Text(expandedBody)
                        .font(.system(size: tool == "delegate_to_employee" ? 12 : 10, design: tool == "delegate_to_employee" ? .default : .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: tool == "delegate_to_employee" ? 220 : 160)
                .padding(8)
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct AgentSkillTagsBar: View {
    let ids: [String]
    let labels: [String: String]
    let onRemove: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ids, id: \.self) { id in
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                        Text(labels[id] ?? id)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        Button {
                            onRemove(id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
        }
    }
}
