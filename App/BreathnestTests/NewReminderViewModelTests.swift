import BreathnestKit
import Foundation
import Testing

@testable import Breathnest

@MainActor
@Suite struct NewReminderViewModelTests {
    @Test func startsAsTheDesignDrawsIt() {
        let model = NewReminderViewModel()
        #expect(model.hour == 7 && model.minute == 30)
        #expect(model.exerciseID == "coherent")
        #expect(model.weekdays == [2, 3, 4, 5, 6])
        #expect(model.summary == .weekdays)
        #expect(model.canAdd)
    }

    @Test func aDayTogglesOnAndOff() {
        let model = NewReminderViewModel()
        model.toggle(1)
        #expect(model.weekdays.contains(1) && model.summary == .days([2, 3, 4, 5, 6, 1]))
        model.toggle(1)
        #expect(!model.weekdays.contains(1))
    }

    @Test func withNoDayTheReminderCannotBeAdded() {
        let model = NewReminderViewModel()
        for day in 1 ... 7 where model.weekdays.contains(day) { model.toggle(day) }
        #expect(!model.canAdd)
    }

    @Test func theTimeFollowsTheWheel() throws {
        let model = NewReminderViewModel()
        model.time = try #require(Calendar.current.date(from: DateComponents(hour: 22, minute: 5)))
        #expect(model.hour == 22 && model.minute == 5)
    }
}
