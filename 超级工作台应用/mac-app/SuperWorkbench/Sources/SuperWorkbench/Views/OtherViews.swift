import SwiftUI

struct RoomsView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(store.data.groups) { g in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(g.name).font(.title3.bold())
                        Spacer()
                        TagChip(text: g.date, color: .gray)
                    }
                    Text(g.members.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
                    ForEach(Array(g.steps.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.caption.bold())
                                .frame(width: 22, height: 22)
                                .background(Color.black)
                                .foregroundStyle(.white)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title).font(.subheadline.weight(.semibold))
                                Text(step.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .swCard()
                    }
                }
                .padding(16)
                .swCard()
            }
            Spacer(minLength: 80)
        }
    }
}

struct RoutinesView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("以下定时任务仅为规划清单，尚未真正创建或调度。")
                .font(.subheadline)
                .foregroundStyle(.orange)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            ForEach(store.data.routines) { r in
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(r.name).font(.headline)
                        Text("\(r.when) · \(r.who)").font(.caption).foregroundStyle(.secondary)
                        Text(r.what).font(.subheadline)
                    }
                    Spacer()
                    TagChip(text: r.status ?? "规划中", color: .orange)
                }
                .padding(14)
                .swCard()
            }
            Spacer(minLength: 80)
        }
    }
}

struct HiringView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if store.data.vacancies.isEmpty {
                Text("花名册岗位均已入职，招聘规划暂无待招项。")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(14).frame(maxWidth: .infinity, alignment: .leading).swCard()
            } else {
            Text("点「确认招聘」仅写入本地 JSON，不会自动创建 Bot。")
                .font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                ForEach(store.data.vacancies) { v in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(v.name).font(.headline)
                            if v.priority == true { TagChip(text: "优先", color: .orange) }
                            Spacer()
                            TagChip(text: v.confirmed ? "已确认" : "待确认", color: v.confirmed ? .green : .gray)
                        }
                        TagChip(text: v.layer, color: SWTheme.layerColor(v.layer))
                        Text(v.duty).font(.caption).foregroundStyle(.secondary)
                        Text(v.toolNote).font(.caption2).foregroundStyle(.secondary)
                        Button(v.confirmed ? "已确认" : "确认招聘") {
                            store.confirmHire(v.id)
                        }
                        .disabled(v.confirmed)
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .swCard()
                }
            }
            Spacer(minLength: 80)
            }
        }
    }
}

struct RulesView: View {
    @EnvironmentObject var store: WorkspaceStore
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(store.data.rules) { r in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text(r.text).font(.subheadline)
                    Spacer()
                    TagChip(text: r.meta, color: .gray)
                }
                .padding(14)
                .swCard()
            }
            Text("权限边界：外部模型只能作为工具调用；Key 按 Bot 单独存放；发信/发布/购买/删除须人工审批。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(12)
            Spacer(minLength: 80)
        }
    }
}
