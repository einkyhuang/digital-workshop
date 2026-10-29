import SwiftUI

struct KanbanView: View {
    @EnvironmentObject var store: WorkspaceStore
    @State private var draggingTaskId: String? = nil
    @State private var dropTargetColumn: TaskColumn? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ForEach(TaskColumn.allCases) { col in
                    let n = store.filteredTasks.filter { $0.status == col.rawValue }.count
                    HStack(spacing: 6) {
                        Circle().fill(SWTheme.columnColor(col)).frame(width: 8, height: 8)
                        Text("\(col.rawValue) \(n)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("拖拽卡片到任意列改状态 · 自动写入 workspace.json")
                    .font(.caption2)
                    .foregroundStyle(SWTheme.textMuted)
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(TaskColumn.allCases) { col in
                    column(col)
                }
            }

            if let task = store.data.tasks.first(where: { $0.id == store.selectedTaskId }) {
                TaskEditor(task: task)
            }
            Spacer(minLength: 80)
        }
    }

    private func column(_ col: TaskColumn) -> some View {
        let items = store.filteredTasks.filter { $0.status == col.rawValue }
        let highlighted = dropTargetColumn == col
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(SWTheme.columnColor(col)).frame(width: 8, height: 8)
                Text(col.rawValue).font(.subheadline.weight(.semibold))
                Text("\(items.count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                Spacer()
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if items.isEmpty {
                        Text("暂无\(col.rawValue) · 拖入卡片")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    } else {
                        ForEach(items) { t in
                            taskCard(t, col: col)
                        }
                    }
                }
            }
            .frame(maxHeight: 520)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .top)
        .background(highlighted ? SWTheme.focus.opacity(0.08) : Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(highlighted ? SWTheme.focus : SWTheme.border, lineWidth: highlighted ? 2 : 1)
        )
        .dropDestination(for: String.self) { ids, _ in
            guard let id = ids.first else { return false }
            store.setTaskStatus(id: id, status: col.rawValue)
            draggingTaskId = nil
            dropTargetColumn = nil
            return true
        } isTargeted: { hovering in
            dropTargetColumn = hovering ? col : (dropTargetColumn == col ? nil : dropTargetColumn)
        }
    }

    private func taskCard(_ t: WorkbenchTask, col: TaskColumn) -> some View {
        let selected = store.selectedTaskId == t.id
        let lifting = draggingTaskId == t.id
        return Button {
            store.selectedTaskId = t.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TagChip(text: t.executor.components(separatedBy: " ").first ?? t.executor, color: .blue)
                    Spacer()
                    TagChip(text: col.rawValue, color: SWTheme.columnColor(col))
                }
                Text(t.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary).multilineTextAlignment(.leading)
                Text(t.note).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text("验收：\(t.reviewer)").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.black : SWTheme.border, lineWidth: selected ? 1.5 : 1)
            )
            .shadow(color: lifting ? Color.black.opacity(0.18) : .clear, radius: lifting ? 12 : 0, y: lifting ? 6 : 0)
            .scaleEffect(lifting ? 1.03 : 1.0)
            .opacity(lifting ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: lifting)
        }
        .buttonStyle(.plain)
        .draggable(t.id) {
            // Lifted preview while dragging
            VStack(alignment: .leading, spacing: 6) {
                Text(t.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                Text(col.rawValue).font(.caption2).foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(width: 200, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
            .onAppear { draggingTaskId = t.id }
        }
    }
}

struct TaskEditor: View {
    @EnvironmentObject var store: WorkspaceStore
    @State var task: WorkbenchTask

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("编辑选中任务").font(.headline)
            TextField("标题", text: $task.title)
            TextField("备注", text: $task.note)
            HStack {
                Picker("执行人", selection: $task.executor) {
                    ForEach(store.data.bots.map(\.name), id: \.self) { Text($0).tag($0) }
                }
                Picker("验收人", selection: $task.reviewer) {
                    ForEach(store.data.bots.map(\.name) + ["用户"], id: \.self) { Text($0).tag($0) }
                }
                Picker("状态", selection: $task.status) {
                    ForEach(TaskColumn.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
            }
            HStack {
                Button("保存") { store.updateTask(task) }
                    .buttonStyle(.borderedProminent).tint(.black)
                Button("← 上一列") { store.moveTask(task.id, direction: -1); reload() }
                Button("下一列 →") { store.moveTask(task.id, direction: 1); reload() }
                Button("删除", role: .destructive) { store.deleteTask(task.id) }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SWTheme.border))
        .onChange(of: store.selectedTaskId) { _, _ in reload() }
        .onChange(of: store.data.tasks) { _, _ in reload() }
    }

    private func reload() {
        if let t = store.data.tasks.first(where: { $0.id == store.selectedTaskId }) {
            task = t
        }
    }
}
