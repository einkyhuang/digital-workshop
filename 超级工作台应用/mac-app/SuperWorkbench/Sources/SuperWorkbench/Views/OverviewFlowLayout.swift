import SwiftUI

/// Horizontal flow of subviews: pack as many as fit on a row (by ideal width), wrap whole items to next row.
struct OverviewFlowLayout: Layout {
    var spacing: CGFloat = 16
    var rowSpacing: CGFloat = 16

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxW, subviews: subviews)
        let height = rows.reduce(CGFloat(0)) { acc, row in
            let h = row.map { $0.size.height }.max() ?? 0
            return acc + h
        } + CGFloat(max(0, rows.count - 1)) * rowSpacing
        let width = proposal.width ?? (rows.map { rowWidth($0) }.max() ?? 0)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowH = row.map { $0.size.height }.max() ?? 0
            for item in row {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: item.size.width, height: item.size.height)
                )
                x += item.size.width + spacing
            }
            y += rowH + rowSpacing
        }
    }

    private struct Item {
        var subview: LayoutSubview
        var size: CGSize
    }

    private func rowWidth(_ row: [Item]) -> CGFloat {
        guard !row.isEmpty else { return 0 }
        return row.reduce(CGFloat(0)) { $0 + $1.size.width } + CGFloat(row.count - 1) * spacing
    }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [[Item]] {
        var rows: [[Item]] = []
        var current: [Item] = []
        var used: CGFloat = 0
        let unlimited = ProposedViewSize(width: nil, height: nil)

        for sub in subviews {
            let size = sub.sizeThatFits(unlimited)
            let next = used == 0 ? size.width : used + spacing + size.width
            if used > 0, next > maxWidth, maxWidth.isFinite {
                rows.append(current)
                current = [Item(subview: sub, size: size)]
                used = size.width
            } else {
                current.append(Item(subview: sub, size: size))
                used = next
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}
