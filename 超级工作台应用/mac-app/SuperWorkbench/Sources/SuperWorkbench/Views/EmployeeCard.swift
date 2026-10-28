import SwiftUI
import AppKit

struct EmployeeCard: View {
    let bot: Bot
    var compact: Bool = false
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: compact ? 12 : 20)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: compact ? 92 : 112, height: compact ? 92 : 112)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                avatar
                    .frame(width: compact ? 84 : 104, height: compact ? 84 : 104)
                    .clipShape(Circle())
            }

            Text(spacedCode(bot.displayCode))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(white: 0.55))
                .padding(.top, 10)

            HStack(spacing: 4) {
                Circle().fill(SWTheme.statusColor(bot.status)).frame(width: 5, height: 5)
                Circle().fill(Color.black.opacity(0.12)).frame(width: 5, height: 5)
                Circle().fill(Color.black.opacity(0.12)).frame(width: 5, height: 5)
            }
            .padding(.top, 6)

            Spacer(minLength: compact ? 16 : 28)

            HStack(alignment: .center) {
                Text(bot.displayCode)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
                Text(bot.layerShort)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(white: 0.55))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(shortName(bot.name))
                    .font(.system(size: compact ? 18 : 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(bot.role)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.45))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .frame(minHeight: compact ? 240 : 280)
        .background(Color(red: 0.945, green: 0.945, blue: 0.948))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(hovering ? 0.14 : 0.06), radius: hovering ? 18 : 10, y: hovering ? 10 : 4)
        .scaleEffect(hovering ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.18), value: hovering)
        .onHover { hovering = $0 }
    }

    @ViewBuilder
    private var avatar: some View {
        let url = bot.avatarURL
        if let img = NSImage(contentsOf: url) {
            Image(nsImage: img).resizable().scaledToFill()
        } else {
            ZStack {
                Circle().fill(
                    LinearGradient(colors: [.blue.opacity(0.7), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                Text(bot.displayEmoji).font(.system(size: compact ? 36 : 44))
            }
        }
    }

    private func spacedCode(_ code: String) -> String {
        if code.count >= 2, let first = code.first, first.isLetter {
            return "\(first) \(code.dropFirst())"
        }
        return code
    }

    private func shortName(_ name: String) -> String {
        if name.contains("|") { return name.components(separatedBy: "|").first!.trimmingCharacters(in: .whitespaces) }
        if name.count > 10 { return String(name.prefix(10)) }
        return name
    }
}
