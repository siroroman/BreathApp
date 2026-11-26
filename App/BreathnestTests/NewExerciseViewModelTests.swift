import BreathnestKit
import Foundation
import Testing

@testable import Breathnest

@MainActor
@Suite struct NewExerciseViewModelTests {
    @Test func startsWithTheDrawnDefaultsAndNoName() {
        let model = NewExerciseViewModel()
        #expect(model.icon == .ring)
        let seconds: [Int] = [model.inhale, model.holdAfterInhale, model.exhale, model.holdAfterExhale]
        #expect(seconds == [4, 0, 4, 0])
        #expect(!model.canSave)
    }

    @Test func aNameMakesTheDefaultPatternSavable() {
        let model = NewExerciseViewModel()
        model.name = "Calm"
        #expect(model.canSave)
    }

    @Test func aBlankNameIsNotAName() {
        let model = NewExerciseViewModel()
        model.name = "   "
        #expect(!model.canSave)
    }

    @Test func inhaleAndExhaleStopAtOneSecond() {
        let model = NewExerciseViewModel()
        for _ in 0 ..< 10 { model.decrease(.inhale); model.decrease(.exhale) }
        #expect(model.inhale == 1 && model.exhale == 1)
        #expect(!model.canDecrease(.inhale))
    }

    @Test func aHoldReachesZero() {
        let model = NewExerciseViewModel()
        model.increase(.holdAfterInhale)
        model.decrease(.holdAfterInhale)
        model.decrease(.holdAfterInhale)
        #expect(model.holdAfterInhale == 0)
        #expect(!model.canDecrease(.holdAfterInhale))
    }

    @Test func aPhaseStopsAtThirtySeconds() {
        let model = NewExerciseViewModel()
        for _ in 0 ..< 40 { model.increase(.holdAfterExhale) }
        #expect(model.holdAfterExhale == 30)
        #expect(!model.canIncrease(.holdAfterExhale))
    }

    @Test func theSummaryFollowsThePattern() {
        let model = NewExerciseViewModel()
        #expect(model.secondsPerCycle == 8)
        model.increase(.holdAfterInhale)
        #expect(model.secondsPerCycle == 9)
    }

    @Test func savingMakesTheRecordFromWhatWasTyped() throws {
        let model = NewExerciseViewModel()
        model.name = " Evening calm "
        model.icon = .moon
        model.details = "Wind-down"
        let record = try #require(model.makeRecord())
        #expect(record.name == "Evening calm")
        #expect(record.icon == .moon)
        #expect(record.description == "Wind-down")
    }

    @Test func noRecordWithoutAName() {
        #expect(NewExerciseViewModel().makeRecord() == nil)
    }
}

@MainActor
@Suite struct CustomExercisesViewModelTests {
    private final class Memory: DocumentStore, @unchecked Sendable {
        var data: Data?
        func load() throws -> Data? { data }
        func save(_ data: Data) throws { self.data = data }
        func setAside() throws {}
    }

    private func record(_ name: String) -> CustomExerciseRecord {
        CustomExerciseRecord(
            name: name, icon: .sun, description: "", inhale: 3, holdAfterInhale: 0, exhale: 5, holdAfterExhale: 0
        )!
    }

    @Test func aSavedExerciseSurvivesARelaunch() {
        let backing = Memory()
        let first = CustomExercisesViewModel(store: CustomExerciseStore(backing: backing))
        first.add(record("Calm"))
        let second = CustomExercisesViewModel(store: CustomExerciseStore(backing: backing))
        #expect(second.records.map(\.name) == ["Calm"])
    }

    @Test func listKeepsTheSavedOrder() {
        let model = CustomExercisesViewModel(store: CustomExerciseStore(backing: Memory()))
        model.add(record("A"))
        model.add(record("B"))
        #expect(model.records.map(\.name) == ["A", "B"])
    }

    @Test func aSavedExerciseOpensFromNavigation() {
        let model = CustomExercisesViewModel(store: CustomExerciseStore(backing: Memory()))
        let saved = record("Calm")
        model.add(saved)
        let navigation = AppNavigation(customExercises: model)
        navigation.openDetail(of: saved.id)
        #expect(navigation.openExercise == saved.exercise)
    }
}
