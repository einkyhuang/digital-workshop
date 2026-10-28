import SwiftUI
import AppKit

struct ProjectsView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var selectedId: String?

    private var projects: [WorkbenchProject] { store.data.projects ?? [] }
    private var selected: WorkbenchProject? {
        projects.first { $0.id == selectedId } ?? projects.first
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("项目列表").font(.headline)
                ForEach(projects) { p in
                    Button {
                        selectedId = p.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name).font(.subheadline.weight(.semibold))
                                Text(p.category).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            TagChip(text: p.status, color: .blue)
                        }
                        .padding(12)
                        .background(selected?.id == p.id ? Color.black.opacity(0.06) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .frame(width: 260)

            if let p = selected {
                ProjectDetailPane(project: p)
            } else {
                Text("暂无项目").foregroundStyle(.secondary)
            }
        }
    }
}

struct ProjectDetailPane: View {
    @EnvironmentObject var store: WorkspaceStore
    let project: WorkbenchProject

    private var owner: Bot? { store.data.bots.first { $0.id == project.ownerBotId } }
    private var collabs: [Bot] {
        project.collabBotIds.compactMap { id in store.data.bots.first { $0.id == id } }
    }
    private var relatedTasks: [WorkbenchTask] {
        store.data.tasks.filter { $0.note.contains(project.id) || $0.note.contains("smart-plan") || $0.title.contains(project.name) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.name).font(.system(size: 26, weight: .bold))
                        Text(project.shortName ?? "").foregroundStyle(.secondary)
                        HStack {
                            TagChip(text: project.category, color: .indigo)
                            TagChip(text: project.status, color: .blue)
                        }
                    }
                    Spacer()
                    Button { store.revealProject(project) } label: { Label("在 Finder 中显示", systemImage: "folder") }
                        .buttonStyle(.bordered)
                    if project.run?.url != nil {
                        Button { store.openProjectURL(project) } label: { Label("打开本地网址", systemImage: "safari") }
                            .buttonStyle(.borderedProminent).tint(.black)
                    }
                }

                Text(project.summary).font(.body)

                groupBox("技术栈") {
                    FlowTech(tags: project.techStack)
                }
                groupBox("路径") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("相对：\(project.localPath)").font(.caption.monospaced())
                        Text(project.absolutePathHint ?? "").font(.caption2).foregroundStyle(.secondary)
                        Text("说明：因含 node_modules/dist（约 883MB）保留在仓库根目录，未挪进 projects/。").font(.caption2).foregroundStyle(.orange)
                    }
                }
                groupBox("启动") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(project.run?.command ?? "—").font(.caption.monospaced())
                        Text(project.run?.url ?? "").font(.caption)
                        Text(project.run?.notes ?? "").font(.caption2).foregroundStyle(.secondary)
                        Button("在终端打开项目目录") {
                            let url = store.projectAbsoluteURL(project)
                            let script = "tell application \"Terminal\" to do script \"cd \(url.path) && ls\""
                            if let apple = NSAppleScript(source: script) {
                                apple.executeAndReturnError(nil)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                groupBox("匹配员工") {
                    VStack(alignment: .leading, spacing: 10) {
                        if let owner {
                            Text("负责人").font(.caption).foregroundStyle(.secondary)
                            staffRow(owner, tag: "负责人")
                        }
                        Text("协作").font(.caption).foregroundStyle(.secondary)
                        ForEach(collabs) { b in
                            staffRow(b, tag: collabTag(b))
                        }
                    }
                }
                groupBox("相关任务") {
                    if relatedTasks.isEmpty {
                        Text("暂无关联任务").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(relatedTasks) { t in
                            HStack {
                                Text(t.title).font(.subheadline)
                                Spacer()
                                TagChip(text: t.status, color: .gray)
                            }
                        }
                    }
                    if let hints = project.relatedTaskHints {
                        Text("建议：" + hints.joined(separator: " · ")).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 80)
            }
        }
    }

    private func collabTag(_ b: Bot) -> String {
        switch b.id {
        case "designer": return "UI"
        case "writer": return "文案"
        case "coo": return "进度"
        default: return "协作"
        }
    }

    private func staffRow(_ b: Bot, tag: String) -> some View {
        HStack(spacing: 10) {
            if let img = NSImage(contentsOf: b.avatarURL) {
                Image(nsImage: img).resizable().scaledToFill()
                    .frame(width: 36, height: 36).clipShape(Circle())
            }
            VStack(alignment: .leading) {
                Text(b.name.components(separatedBy: "-").first ?? b.name).font(.subheadline.weight(.semibold))
                Text(b.role).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            TagChip(text: tag, color: .primary)
            Button("档案") {
                store.selectedBotId = b.id
                store.selectedSection = .roster
                store.showingBotDetail = true
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func groupBox<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.06)))
    }
}

struct FlowTech: View {
    let tags: [String]
    var body: some View {
        FlexibleWrap(tags: tags)
    }
}

struct FlexibleWrap: View {
    let tags: [String]
    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { TagChip(text: $0, color: .blue) }
        }
    }
}
