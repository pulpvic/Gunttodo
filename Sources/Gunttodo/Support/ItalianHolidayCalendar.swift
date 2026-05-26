import Foundation

struct ItalianCalendarDay: Identifiable {
    var id: Date { date }
    let date: Date
    let dayNumber: String
    let weekday: String
    let isToday: Bool
    let isWeekend: Bool
    let holidayName: String?
}

enum ItalianHolidayCalendar {
    static func visibleDays(centeredOn date: Date = Date(), pastDays: Int = 3, futureDays: Int = 3) -> [ItalianCalendarDay] {
        let calendar = romeCalendar
        let today = calendar.startOfDay(for: date)
        let past = max(pastDays, 0)
        let future = max(futureDays, 0)

        return (-past...future).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let weekday = calendar.component(.weekday, from: day)

            return ItalianCalendarDay(
                date: day,
                dayNumber: String(calendar.component(.day, from: day)),
                weekday: weekdayTitle(for: weekday),
                isToday: calendar.isDate(day, inSameDayAs: today),
                isWeekend: weekday == 1 || weekday == 7,
                holidayName: holidayName(for: day)
            )
        }
    }

    static func holidayName(for date: Date) -> String? {
        let calendar = romeCalendar
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return nil }

        switch (month, day) {
        case (1, 1): return "Capodanno"
        case (1, 6): return "Epifania"
        case (4, 25): return "Liberazione"
        case (5, 1): return "Lavoro"
        case (6, 2): return "Repubblica"
        case (8, 15): return "Ferragosto"
        case (11, 1): return "Ognissanti"
        case (12, 8): return "Immacolata"
        case (12, 25): return "Natale"
        case (12, 26): return "S. Stefano"
        default:
            guard let easterMonday = easterMonday(year: year) else { return nil }
            return calendar.isDate(date, inSameDayAs: easterMonday) ? "Pasquetta" : nil
        }
    }

    static var romeCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "it_IT")
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        return calendar
    }

    private static func weekdayTitle(for weekday: Int) -> String {
        switch weekday {
        case 1: return "日"
        case 2: return "一"
        case 3: return "二"
        case 4: return "三"
        case 5: return "四"
        case 6: return "五"
        case 7: return "六"
        default: return ""
        }
    }

    private static func easterMonday(year: Int) -> Date? {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1

        let calendar = romeCalendar
        guard let easter = calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: year, month: month, day: day)) else {
            return nil
        }

        return calendar.date(byAdding: .day, value: 1, to: easter)
    }
}
