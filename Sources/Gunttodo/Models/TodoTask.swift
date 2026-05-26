import Foundation

struct TodoTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var notes: String
    var project: String
    var status: TaskStatus
    var priority: TaskPriority
    var startDate: Date
    var dueDate: Date
    var progress: Double
    var tags: [String]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var isDone: Bool {
        status == .done
    }

    var isInFlight: Bool {
        status == .active || status == .paused || status == .waiting
    }
}

enum TaskStatus: String, CaseIterable, Codable, Identifiable {
    case inbox
    case active
    case waiting
    case paused
    case done

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inbox: "收件箱"
        case .active: "进行中"
        case .waiting: "等待"
        case .paused: "暂停"
        case .done: "完成"
        }
    }

    var systemImage: String {
        switch self {
        case .inbox: "tray"
        case .active: "play.circle.fill"
        case .waiting: "clock"
        case .paused: "pause.circle"
        case .done: "checkmark.circle.fill"
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable, Identifiable, Comparable {
    case low
    case normal
    case high
    case urgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: "低"
        case .normal: "普通"
        case .high: "高"
        case .urgent: "紧急"
        }
    }

    var sortWeight: Int {
        switch self {
        case .low: 0
        case .normal: 1
        case .high: 2
        case .urgent: 3
        }
    }

    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        lhs.sortWeight < rhs.sortWeight
    }
}

