import BreathnestKit
import Foundation
import Testing

@testable import Breathnest

@Suite struct ReminderTextTests {
    private let us = Locale(identifier: "en_US")

    @Test func aTimeIsWrittenInTheLocale() {
        #expect(ReminderText.time(hour: 7, minute: 30, locale: us).contains("7:30"))
        #expect(ReminderText.time(hour: 13, minute: 0, locale: Locale(identifier: "cs_CZ")) == "13:00")
    }

    @Test func dayLettersStartFromSunday() {
        #expect(ReminderText.letter(of: 2, locale: us) == "M")
        #expect(ReminderText.dayName(of: 1, locale: us) == "Sunday")
    }

    @Test func theSpokenDaysNameTheSetAndEachDay() throws {
        let weekdays = try #require(Reminder(
            hour: 8,
            minute: 0,
            weekdays: [2, 3, 4, 5, 6],
            exerciseID: "box",
            isEnabled: true
        ))
        #expect(ReminderText.spokenDays(weekdays.weekdays, locale: us)
            == "Weekdays: Monday, Tuesday, Wednesday, Thursday, Friday")
    }

    @Test func otherSetsAreIntroducedAsRepeat() {
        #expect(ReminderText.spokenDays([2, 4], locale: us) == "Repeat: Monday, Wednesday")
    }

    @Test func theSummaryListsShortDayNamesInOrder() {
        #expect(ReminderText.summary(.days([2, 4, 1]), locale: us) == "Mon, Wed, Sun")
        #expect(ReminderText.summary(.everyDay) == "Every day")
    }

    @Test func theSwitchIsNamedByTimeAndExercise() throws {
        let reminder = try #require(Reminder(hour: 7, minute: 30, weekdays: [2], exerciseID: "box", isEnabled: true))
        let label = ReminderText.switchLabel(reminder, exerciseName: "Box breathing", locale: us)
        #expect(label.hasSuffix("Box breathing") && label.contains("7:30"))
    }
}
