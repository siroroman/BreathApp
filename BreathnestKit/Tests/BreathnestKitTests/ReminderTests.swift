import Foundation
import Testing

import BreathnestKitTesting
@testable import BreathnestKit

@Suite struct ReminderTests {
    private func make(
        hour: Int = 7, minute: Int = 30, weekdays: Set<Int> = [1, 2, 3, 4, 5, 6, 7], exerciseID: String = "box"
    ) -> Reminder? {
        Reminder(id: "r1", hour: hour, minute: minute, weekdays: weekdays, exerciseID: exerciseID, isEnabled: true)
    }

    @Test func aValidReminderKeepsItsFields() throws {
        let reminder = try #require(make(hour: 13, minute: 0, weekdays: [2, 3, 4, 5, 6]))
        #expect(reminder.hour == 13 && reminder.minute == 0)
        #expect(reminder.weekdays == [2, 3, 4, 5, 6])
        #expect(reminder.exerciseID == "box")
    }

    @Test func anOutOfRangeTimeOrDayIsRefused() {
        #expect(make(hour: 24) == nil)
        #expect(make(minute: 60) == nil)
        #expect(make(hour: -1) == nil)
        #expect(make(weekdays: [0, 1]) == nil)
        #expect(make(weekdays: [8]) == nil)
    }

    @Test func aReminderNeedsAtLeastOneDay() {
        #expect(make(weekdays: []) == nil)
    }

    @Test func theSummaryNamesTheCommonSets() throws {
        #expect(try #require(make(weekdays: [1, 2, 3, 4, 5, 6, 7])).weekdaySummary == .everyDay)
        #expect(try #require(make(weekdays: [2, 3, 4, 5, 6])).weekdaySummary == .weekdays)
        #expect(try #require(make(weekdays: [1, 7])).weekdaySummary == .weekends)
    }

    @Test func otherSetsListTheirDaysMondayFirst() throws {
        #expect(try #require(make(weekdays: [1, 2, 4])).weekdaySummary == .days([2, 4, 1]))
    }

    @Test func theWeekIsShownMondayToSunday() {
        #expect(Reminder.displayOrder == [2, 3, 4, 5, 6, 7, 1])
    }

    @Test func aReminderRoundTripsThroughJSON() throws {
        let reminder = try #require(make(weekdays: [2, 4]))
        let data = try JSONEncoder().encode(reminder)
        #expect(try JSONDecoder().decode(Reminder.self, from: data) == reminder)
    }

    @Test func aStoredReminderOutOfRangeFailsToDecode() {
        let json = #"{"id":"a","hour":30,"minute":0,"weekdays":[1],"exerciseID":"box","isEnabled":true}"#
        #expect(throws: (any Error).self) { try JSONDecoder().decode(Reminder.self, from: Data(json.utf8)) }
    }
}

@Suite @MainActor struct RemindersDocumentTests {
    @Test func nothingSavedIsAnEmptyList() {
        let saved = SavedDocument<RemindersDocument>(store: InMemoryDocumentStore())
        #expect(saved.value.items.isEmpty)
        #expect(saved.outcome == .empty)
    }

    @Test func savedRemindersComeBackAfterARelaunch() throws {
        let store = InMemoryDocumentStore()
        let reminder = try #require(Reminder(
            id: "a", hour: 22, minute: 0, weekdays: [1, 7], exerciseID: "four-seven-eight", isEnabled: false
        ))
        SavedDocument<RemindersDocument>(store: store).update(RemindersDocument(items: [reminder]))
        let again = SavedDocument<RemindersDocument>(store: store)
        #expect(again.value.items == [reminder])
        #expect(again.outcome == .loaded)
    }

    @Test func aBrokenReminderIsDroppedAndTheRestKept() throws {
        let json = """
        {"version":1,"items":[
        {"id":"a","hour":30,"minute":0,"weekdays":[1],"exerciseID":"box","isEnabled":true},
        {"id":"b","hour":8,"minute":15,"weekdays":[2],"exerciseID":"box","isEnabled":true}]}
        """
        let saved = SavedDocument<RemindersDocument>(store: InMemoryDocumentStore(Data(json.utf8)))
        #expect(saved.value.items.map(\.id) == ["b"])
    }

    @Test func aNewerVersionIsSetAsideAndTheListStartsEmpty() {
        let store = InMemoryDocumentStore(Data(#"{"version":9,"items":[]}"#.utf8))
        let saved = SavedDocument<RemindersDocument>(store: store)
        #expect(saved.outcome == .recovered)
        #expect(saved.value.items.isEmpty)
    }
}
