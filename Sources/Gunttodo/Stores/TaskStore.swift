import Foundation
import SwiftUI

@MainActor
final class TaskStore: ObservableObject {
    static let shared = TaskStore()

    @Published var tasks: [TodoTask] = [] {
        didSet {
            guard !isHydrating else { return }
            saveTasks()
            OverlayPanelController.shared.applySettings()
        }
    }

    @Published var settings: AppSettings = AppSettings() {
        didSet {
            guard !isHydrating else { return }
            saveSettings()
            OverlayPanelController.shared.applySettings()
        }
    }

    @Published var lastError: String?

    private let tasksURL: URL
    private let settingsURL: URL
    private var isHydrating = true

    private init() {
        let baseURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Gunttodo", isDirectory: true)

        tasksURL = baseURL.appendingPathComponent("tasks.json")
        settingsURL = baseURL.appendingPathComponent("settings.json")

        do {
            try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
            tasks = try Self.decode([TodoTask].self, from: tasksURL) ?? Self.sampleTasks()
            settings = try Self.decode(AppSettings.self, from: settingsURL) ?? AppSettings()
            normalizeLoadedTasks()
            normalizeLoadedSettings()
        } catch {
            lastError = error.localizedDescription
            tasks = Self.sampleTasks()
            settings = AppSettings()
        }

        isHydrating = false
        saveTasks()
        saveSettings()
    }

    func task(id: TodoTask.ID?) -> TodoTask? {
        guard let id else { return nil }
        return tasks.first { $0.id == id }
    }

