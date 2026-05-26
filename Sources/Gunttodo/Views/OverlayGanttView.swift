import SwiftUI

struct OverlayGanttView: View {
    @ObservedObject var store: TaskStore
    @ObservedObject private var weather = WeatherStore.shared

    private var tasks: [TodoTask] {
        store.overlayTasks
    }

    var body: some View {
        ZStack {
            glassHighlights

            VStack(alignment: .leading, spacing: 8) {
                if tasks.isEmpty {
                    Spacer(minLength: 0)
                    header
                    Text("当前没有进行中的任务")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.45), radius: 1, y: 0.5)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer(minLength: 0)
                } else {
                        OverlayTimelineView(
                            tasks: Array(tasks.prefix(store.settings.clampedOverlayMaxTasks)),
                            days: ItalianHolidayCalendar.visibleDays(futureDays: store.settings.overlaySize.futureDays),
                            projectColors: store.settings.projectColors,
                            weatherSummary: weather.summary
                        )
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
        }
        .frame(width: store.settings.overlayWidth, height: overlayHeight)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.78),
                            .white.opacity(0.2),
                            .white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .task {
            await weather.refreshIfNeeded(city: store.settings.weatherCity)
        }
        .onChange(of: store.settings.weatherCity) { _, city in
            Task {
                await weather.refresh(city: city)
            }
        }
    }

    private var overlayHeight: Double {
        store.settings.overlayHeight(displayedTaskCount: max(tasks.count, 1))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "cloud.sun")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(OverlayTimelineMetrics.weatherColor)

            Text(weather.summary)
                .font(.system(size: 11, weight: .semibold))
                .fontWeight(.semibold)
                .foregroundStyle(OverlayTimelineMetrics.weatherColor)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .shadow(color: .black.opacity(0.45), radius: 1, y: 0.5)
    }

    private var glassHighlights: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.09),
                            .white.opacity(0.025),
                            .white.opacity(0.01)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.22),
                            .white.opacity(0.055),
                            .clear
                        ],
                        center: .topLeading,
                        startRadius: 12,
                        endRadius: 210
                    )
                )
                .blendMode(.screen)

            LinearGradient(
                colors: [
                    .white.opacity(0.12),
                    .clear,
                    .white.opacity(0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private enum OverlayTimelineMetrics {
    static let labelWidth = 132.0
    static let labelGap = 9.0
    static let rowSpacing = 6.0
    static let rowHeight = 23.0
    static let weatherColor = Color(red: 0.66, green: 0.86, blue: 1.0).opacity(0.94)
}

private enum TimelinePositioning {
    static func dayWidth(totalWidth: Double, dayCount: Int) -> Double {
        totalWidth / Double(max(dayCount, 1))
    }

    static func centerX(forDayAt index: Int, totalWidth: Double, dayCount: Int) -> Double {
        (Double(index) + 0.5) * dayWidth(totalWidth: totalWidth, dayCount: dayCount)
    }

    static func centerOffset(for date: Date, days: [ItalianCalendarDay], totalWidth: Double) -> Double {
        guard let firstDay = days.first?.date, let lastDay = days.last?.date else {
            return 0
        }

        let calendar = ItalianHolidayCalendar.romeCalendar
        let target = calendar.startOfDay(for: date)
        let first = calendar.startOfDay(for: firstDay)
        let last = calendar.startOfDay(for: lastDay)
        let width = dayWidth(totalWidth: totalWidth, dayCount: days.count)

        if target < first {
            return 0
        }

        if target > last {
            return totalWidth
        }

        let dayOffset = calendar.dateComponents([.day], from: first, to: target).day ?? 0
        return min(max((Double(dayOffset) + 0.5) * width, 0), totalWidth)
    }
}

private struct OverlayTimelineView: View {
    let tasks: [TodoTask]
    let days: [ItalianCalendarDay]
    let projectColors: [String: ProjectColor]
    let weatherSummary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TimelineAxisView(days: days, weatherSummary: weatherSummary)

            TimelineTaskChartView(tasks: tasks, days: days, projectColors: projectColors)
        }
    }
}

private struct TimelineAxisView: View {
    let days: [ItalianCalendarDay]
    let weatherSummary: String

    var body: some View {
        HStack(spacing: OverlayTimelineMetrics.labelGap) {
            HStack(spacing: 5) {
                Image(systemName: "cloud.sun")
                    .font(.system(size: 10, weight: .semibold))

                Text(weatherSummary)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(OverlayTimelineMetrics.weatherColor)
            .shadow(color: .black.opacity(0.45), radius: 1, y: 0.5)
            .frame(width: OverlayTimelineMetrics.labelWidth, alignment: .leading)

            GeometryReader { proxy in
                let dayWidth = TimelinePositioning.dayWidth(totalWidth: proxy.size.width, dayCount: days.count)

                ZStack(alignment: .topLeading) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        Rectangle()
                            .fill(dayBand(for: day))
                            .frame(width: dayWidth, height: 42)
                            .offset(x: Double(index) * dayWidth)

                        VStack(alignment: .center, spacing: 1) {
                            Text(day.dayNumber)
                                .font(.system(size: 12.5, weight: day.isToday ? .bold : .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(numberColor(for: day))

                            Text(day.weekday)
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundStyle(labelColor(for: day))

                            Text(day.holidayName ?? "")
                                .font(.system(size: 7, weight: .medium))
                                .foregroundStyle(labelColor(for: day))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(height: 8, alignment: .center)
                        }
                            .padding(.top, 2)
                            .frame(width: dayWidth, height: 31, alignment: .top)
                            .offset(x: Double(index) * dayWidth)
                    }
                }
            }
            .frame(height: 31)
        }
    }

    private func dayBand(for day: ItalianCalendarDay) -> some ShapeStyle {
        return AnyShapeStyle(.clear)
    }

    private func numberColor(for day: ItalianCalendarDay) -> Color {
        if day.isToday {
            return .white
        }

        if day.isWeekend || day.holidayName != nil {
            return .white.opacity(0.46)
        }

        return .white.opacity(0.86)
    }

    private func labelColor(for day: ItalianCalendarDay) -> Color {
        if day.isWeekend || day.holidayName != nil {
            return .white.opacity(0.4)
        }

        return .white.opacity(0.66)
    }
}

private struct TimelineTaskChartView: View {
    let tasks: [TodoTask]
    let days: [ItalianCalendarDay]
    let projectColors: [String: ProjectColor]

    var body: some View {
        HStack(spacing: OverlayTimelineMetrics.labelGap) {
            VStack(alignment: .leading, spacing: OverlayTimelineMetrics.rowSpacing) {
                ForEach(tasks) { task in
                    OverlayTaskLabel(
                        task: task,
                        projectColor: projectColor(for: task.project)
                    )
                }
            }
            .frame(width: OverlayTimelineMetrics.labelWidth)

            GeometryReader { proxy in
                let dayWidth = TimelinePositioning.dayWidth(totalWidth: proxy.size.width, dayCount: days.count)

                ZStack(alignment: .topLeading) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        let centerX = TimelinePositioning.centerX(forDayAt: index, totalWidth: proxy.size.width, dayCount: days.count)

                        Rectangle()
                            .fill(dayBand(for: day))
                            .frame(width: dayWidth, height: proxy.size.height)
                            .offset(x: Double(index) * dayWidth)

                        if !day.isToday {
                            DateCenterLine(day: day, height: proxy.size.height)
                                .offset(x: centerX - 0.5)
                        }
                    }

                    VStack(alignment: .leading, spacing: OverlayTimelineMetrics.rowSpacing) {
                        ForEach(tasks) { task in
                            OverlayTaskBarRow(task: task, days: days, totalWidth: proxy.size.width)
                        }
                    }

                    ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                        if day.isToday {
                            let centerX = TimelinePositioning.centerX(forDayAt: index, totalWidth: proxy.size.width, dayCount: days.count)

                            DateCenterLine(day: day, height: proxy.size.height)
                                .offset(x: centerX - 0.5)
                                .blendMode(.plusLighter)
                        }
                    }
                }
            }
        }
        .frame(height: rowsHeight)
        .allowsHitTesting(false)
    }

    private var rowsHeight: Double {
        Double(tasks.count) * OverlayTimelineMetrics.rowHeight
            + Double(max(tasks.count - 1, 0)) * OverlayTimelineMetrics.rowSpacing
    }

    private func projectColor(for project: String) -> ProjectColor {
        let key = AppSettings.normalizedProjectName(project)
        return projectColors[key] ?? ProjectColor.defaultColor(for: key)
    }

    private func dayBand(for day: ItalianCalendarDay) -> some ShapeStyle {
        return AnyShapeStyle(.clear)
    }
}

