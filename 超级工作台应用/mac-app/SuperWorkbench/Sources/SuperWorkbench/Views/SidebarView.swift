import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: WorkspaceStore

    private var groups: [(String, [SidebarSection])] {
        [
            ("工作台", [.overview, .roster, .tasks]),
            ("协作与运维", [.rooms, .routines]),
            ("组织与规则", [.hiring, .rules])
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 32, height: 32)
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 14, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("超级工作台").font(.headline)
                    Text("v1.0 · 本地原生").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .padding(16)

            // Workspace switcher
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("个人主工作区").font(.subheadline.weight(.semibold))
                    Text("\(store.data.bots.count) 员工 · \(store.data.tasks.count) 任务")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.black.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(groups, id: \.0) { group, items in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.uppercased())
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                            ForEach(items) { section in
                                navRow(section)
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("数据文件").font(.caption.weight(.semibold))
                        Text(store.loadError == nil ? "已连接 workspace.json" : "读取异常")
                            .font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.black)
                        Text("KY").font(.caption.bold()).foregroundStyle(.white)
                    }
                    .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KY Workspace").font(.caption.weight(.semibold))
                        Text("ARM64 · 离线本地").font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(10)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(12)
        }
        .background(Color.white)
    }

    private func badge(for section: SidebarSection) -> Int? {
        switch section {
        case .roster: return store.data.bots.count
        case .tasks: return store.data.tasks.count
        case .hiring: return store.data.vacancies.filter { !$0.confirmed }.count
        case .rooms: return store.data.groups.count
        default: return nil
        }
    }

    private func navRow(_ section: SidebarSection) -> some View {
        let selected = store.selectedSection == section
        return Button {
            store.selectedSection = section
            if section != .roster { store.showingBotDetail = false }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .frame(width: 18)
                Text(section.rawValue)
                    .font(.subheadline.weight(selected ? .semibold : .regular))
                Spacer()
                if let n = badge(for: section) {
                    Text("\(n)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(selected ? Color.black.opacity(0.12) : Color.black.opacity(0.06))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? Color.black.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}
