import SwiftUI

enum SWTheme {
    static let bg = Color(nsColor: NSColor.windowBackgroundColor)
    static let pageBg = Color(red: 0.965, green: 0.968, blue: 0.973) // soft gray
    static let card = Color.white
    static let border = Color.black.opacity(0.08)
    static let muted = Color.secondary
    static let accent = Color.black
    static let sidebarWidth: CGFloat = 260

    static func statusColor(_ status: String) -> Color {
        switch status {
        case "在线": return .green
        case "忙碌": return .orange
        case "空闲": return .gray
        default: return .secondary
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

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SWTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
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
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
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
