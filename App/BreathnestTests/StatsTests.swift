import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@testable import Breathnest

@MainActor
@Suite struct StatsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2
        return calendar
    }

    private let us = Locale(identifier: "en_US")

    private func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    private func entry(_ iso: String, minutes: Double = 10, custom: String? = nil) -> LogEntry {
        LogEntry(
            exerciseID: "box", finishedAt: date(iso), length: .seconds(minutes * 60), pattern: Exercise.box.pattern,
            customName: custom
        )
    }

    @Test func theWeekAndTheRowsComeFromTheLog() {
        let backing = InMemoryDocumentStore()
        let log = LogStore(store: backing, now: { date("2026-11-24T07:30:00Z") })
        log.recordCompleted(exercise: .box, length: .seconds(300), customName: nil)
        log.recordCompleted(exercise: .coherent, length: .seconds(600), customName: nil)
        let model = StatsViewModel(log: log, calendar: calendar, now: { date("2026-11-25T10:00:00Z") })
        #expect(model.week.totalMinutes == 15)
        #expect(model.rows.count == 2)
    }

    @Test func aTimeTodayIsNamedTodayAndOtherDaysShowTheDate() {
        let now = date("2026-11-27T12:00:00Z")
        let today = StatsText.when(date("2026-11-27T07:30:00Z"), now: now, calendar: calendar, locale: us)
        // The system puts a narrow no-break space before AM.
        #expect(today.replacingOccurrences(of: "\u{202F}", with: " ") == "Today, 7:30 AM")
        let other = StatsText.when(date("2026-10-27T21:40:00Z"), now: now, calendar: calendar, locale: us)
        #expect(other.contains("Oct"))
        #expect(other.contains("27"))
        #expect(other.contains("9:40"))
    }

    @Test func aCustomRowShowsItsSavedName() {
        #expect(StatsText.name(of: entry("2026-11-27T07:30:00Z", custom: "Evening calm")) == "Evening calm")
    }

    @Test func aBuiltInRowIsNamedFromTheCatalog() {
        #expect(StatsText.name(of: entry("2026-11-27T07:30:00Z")) == "Box breathing")
    }

    @Test func aLengthIsWholeMinutesAndNeverZero() {
        #expect(StatsText.minutes(of: .seconds(600)) == 10)
        #expect(StatsText.minutes(of: .seconds(20)) == 1)
    }

    @Test func aDayIsReadWithItsMinutesAndAFutureDayWithoutThem() {
        let week = WeekSummary(
            entries: [entry("2026-11-23T07:30:00Z", minutes: 5)], now: date("2026-11-24T10:00:00Z"), calendar: calendar
        )
        #expect(StatsText.spokenDay(week.days[0], calendar: calendar, locale: us) == "Monday, 5 min")
        #expect(StatsText.spokenDay(week.days[1], calendar: calendar, locale: us) == "Tuesday, 0 min")
        #expect(StatsText.spokenDay(week.days[2], calendar: calendar, locale: us) == "Wednesday")
    }

    @Test func theDayLettersStartWithTheFirstWeekday() {
        let week = WeekSummary(entries: [], now: date("2026-11-24T10:00:00Z"), calendar: calendar)
        #expect(week.days.map { StatsText.letter(of: $0.date, calendar: calendar) } == ["M", "T", "W", "T", "F", "S", "S"])
    }

    @Test func aRowIsReadAsOneSentence() {
        let row = StatsText.spokenRow(entry("2026-11-27T07:30:00Z"), now: date("2026-11-27T12:00:00Z"), calendar: calendar)
        #expect(row.hasPrefix("Box breathing, "))
        #expect(row.hasSuffix(", 10 min"))
    }

    @Test func selectingATabChangesTheTab() {
        let navigation = AppNavigation()
        #expect(navigation.tab == .exercises)
        navigation.select(.stats)
        #expect(navigation.tab == .stats)
    }
}
