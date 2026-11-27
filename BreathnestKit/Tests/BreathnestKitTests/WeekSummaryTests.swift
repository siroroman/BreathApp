import BreathnestKit
import Foundation
import Testing

@Suite struct WeekSummaryTests {
    private func calendar(firstWeekday: Int, zone: String = "UTC") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    /// 2026-11-25 is a Wednesday.
    private func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    private func entry(_ iso: String, minutes: Double) -> LogEntry {
        LogEntry(
            exerciseID: "box", finishedAt: date(iso), length: .seconds(minutes * 60),
            pattern: Exercise.box.pattern, customName: nil
        )
    }

    @Test func aMondayFirstWeekHasSevenDaysFromMondayToSunday() {
        let summary = WeekSummary(entries: [], now: date("2026-11-25T10:00:00Z"), calendar: calendar(firstWeekday: 2))
        #expect(summary.days.count == 7)
        #expect(summary.days.first?.date == date("2026-11-23T00:00:00Z"))
        #expect(summary.days.last?.date == date("2026-11-29T00:00:00Z"))
    }

    @Test func aSundayFirstCalendarStartsTheWeekOnSunday() {
        let summary = WeekSummary(entries: [], now: date("2026-11-25T10:00:00Z"), calendar: calendar(firstWeekday: 1))
        #expect(summary.days.first?.date == date("2026-11-22T00:00:00Z"))
        #expect(summary.days.last?.date == date("2026-11-28T00:00:00Z"))
    }

    @Test func sessionsOfOneDayAddUp() {
        let log = [entry("2026-11-24T07:30:00Z", minutes: 5), entry("2026-11-24T21:00:00Z", minutes: 10)]
        let summary = WeekSummary(entries: log, now: date("2026-11-25T10:00:00Z"), calendar: calendar(firstWeekday: 2))
        #expect(summary.days[1].minutes == 15)
        #expect(summary.totalMinutes == 15)
    }

    @Test func entriesOutsideTheWeekAreIgnored() {
        let log = [entry("2026-11-22T23:59:00Z", minutes: 5), entry("2026-11-30T00:00:00Z", minutes: 5)]
        let summary = WeekSummary(entries: log, now: date("2026-11-25T10:00:00Z"), calendar: calendar(firstWeekday: 2))
        #expect(summary.totalMinutes == 0)
    }

    @Test func theWeekBoundaryDependsOnTheFirstWeekday() {
        // Sunday 2026-11-22 belongs to the week before with Monday first, and starts the week with Sunday first.
        let log = [entry("2026-11-22T12:00:00Z", minutes: 5)]
        let now = date("2026-11-25T10:00:00Z")
        #expect(WeekSummary(entries: log, now: now, calendar: calendar(firstWeekday: 2)).totalMinutes == 0)
        #expect(WeekSummary(entries: log, now: now, calendar: calendar(firstWeekday: 1)).totalMinutes == 5)
    }

    @Test func aDayIsCutAtMidnightInTheCalendarsTimeZone() {
        // 23:30 UTC on Tuesday is 00:30 on Wednesday in Berlin (UTC+1 in November).
        let log = [entry("2026-11-24T23:30:00Z", minutes: 5)]
        let now = date("2026-11-25T10:00:00Z")
        let berlin = WeekSummary(entries: log, now: now, calendar: calendar(firstWeekday: 2, zone: "Europe/Berlin"))
        #expect(berlin.days[1].minutes == 0)
        #expect(berlin.days[2].minutes == 5)
        let utc = WeekSummary(entries: log, now: now, calendar: calendar(firstWeekday: 2))
        #expect(utc.days[1].minutes == 5)
    }

    @Test func aDayWithPracticeIsFilledAPastDayWithoutIsEmptyAndTheFutureIsDashed() {
        let log = [entry("2026-11-24T07:30:00Z", minutes: 5)]
        let summary = WeekSummary(entries: log, now: date("2026-11-26T10:00:00Z"), calendar: calendar(firstWeekday: 2))
        #expect(summary.days.map(\.state) == [.missed, .practiced, .missed, .missed, .upcoming, .upcoming, .upcoming])
        #expect(summary.days[3].isToday)
        #expect(!summary.days[1].isToday)
    }

    @Test func todayWithPracticeIsPracticedAndToday() {
        let log = [entry("2026-11-26T07:30:00Z", minutes: 5)]
        let summary = WeekSummary(entries: log, now: date("2026-11-26T10:00:00Z"), calendar: calendar(firstWeekday: 2))
        #expect(summary.days[3].state == .practiced)
        #expect(summary.days[3].isToday)
    }

    @Test func aShortSessionShowsAtLeastOneMinute() {
        let log = [entry("2026-11-24T07:30:00Z", minutes: 0.4)]
        let summary = WeekSummary(entries: log, now: date("2026-11-25T10:00:00Z"), calendar: calendar(firstWeekday: 2))
        #expect(summary.days[1].minutes == 1)
        #expect(summary.days[1].state == .practiced)
    }

    @Test func theTotalIsTheSumOfTheDaysShown() {
        // 1:15 and 1:15 on two days show "1 min" each, so the total says 2, matching the card.
        let log = [entry("2026-11-24T07:30:00Z", minutes: 1.25), entry("2026-11-25T07:30:00Z", minutes: 1.25)]
        let summary = WeekSummary(entries: log, now: date("2026-11-26T10:00:00Z"), calendar: calendar(firstWeekday: 2))
        #expect(summary.totalMinutes == 2)
    }
}
