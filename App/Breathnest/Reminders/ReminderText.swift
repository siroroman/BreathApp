import BreathnestKit
import Foundation

/// The text of the Reminder screens, built from the String Catalog and the calendar of the locale. The
/// ViewModels hold none of it (ADR 0002).
enum ReminderText {
    /// `7:30 AM` or `07:30`, as the locale writes a time.
    static func time(hour: Int, minute: Int, locale: Locale = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let date = calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: hour, minute: minute))
        return (date ?? .distantPast).formatted(.dateTime.hour().minute().locale(locale))
    }

    /// The letter on a day circle: `M`, `T`, … for a weekday number (1 is Sunday).
    static func letter(of weekday: Int, locale: Locale = .current) -> String {
        calendar(locale).veryShortStandaloneWeekdaySymbols[weekday - 1]
    }

    /// The full name VoiceOver speaks: `Monday`.
    static func dayName(of weekday: Int, locale: Locale = .current) -> String {
        calendar(locale).standaloneWeekdaySymbols[weekday - 1]
    }

    /// The Repeat row's words: `Every day`, `Weekdays`, `Weekends` or the short day names.
    static func summary(_ summary: WeekdaySummary, locale: Locale = .current) -> String {
        switch summary {
        case .everyDay: String(localized: "reminders.days.everyDay")
        case .weekdays: String(localized: "reminders.days.weekdays")
        case .weekends: String(localized: "reminders.days.weekends")
        case let .days(days): days.map { calendar(locale).shortStandaloneWeekdaySymbols[$0 - 1] }
            .joined(separator: ", ")
        }
    }

    /// What the day circles of one Reminder say as one VoiceOver element: `Weekdays: Monday, Tuesday, …`.
    static func spokenDays(_ weekdays: Set<Int>, locale: Locale = .current) -> String {
        let names = Reminder.displayOrder.filter(weekdays.contains).map { dayName(of: $0, locale: locale) }
            .joined(separator: ", ")
        switch Reminder.summary(of: weekdays) {
        case .days: return String(localized: "reminders.days.spokenOther \(names)")
        case let named: return String(localized: "reminders.days.spoken \(summary(named, locale: locale)) \(names)")
        }
    }

    /// The name of the switch: the time and the Exercise, so two switches are never alike.
    static func switchLabel(_ reminder: Reminder, exerciseName: String, locale: Locale = .current) -> String {
        let time = time(hour: reminder.hour, minute: reminder.minute, locale: locale)
        return String(localized: "reminders.switch.label \(time) \(exerciseName)")
    }

    private static func calendar(_ locale: Locale) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        return calendar
    }
}