private struct DateCenterLine: View {
    let day: ItalianCalendarDay
    let height: Double

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0.5, y: height))
        }
        .stroke(
            lineColor,
            style: StrokeStyle(lineWidth: day.isToday ? 1.1 : 0.65, lineCap: .round, dash: day.isToday ? [] : [2, 3])
        )
        .frame(width: 1, height: height)
        .shadow(color: day.isToday ? .orange.opacity(0.45) : .clear, radius: 2)
    }

    private var lineColor: Color {
        if day.isToday {
            return .orange.opacity(0.95)
        }

        if day.isWeekend || day.holidayName != nil {
            return .black.opacity(0.42)
        }

        return .white.opacity(0.2)
    }
}

private struct OverlayTaskLabel: View {
    let task: TodoTask
    let projectColor: ProjectColor

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(task.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.96))
                .lineLimit(1)

            Text(AppSettings.normalizedProjectName(task.project))
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(projectColor.color.opacity(0.86))
                .lineLimit(1)
        }
        .frame(width: OverlayTimelineMetrics.labelWidth, height: OverlayTimelineMetrics.rowHeight, alignment: .leading)
        .shadow(color: .black.opacity(0.5), radius: 1, y: 0.5)
    }
}

private struct OverlayTaskBarRow: View {
    let task: TodoTask
    let days: [ItalianCalendarDay]
    let totalWidth: Double

