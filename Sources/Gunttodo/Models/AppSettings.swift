import Foundation

struct AppSettings: Codable, Equatable {
    var isOverlayVisible: Bool = true
    var overlayScreenIndex: Int = 0
    var overlayCorner: OverlayCorner = .bottomLeft
    var overlayOpacity: Double = 0.12
    var overlaySize: OverlaySize = .short
    var overlayAllowsMouse: Bool = false
    var overlayMaxTasks: Int = 5
    var weatherCity: String = "米兰"
    var projectColors: [String: ProjectColor] = [:]

    static let defaultProjectName = "未分组"

    var clampedOverlayMaxTasks: Int {
        min(max(overlayMaxTasks, 1), 10)
    }

    var overlayWidth: Double {
        overlaySize.width
    }

    var overlayHeight: Double {
        overlaySize.height(forTaskLimit: clampedOverlayMaxTasks)
    }

    func overlayHeight(displayedTaskCount: Int) -> Double {
        overlaySize.height(forDisplayedTaskCount: displayedTaskCount, taskLimit: clampedOverlayMaxTasks)
    }

    func projectColor(for project: String) -> ProjectColor {
        let key = Self.normalizedProjectName(project)
        return projectColors[key] ?? ProjectColor.defaultColor(for: key)
    }

    static func normalizedProjectName(_ project: String) -> String {
        let trimmed = project.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultProjectName : trimmed
    }

    init() {}

    enum CodingKeys: String, CodingKey {
        case isOverlayVisible
        case overlayScreenIndex
        case overlayCorner
        case overlayOpacity
        case overlaySize
        case overlayAllowsMouse
        case overlayMaxTasks
        case weatherCity
        case projectColors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isOverlayVisible = try container.decodeIfPresent(Bool.self, forKey: .isOverlayVisible) ?? true
        overlayScreenIndex = try container.decodeIfPresent(Int.self, forKey: .overlayScreenIndex) ?? 0
        overlayCorner = try container.decodeIfPresent(OverlayCorner.self, forKey: .overlayCorner) ?? .bottomLeft
        overlayOpacity = try container.decodeIfPresent(Double.self, forKey: .overlayOpacity) ?? 0.12
        overlaySize = try container.decodeIfPresent(OverlaySize.self, forKey: .overlaySize) ?? .short
        overlayAllowsMouse = false
        overlayMaxTasks = try container.decodeIfPresent(Int.self, forKey: .overlayMaxTasks) ?? 5
        weatherCity = try container.decodeIfPresent(String.self, forKey: .weatherCity) ?? "米兰"
        projectColors = try container.decodeIfPresent([String: ProjectColor].self, forKey: .projectColors) ?? [:]
    }
}

enum OverlayCorner: String, CaseIterable, Codable, Identifiable {
    case bottomLeft
    case bottomRight
    case topLeft
    case topRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bottomLeft: "左下"
        case .bottomRight: "右下"
        case .topLeft: "左上"
        case .topRight: "右上"
        }
    }
}

enum OverlaySize: String, CaseIterable, Codable, Identifiable {
    case short
    case medium
    case long

    var id: String { rawValue }

    var title: String {
        switch self {
        case .short: "短"
        case .medium: "中"
        case .long: "长"
        }
    }

    var width: Double {
        switch self {
        case .short: 430
        case .medium: 560
        case .long: 710
        }
    }

    var futureDays: Int {
        switch self {
        case .short: 3
        case .medium: 6
        case .long: 10
        }
    }

    func height(forTaskLimit taskLimit: Int) -> Double {
        height(forDisplayedTaskCount: taskLimit, taskLimit: taskLimit)
    }

    func height(forDisplayedTaskCount displayedTaskCount: Int, taskLimit: Int) -> Double {
        let limit = min(max(taskLimit, 1), 10)
        let rows = Double(min(max(displayedTaskCount, 1), limit))
        return max(116, 58 + rows * 28)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "compact", "comfortable", "short":
            self = .short
        case "medium":
            self = .medium
        case "long":
            self = .long
        default:
            self = .short
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
