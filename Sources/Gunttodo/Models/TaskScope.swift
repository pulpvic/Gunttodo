import Foundation

enum TaskScope: String, CaseIterable, Identifiable {
    case active
    case dueToday
    case overdue
    case completed
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: "正在进行"
        case .dueToday: "今天截止"
        case .overdue: "已经逾期"
        case .completed: "已经完成"
        case .all: "全部任务"
        }
    }

    var systemImage: String {
        switch self {
        case .active: "chart.bar.xaxis"
        case .dueToday: "calendar.badge.clock"
        case .overdue: "exclamationmark.triangle"
        case .completed: "checkmark.circle"
        case .all: "list.bullet.rectangle"
        }
    }
}
