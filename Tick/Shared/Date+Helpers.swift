import Foundation

extension Date {
    /// Start of the current day in the user's calendar.
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: .now)
    }

    /// Start of the day `days` from today (negative for past).
    static func startOfDay(daysFromToday days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: startOfToday) ?? startOfToday
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

enum DateRanges {
    /// `[startOfToday, startOfTomorrow)` — used by the Today smart view.
    static var today: (start: Date, end: Date) {
        (Date.startOfToday, Date.startOfDay(daysFromToday: 1))
    }

    /// `[startOfToday, startOfToday + 7d)` — used by the Upcoming smart view.
    static var upcoming: (start: Date, end: Date) {
        (Date.startOfToday, Date.startOfDay(daysFromToday: 7))
    }
}

extension Date {
    /// Compact, friendly display for due-date pills, e.g. "Today 5:00 PM".
    var dueDisplay: String {
        let cal = Calendar.current
        let timeString = formatted(date: .omitted, time: .shortened)
        if cal.isDateInToday(self) { return "Today \(timeString)" }
        if cal.isDateInTomorrow(self) { return "Tomorrow \(timeString)" }
        if cal.isDateInYesterday(self) { return "Yesterday \(timeString)" }

        // Within the next 7 days → weekday name; otherwise short date.
        let days = cal.dateComponents([.day], from: .startOfToday, to: startOfDay).day ?? 0
        if (0...6).contains(days) {
            let weekday = formatted(.dateTime.weekday(.wide))
            return "\(weekday) \(timeString)"
        }
        let dateString = formatted(.dateTime.month(.abbreviated).day())
        return "\(dateString) \(timeString)"
    }
}
