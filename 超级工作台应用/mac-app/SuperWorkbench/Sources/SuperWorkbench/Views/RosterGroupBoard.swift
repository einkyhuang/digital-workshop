import SwiftUI

/// Shared employee group board: fixed-size cards in one row per group shell;
/// group shells flow-wrap via OverviewFlowLayout (overview + 员工档案).
struct RosterGroupBoard: View {
    let groups: [(title: String, bots: [Bot])]
    var cardWidth: CGFloat = SWTheme.Roster.cardMinWidth
    var spacing: CGFloat = 16
    var onSelect: (Bot) -> Void

    var body: some View {
        OverviewFlowLayout(spacing: spacing, rowSpacing: spacing) {
            ForEach(groups, id: \.title) { group in
                groupShell(group.title, group.bots)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func groupShell(_ title: String, _ items: [Bot]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(SWTheme.text)
                Text("\(items.count)")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.06))
                    .foregroundStyle(SWTheme.textMuted)
                    .clipShape(Capsule())
            }

            HStack(alignment: .top, spacing: 10) {
                ForEach(items) { bot in
                    Button { onSelect(bot) } label: {
                        EmployeeCard(bot: bot, compact: true)
                    }
                    .buttonStyle(.plain)
                    .frame(width: cardWidth, height: SWTheme.Roster.cardMinHeight, alignment: .top)
                }
            }
        }
        .padding(.horizontal, SWTheme.Roster.groupPadding)
        .padding(.top, SWTheme.Roster.groupPadding)
        .padding(.bottom, 16)
        // Intrinsic size both axes — avoids Spacer-driven infinite height inside Layout/ScrollView
        .fixedSize(horizontal: true, vertical: true)
        .background(SWTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: SWTheme.Radius.group, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SWTheme.Radius.group, style: .continuous)
                .stroke(SWTheme.borderGroup, lineWidth: 1)
        )
    }
}