    func tasks(in scope: TaskScope, matching query: String) -> [TodoTask] {
        let calendar = ItalianHolidayCalendar.romeCalendar
        let today = calendar.startOfDay(for: Date())

        let scoped = tasks.filter { task in
            let dueDay = calendar.startOfDay(for: task.dueDate)

            switch scope {
            case .active:
                return task.isInFlight && !task.isDone
            case .dueToday:
                return !task.isDone && calendar.isDate(dueDay, inSameDayAs: today)
            case .overdue:
                return !task.isDone && dueDay < today
            case .completed:
                return task.isDone
            case .all:
                return true
            }
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched: [TodoTask]
        if trimmedQuery.isEmpty {
            searched = scoped
        } else {
            searched = scoped.filter { task in
                task.title.localizedCaseInsensitiveContains(trimmedQuery)
                    || task.project.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }

        return searched.sorted(by: Self.taskSort)
    }

    var overlayTasks: [TodoTask] {
        let active = tasks
            .filter { $0.status == .active || $0.status == .waiting || $0.status == .paused }
            .sorted(by: Self.taskSort)

        if !active.isEmpty {
            return Array(active.prefix(settings.clampedOverlayMaxTasks))
        }

        return Array(tasks.filter { !$0.isDone }.sorted(by: Self.taskSort).prefix(settings.clampedOverlayMaxTasks))
    }

    var overlayDisplayedTaskCount: Int {
        max(overlayTasks.count, 1)
    }

    @discardableResult
    func addTask(title: String = "新任务", status: TaskStatus = .active) -> TodoTask.ID {
        let dates = defaultTaskDates()
        let task = TodoTask(
            title: title,
            notes: "",
            project: "个人",
            status: status,
            priority: .normal,
            startDate: dates.start,
            dueDate: dates.due,
            progress: status == .done ? 1 : 0.15,
            tags: []
        )

        tasks.insert(task, at: 0)
        return task.id
    }

    func updateTask(id: TodoTask.ID, mutate: (inout TodoTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        mutate(&tasks[index])
        tasks[index].progress = min(max(tasks[index].progress, 0), 1)
        if tasks[index].status == .done {
            tasks[index].progress = 1
        }
        tasks[index].updatedAt = Date()
    }

    func markDone(id: TodoTask.ID) {
        updateTask(id: id) { task in
            task.status = .done
            task.progress = 1
        }
    }

    func reactivate(id: TodoTask.ID) {
        updateTask(id: id) { task in
            task.status = .active
            task.progress = min(task.progress, 0.85)
        }
    }

    func deleteTasks(ids: Set<TodoTask.ID>) {
        tasks.removeAll { ids.contains($0.id) }
    }

    func projectColor(for project: String) -> ProjectColor {
        settings.projectColor(for: project)
    }

    func setProjectColor(_ color: ProjectColor, for project: String) {
        let key = AppSettings.normalizedProjectName(project)
        var updated = settings
        updated.projectColors[key] = color
        settings = updated
    }

    func resetSampleData() {
        tasks = Self.sampleTasks()
    }

    private static func taskSort(lhs: TodoTask, rhs: TodoTask) -> Bool {
        if lhs.isDone != rhs.isDone {
            return !lhs.isDone
        }

        if lhs.dueDate != rhs.dueDate {
            return lhs.dueDate < rhs.dueDate
        }

        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }

    private func normalizeLoadedTasks() {
        for index in tasks.indices {
            tasks[index].progress = min(max(tasks[index].progress, 0), 1)
            if tasks[index].dueDate < tasks[index].startDate {
                tasks[index].dueDate = tasks[index].startDate
            }
        }
    }

    private func normalizeLoadedSettings() {
        if settings.overlayOpacity > 0.3 {
            settings.overlayOpacity = AppSettings().overlayOpacity
        } else {
            settings.overlayOpacity = min(max(settings.overlayOpacity, 0.06), 0.24)
        }
        settings.overlayMaxTasks = settings.clampedOverlayMaxTasks
        settings.overlayScreenIndex = max(settings.overlayScreenIndex, 0)
        settings.overlayAllowsMouse = false
        let city = settings.weatherCity.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.weatherCity = city.isEmpty ? "米兰" : city
        settings.projectColors = settings.projectColors.reduce(into: [:]) { result, entry in
            result[AppSettings.normalizedProjectName(entry.key)] = entry.value
        }
    }

    private func saveTasks() {
        encode(tasks, to: tasksURL)
    }

    private func saveSettings() {
        encode(settings, to: settingsURL)
    }

    private func encode<T: Encodable>(_ value: T, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    private static func sampleTasks() -> [TodoTask] {
        let calendar = Calendar.current
        let now = Date()

        func date(_ component: Calendar.Component, _ value: Int) -> Date {
            calendar.date(byAdding: component, value: value, to: now) ?? now
        }

        return [
            TodoTask(
                title: "确定浮窗默认信息密度",
                notes: "浮窗只保留任务、项目和时间范围，避免变成第二个主界面。",
                project: "Gunttodo",
                status: .active,
                priority: .urgent,
                startDate: date(.hour, -4),
                dueDate: date(.day, 1),
                progress: 0.55,
                tags: ["设计", "浮窗"]
            ),
            TodoTask(
                title: "整理本周开发任务",
                notes: "把大任务拆成小块，主界面负责维护，菜单栏负责快速进入。",
                project: "Gunttodo",
                status: .active,
                priority: .high,
                startDate: date(.day, -1),
                dueDate: date(.day, 3),
                progress: 0.35,
                tags: ["计划"]
            ),
            TodoTask(
                title: "评估提醒和重复任务",
                notes: "第一版先不做通知打扰，后续再决定是否加系统提醒。",
                project: "产品想法",
                status: .waiting,
                priority: .normal,
                startDate: now,
                dueDate: date(.day, 5),
                progress: 0.1,
                tags: ["后续"]
            )
        ]
    }

    private func defaultTaskDates(anchor: Date = Date()) -> (start: Date, due: Date) {
        var calendar = ItalianHolidayCalendar.romeCalendar
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        let day = calendar.startOfDay(for: anchor)
        let start = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day) ?? anchor
        let due = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: day) ?? start
        return (start, due)
    }
}
