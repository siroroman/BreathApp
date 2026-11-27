import BreathnestKit
import Foundation
import Observation

/// The Stats section: the week card and the Log rows, both read from the saved Log. Holds no text (ADR 0002).
/// The calendar is the system's, so the first weekday and the time zone follow the settings of the device.
@MainActor
@Observable
final class StatsViewModel {
    @ObservationIgnored private let log: LogStore
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored let now: @MainActor () -> Date

    init(log: LogStore, calendar: Calendar = .autoupdatingCurrent, now: @escaping @MainActor () -> Date = { Date() }) {
        self.log = log
        self.calendar = calendar
        self.now = now
    }

    var week: WeekSummary {
        week(at: now())
    }

    /// The week at one instant, so the card and the Log rows of one render agree on "today".
    func week(at instant: Date) -> WeekSummary {
        WeekSummary(entries: log.log.entries, now: instant, calendar: calendar)
    }

    /// Newest first.
    var rows: [LogEntry] {
        log.log.newestFirst
    }
}
