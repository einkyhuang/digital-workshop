import SwiftUI

struct EmployeeCard: View {
    let bot: Bot
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(SWTheme.layerColor(bot.layer).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Text(bot.emoji).font(.title2)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(bot.name).font(.headline).lineLimit(2)
                    Text(bot.role).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(SWTheme.statusColor(bot.status)).frame(width: 8, height: 8)
                    Text(bot.status).font(.caption2).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 6) {
                TagChip(text: bot.layer, color: SWTheme.layerColor(bot.layer))
                TagChip(text: "\(bot.progress)%", color: .gray)
            }
            if !compact {
                ProgressView(value: Double(bot.progress), total: 100)
                    .tint(SWTheme.layerColor(bot.layer))
                VStack(alignment: .leading, spacing: 4) {
                    Text("OKR").font(.caption2).foregroundStyle(.secondary)
                    Text(bot.okr).font(.caption).lineLimit(2)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("最近交付").font(.caption2).foregroundStyle(.secondary)
                    Text(bot.lastDelivery).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                }
            } else {
                Text(bot.okr).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .swCard()
    }
}
