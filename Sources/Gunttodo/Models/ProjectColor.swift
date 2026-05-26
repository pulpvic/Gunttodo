import SwiftUI

enum ProjectColor: String, CaseIterable, Codable, Identifiable {
    case blue
    case violet
    case mint
    case green
    case yellow
    case orange
    case red
    case pink
    case slate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: "蓝色"
        case .violet: "紫色"
        case .mint: "薄荷"
        case .green: "绿色"
        case .yellow: "黄色"
        case .orange: "橙色"
        case .red: "红色"
        case .pink: "粉色"
        case .slate: "灰色"
        }
    }

    var color: Color {
        switch self {
        case .blue:
            Color(red: 0.34, green: 0.62, blue: 1.0)
        case .violet:
            Color(red: 0.58, green: 0.46, blue: 1.0)
        case .mint:
            Color(red: 0.28, green: 0.82, blue: 0.72)
        case .green:
            Color(red: 0.42, green: 0.78, blue: 0.34)
        case .yellow:
            Color(red: 0.95, green: 0.78, blue: 0.26)
        case .orange:
            Color(red: 1.0, green: 0.56, blue: 0.22)
        case .red:
            Color(red: 0.98, green: 0.32, blue: 0.32)
        case .pink:
            Color(red: 0.95, green: 0.42, blue: 0.74)
        case .slate:
            Color(red: 0.62, green: 0.68, blue: 0.74)
        }
    }

    static func defaultColor(for project: String) -> ProjectColor {
        let key = AppSettings.normalizedProjectName(project)
        if key == AppSettings.defaultProjectName {
            return .slate
        }

        let palette: [ProjectColor] = [.blue, .violet, .mint, .green, .yellow, .orange, .red, .pink]
        let checksum = key.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[checksum % palette.count]
    }
}
