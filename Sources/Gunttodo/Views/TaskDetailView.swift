import SwiftUI

struct TaskDetailView: View {
    let taskID: TodoTask.ID?
    @ObservedObject var store: TaskStore
    var onTaskAction: () -> Void = {}

    var body: some View {
        if let task = store.task(id: taskID) {
            Form {
                Section("任务") {
                    TextField("标题", text: binding(\.title, default: ""))
                    TextField("项目", text: binding(\.project, default: ""))

                    LabeledContent("项目颜色") {
                        ProjectColorPalette(selected: store.projectColor(for: task.project)) { color in
                            store.setProjectColor(color, for: task.project)
                        }
                    }
                }

                Section("时间") {
                    DateTimeEditor(
                        title: "开始",
                        date: startDateBinding(default: task.startDate),
                        presets: [.todayStart, .tomorrowStart]
                    )

                    DateTimeEditor(
                        title: "截止",
                        date: dueDateBinding(default: task.dueDate),
                        presets: [.todayDue, .tomorrowDue, .threeDaysDue]
                    )
                }

                Section {
                    HStack(spacing: 8) {
                        if task.isDone {
                            Button {
                                store.reactivate(id: task.id)
                                onTaskAction()
                            } label: {
                                Label("重启任务", systemImage: "arrow.3.trianglepath")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                        } else {
                            Button {
                                store.markDone(id: task.id)
                                onTaskAction()
                            } label: {
                                Label("标记完成", systemImage: "checkmark")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }

                        Button {
                            store.deleteTasks(ids: [task.id])
                            onTaskAction()
                        } label: {
                            Label("删除任务", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(.clear)
            .navigationTitle(task.title)
        } else {
            ContentUnavailableView("选择一个任务", systemImage: "list.bullet.rectangle", description: Text("在左侧列表选择任务后，可以编辑日期和项目。"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<TodoTask, Value>, default defaultValue: Value) -> Binding<Value> {
        Binding {
            store.task(id: taskID)?[keyPath: keyPath] ?? defaultValue
        } set: { newValue in
            guard let taskID else { return }
            store.updateTask(id: taskID) { task in
                task[keyPath: keyPath] = newValue
            }
        }
    }

    private func startDateBinding(default defaultValue: Date) -> Binding<Date> {
        Binding {
            store.task(id: taskID)?.startDate ?? defaultValue
        } set: { newValue in
            guard let taskID else { return }
            store.updateTask(id: taskID) { task in
                task.startDate = newValue
                if task.dueDate < newValue {
                    task.dueDate = DatePreset.defaultDueDate(after: newValue)
                }
            }
        }
    }

    private func dueDateBinding(default defaultValue: Date) -> Binding<Date> {
        Binding {
            store.task(id: taskID)?.dueDate ?? defaultValue
        } set: { newValue in
            guard let taskID else { return }
            store.updateTask(id: taskID) { task in
                task.dueDate = max(newValue, task.startDate)
            }
        }
    }
}

private struct DateTimeEditor: View {
    let title: String
    @Binding var date: Date
    let presets: [DatePreset]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("日期")
                        .foregroundStyle(.secondary)
                        .frame(width: 34, alignment: .leading)

                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .fixedSize()

                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    Text("时间")
                        .foregroundStyle(.secondary)
                        .frame(width: 34, alignment: .leading)

                    DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .fixedSize()

                    Spacer(minLength: 0)
                }
            }
            .font(.subheadline)

            HStack(spacing: 6) {
                ForEach(presets) { preset in
                    Button(preset.title) {
                        date = preset.date()
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

private enum DatePreset: String, CaseIterable, Identifiable {
    case todayStart
    case tomorrowStart
    case todayDue
    case tomorrowDue
    case threeDaysDue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todayStart: "今天 10:00"
        case .tomorrowStart: "明天 10:00"
        case .todayDue: "今天 18:30"
        case .tomorrowDue: "明天 18:30"
        case .threeDaysDue: "三天后 18:30"
        }
    }

    func date() -> Date {
        switch self {
        case .todayStart:
            Self.date(dayOffset: 0, hour: 10, minute: 0)
        case .tomorrowStart:
            Self.date(dayOffset: 1, hour: 10, minute: 0)
        case .todayDue:
            Self.date(dayOffset: 0, hour: 18, minute: 30)
        case .tomorrowDue:
            Self.date(dayOffset: 1, hour: 18, minute: 30)
        case .threeDaysDue:
            Self.date(dayOffset: 3, hour: 18, minute: 30)
        }
    }

    static func defaultDueDate(after start: Date) -> Date {
        let calendar = ItalianHolidayCalendar.romeCalendar
        let day = calendar.startOfDay(for: start)
        let due = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: day) ?? start
        return max(due, start)
    }

    private static func date(dayOffset: Int, hour: Int, minute: Int) -> Date {
        let calendar = ItalianHolidayCalendar.romeCalendar
        let today = calendar.startOfDay(for: Date())
        let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
}

private struct ProjectColorPalette: View {
    let selected: ProjectColor
    let onSelect: (ProjectColor) -> Void

    var body: some View {
        HStack(spacing: 7) {
            ForEach(ProjectColor.allCases) { projectColor in
                Button {
                    onSelect(projectColor)
                } label: {
                    ZStack {
                        Circle()
                            .fill(projectColor.color.gradient)

                        Circle()
                            .strokeBorder(
                                selected == projectColor ? Color.white.opacity(0.95) : Color.white.opacity(0.28),
                                lineWidth: selected == projectColor ? 2 : 1
                            )

                        if selected == projectColor {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .help(projectColor.title)
            }
        }
    }
}
