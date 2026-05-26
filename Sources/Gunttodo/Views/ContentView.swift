import SwiftUI

struct ContentView: View {
    @ObservedObject var store: TaskStore
    @State private var scope: TaskScope = .active
    @State private var selectedTaskID: TodoTask.ID?
    @State private var query = ""

    private var visibleTasks: [TodoTask] {
        store.tasks(in: scope, matching: query)
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(store: store, selection: $scope)
                .frame(width: 172)

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)

            ManagementWorkspaceView(
                tasks: visibleTasks,
                selectedTaskID: $selectedTaskID,
                store: store
            )
            .frame(minWidth: 360)
        }
        .background {
            TitlebarAddTaskAccessory {
                let id = store.addTask()
                selectedTaskID = id
                scope = .active
            }
        }
        .background {
            TitlebarSearchAccessory(text: $query, placeholder: "搜索任务或项目")
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 14)
        }
        .onChange(of: scope) { _, _ in
            selectedTaskID = nil
        }
        .onChange(of: query) { _, _ in
            selectedTaskID = nil
        }
    }
}

private struct ManagementWorkspaceView: View {
    let tasks: [TodoTask]
    @Binding var selectedTaskID: TodoTask.ID?
    @ObservedObject var store: TaskStore

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                WorkspaceGlassSurface()

                TaskListView(
                    tasks: tasks,
                    selectedTaskID: $selectedTaskID,
                    store: store
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let selectedTaskID, store.task(id: selectedTaskID) != nil {
                    DetailDrawerView(
                        taskID: selectedTaskID,
                        store: store,
                        close: {
                            self.selectedTaskID = nil
                        }
                    )
                    .frame(width: 390)
                    .padding(.vertical, 6)
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            .animation(.spring(response: 0.28, dampingFraction: 0.86), value: selectedTaskID)
        }
    }
}

private struct WorkspaceGlassSurface: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    .white.opacity(0.18),
                    .white.opacity(0.04),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    .white.opacity(0.22),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 24,
                endRadius: 420
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

private struct DetailDrawerView: View {
    let taskID: TodoTask.ID
    @ObservedObject var store: TaskStore
    let close: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TaskDetailView(taskID: taskID, store: store, onTaskAction: close)
                .scrollContentBackground(.hidden)

            Button(action: close) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)

                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("关闭详情")
            .padding(8)
        }
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.55),
                            .white.opacity(0.14),
                            .white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.24), radius: 24, y: 10)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
