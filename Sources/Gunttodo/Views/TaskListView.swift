import SwiftUI

struct TaskListView: View {
    let tasks: [TodoTask]
    @Binding var selectedTaskID: TodoTask.ID?
    @ObservedObject var store: TaskStore

    var body: some View {
        if tasks.isEmpty {
            ContentUnavailableView("没有任务", systemImage: "checklist", description: Text("新建一个任务后，浮窗会自动更新。"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selectedTaskID) {
                ForEach(tasks) { task in
                    TaskRowView(
                        task: task,
                        projectColor: store.projectColor(for: task.project)
                    )
                    .tag(task.id)
                    .contextMenu {
                        if task.isDone {
                            Button("重新开始") {
                                store.reactivate(id: task.id)
                                selectedTaskID = nil
                            }
                        } else {
                            Button("标记完成") {
                                store.markDone(id: task.id)
                                selectedTaskID = nil
                            }
                        }

                        Button("删除", role: .destructive) {
                            store.deleteTasks(ids: [task.id])
                        }
                    }
                }
                .onDelete { indexSet in
                    let ids = Set(indexSet.compactMap { tasks.indices.contains($0) ? tasks[$0].id : nil })
                    store.deleteTasks(ids: ids)
                }
            }
            .listStyle(.inset)
        }
    }
}

struct TaskRowView: View {
    let task: TodoTask
    let projectColor: ProjectColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(FriendlyDate.relativeDueText(for: task.dueDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                ProjectBadge(project: task.project, projectColor: projectColor)
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
    }
}

private struct ProjectBadge: View {
    let project: String
    let projectColor: ProjectColor

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(projectColor.color.gradient)
                .frame(width: 7, height: 7)

            Text(AppSettings.normalizedProjectName(project))
                .foregroundStyle(projectColor.color)
                .lineLimit(1)
        }
    }
}
