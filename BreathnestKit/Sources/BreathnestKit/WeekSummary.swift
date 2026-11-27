import Foundation

/// The minutes of practice on each day of the week that contains `now`, from the Log (#58). The week starts on
/// the calendar's first weekday, and a day is cut at midnight in the calendar's time zone, so nothing stored
/// depends on either.
public struct WeekSummary: Sendable, Equatable {
    public enum DayState: Sendable, Equatable {
        /// A day with practice: a filled disc.
        case practiced
        /// A past day, or today, with none: an empty ring.
        case missed
        /// A day after today: a dashed ring.
        case upcoming
    }

    public struct Day: Sendable, Equatable {
        /// The start of the day.
        public let date: Date
        /// Whole minutes, at least 1 for a day with practice.
        public let minutes: Int
        public let state: DayState
        public let isToday: Bool
    }

    public let days: [Day]

    /// The sum of the minutes the days show, so the total always matches the card.
    public var totalMinutes: Int {
        days.reduce(0) { $0 + $1.minutes }
    }

    public init(entries: [LogEntry], now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? today
        days = (0 ..< 7).map { offset in
            let start = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            let seconds = entries
                .filter { $0.finishedAt >= start && $0.finishedAt < end }
                .reduce(0.0) { $0 + $1.length / .seconds(1) }
            let minutes = seconds > 0 ? max(1, Int((seconds / 60).rounded(.toNearestOrAwayFromZero))) : 0
            let state: DayState = if minutes > 0 { .practiced } else if start > today { .upcoming } else { .missed }
            return Day(date: start, minutes: minutes, state: state, isToday: start == today)
        }
    }
}
