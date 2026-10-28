import SwiftUI
import AppKit

struct EmployeeCard: View {
    let bot: Bot
    var compact: Bool = false
    var dense: Bool = false
    @State private var hovering = false

    private var avatarOuter: CGFloat { dense ? 64 : (compact ? SWTheme.Roster.avatarOuter : 112) }
    private var avatarInner: CGFloat { dense ? 56 : (compact ? SWTheme.Roster.avatarInner : 104) }
    private var minH: CGFloat { dense ? 168 : (compact ? SWTheme.Roster.cardMinHeight : 280) }
    private var corner: CGFloat { dense ? 20 : SWTheme.Radius.card }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: dense ? 8 : (compact ? 12 : 20))

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: avatarOuter, height: avatarOuter)
                    .shadow(color: .black.opacity(0.08), radius: dense ? 4 : 8, y: 2)
                avatarView
                    .frame(width: avatarInner, height: avatarInner)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: dense ? 3 : 4))
            }

            if !dense {
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
            } else {
                Spacer(minLength: 6)
            }

            Spacer(minLength: dense ? 8 : (compact ? 16 : 28))

            HStack(alignment: .center) {
                Text(bot.displayCode)
                    .font(.system(size: dense ? 10 : 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, dense ? 8 : 10)
                    .padding(.vertical, dense ? 3 : 5)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
                if !dense {
                    Text(bot.displayGroup)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(white: 0.55))
                        .lineLimit(1)
                } else {
                    Circle().fill(SWTheme.statusColor(bot.status)).frame(width: 6, height: 6)
                }
            }

            VStack(alignment: .leading, spacing: dense ? 2 : 4) {
                Text(displayNick(bot.name))
                    .font(.system(size: dense ? 15 : (compact ? 18 : 20), weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(displayTitle(bot.name, bot.role))
                    .font(.system(size: dense ? 11 : 12))
                    .foregroundStyle(Color(white: 0.45))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, dense ? 6 : 10)
        }
        .padding(.horizontal, dense ? 12 : 18)
        .padding(.bottom, dense ? 12 : 18)
        .frame(maxWidth: .infinity)
        .frame(minHeight: minH)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(hovering ? 0.12 : 0.05), radius: hovering ? 12 : 6, y: hovering ? 6 : 3)
        .scaleEffect(hovering ? 1.015 : 1.0)
        .animation(.easeOut(duration: 0.15), value: hovering)
        .onHover { hovering = $0 }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let img = NSImage(contentsOf: bot.avatarURL) {
            Image(nsImage: img).resizable().scaledToFill()
        } else {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.85), .purple.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Text(String(shortName(bot.name).prefix(1)))
                    .font(.system(size: dense ? 22 : (compact ? 32 : 40), weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private func spacedCode(_ code: String) -> String {
        if code.count >= 2, let first = code.first, first.isLetter {
            return "\(first) \(code.dropFirst())"
        }
        return code
    }
    private func displayNick(_ name: String) -> String {
        if let idx = name.firstIndex(of: "-") { return String(name[..<idx]) }
        return name
    }
    private func displayTitle(_ name: String, _ role: String) -> String {
        if let idx = name.firstIndex(of: "-") {
            let t = String(name[name.index(after: idx)...])
            if !t.isEmpty { return t }
        }
        return role
    }
    private func shortName(_ name: String) -> String { displayNick(name) }
}
