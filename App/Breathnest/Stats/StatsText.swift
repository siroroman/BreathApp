import BreathnestKit
import Foundation

/// The text of the Stats section, built from the String Catalog and the system's date formats. The ViewModel holds
/// none of it (ADR 0002). Functions that format dates take the calendar and locale so a test can name them.
enum StatsText {
    /// A custom Exercise shows the name saved in the entry, a built-in one is looked up by ID.
    static func name(of entry: LogEntry) -> String {
        if let custom = entry.customName { return custom }
        return Bundle.main.localizedString(forKey: "exercise.\(entry.exerciseID).name", value: nil, table: nil)
    }

    /// Whole minutes, at least 1: a Session is never shown as "0 min".
    static func minutes(of length: Duration) -> Int {
        max(1, Int((length / .seconds(60)).rounded(.toNearestOrAwayFromZero)))
    }

    static func length(of entry: LogEntry) -> String {
        String(localized: "duration.minutes \(minutes(of: entry.length))")
    }

    static func dayMinutes(_ minutes: Int) -> String {
        String(localized: "duration.minutes \(minutes)")
    }

    /// The week's total, "23 min".
    static func total(_ minutes: Int) -> String {
        dayMinutes(minutes)
    }

    /// "Today, 7:30 AM" for today, "Tue, 27 Oct, 9:40 PM" otherwise, in the system's order and language.
    static func when(
        _ date: Date, now: Date, calendar: Calendar = .current, locale: Locale = .current
    ) -> String {
        let time = date.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .hour().minute())
        if calendar.isDate(date, inSameDayAs: now) {
            return String(localized: "stats.log.today \(time)", locale: locale)
        }
        return date.formatted(Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    /// One letter for the day card: M, T, W, ...
    static func letter(of date: Date, calendar: Calendar = .current) -> String {
        calendar.veryShortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
    }

    /// "Monday, 5 min", and just "Monday" for a day that has not come yet.
    static func spokenDay(
        _ day: WeekSummary.Day, calendar: Calendar = .current, locale: Locale = .current
    ) -> String {
        let weekday = day.date.formatted(
            Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).weekday(.wide)
        )
        guard day.state != .upcoming else { return weekday }
        return String(localized: "stats.a11y.day \(weekday) \(day.minutes)", locale: locale)
    }

    /// A Log row read as one element: "Box breathing, Today, 7:30 AM, 10 min".
    static func spokenRow(_ entry: LogEntry, now: Date, calendar: Calendar = .current) -> String {
        [name(of: entry), when(entry.finishedAt, now: now, calendar: calendar), length(of: entry)]
            .joined(separator: ", ")
    }
}