    var body: some View {
        ZStack(alignment: .topLeading) {
            Capsule()
                .fill(.black.opacity(0.24))
                .frame(width: totalWidth, height: 8)
                .position(x: totalWidth / 2, y: rowCenterY)

            Capsule()
                .fill(dueColor.gradient)
                .frame(width: barWidth, height: 8)
                .position(x: barStart + barWidth / 2, y: rowCenterY)
                .shadow(color: dueColor.opacity(0.55), radius: 3)

            if isDueToday {
                Circle()
                    .fill(dueColor)
                    .frame(width: 7, height: 7)
                    .position(x: dueX, y: rowCenterY)
                    .shadow(color: dueColor.opacity(0.65), radius: 3)
            }
        }
        .frame(width: totalWidth, height: OverlayTimelineMetrics.rowHeight, alignment: .topLeading)
    }

    private var rowCenterY: Double {
        OverlayTimelineMetrics.rowHeight / 2
    }

    private var minimumBarWidth: Double {
        8
    }

    private var dueColor: Color {
        let calendar = ItalianHolidayCalendar.romeCalendar
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: task.dueDate)

        if due < today {
            return .red
        }

        if calendar.isDate(due, inSameDayAs: today) {
            return .orange
        }

        return Color(red: 0.52, green: 0.42, blue: 1.0)
    }

    private var isDueToday: Bool {
        let calendar = ItalianHolidayCalendar.romeCalendar
        return calendar.isDate(task.dueDate, inSameDayAs: Date())
    }

    private var barStart: Double {
        if rawBarWidth < minimumBarWidth {
            let centeredStart = dueX - minimumBarWidth / 2
            return min(max(centeredStart, 0), max(totalWidth - minimumBarWidth, 0))
        }

        return rawBarStart
    }

    private var barWidth: Double {
        if rawBarWidth < minimumBarWidth {
            return min(minimumBarWidth, totalWidth - barStart)
        }

        return rawBarWidth
    }

    private var rawBarStart: Double {
        timelineCenterOffset(for: task.startDate)
    }

    private var rawBarWidth: Double {
        max(dueX - rawBarStart, 0)
    }

    private var dueX: Double {
        timelineCenterOffset(for: task.dueDate)
    }

    private func timelineCenterOffset(for date: Date) -> Double {
        TimelinePositioning.centerOffset(for: date, days: days, totalWidth: totalWidth)
    }
}
