import BreathnestKit
import BreathnestKitTesting
import Testing

@testable import Breathnest

@MainActor
@Suite struct ExerciseDetailViewModelTests {
    private func makeViewModel(
        _ exercise: Exercise, settings: AppSettingsStore = AppSettingsStore(store: InMemoryDocumentStore()),
        lastSession: LastSessionStore = LastSessionStore(store: InMemoryDocumentStore())
    ) -> ExerciseDetailViewModel {
        ExerciseDetailViewModel(exercise: exercise, settings: settings, lastSession: lastSession)
    }

    @Test func opensOnTheDefaultDurationOption() {
        for exercise in Exercise.builtIn {
            let viewModel = makeViewModel(exercise)
            #expect(viewModel.selectedDuration == exercise.defaultPickerDuration)
        }
    }

    @Test func hapticsAreOnWhenTheSheetOpens() {
        let viewModel = makeViewModel(.box)
        #expect(viewModel.isHapticsOn)
    }

    @Test func boxAtFiveMinutesRunsNineteenCyclesInFiveMinutesFourSeconds() {
        let viewModel = makeViewModel(.box)
        #expect(viewModel.sessionLength.cycleCount == 19)
        #expect(viewModel.sessionLength.totalLength == .seconds(304))
    }

    @Test func choosingAnotherOptionUpdatesTheSessionLength() {
        let viewModel = makeViewModel(.box)
        viewModel.select(duration: .seconds(600))
        #expect(viewModel.selectedDuration == .seconds(600))
        #expect(viewModel.sessionLength.cycleCount == 38)
        #expect(viewModel.sessionLength.totalLength == .seconds(608))
    }

    @Test func incrementAndDecrementMoveTheDurationByOneMinute() {
        let viewModel = makeViewModel(.box)
        viewModel.increment()
        #expect(viewModel.selectedMinutes == 6)
        viewModel.decrement()
        viewModel.decrement()
        #expect(viewModel.selectedMinutes == 4)
    }

    @Test func steppingStopsAtOneAndThirtyMinutes() {
        let viewModel = makeViewModel(.box)
        viewModel.select(minutes: 1)
        #expect(viewModel.canDecrement == false)
        #expect(viewModel.canIncrement)
        viewModel.decrement()
        #expect(viewModel.selectedMinutes == 1)

        viewModel.select(minutes: 30)
        #expect(viewModel.canIncrement == false)
        #expect(viewModel.canDecrement)
        viewModel.increment()
        #expect(viewModel.selectedMinutes == 30)
    }

    @Test func aDurationThatIsNotAnOptionIsIgnored() {
        let viewModel = makeViewModel(.fourSevenEight)
        viewModel.select(duration: .seconds(90))
        #expect(viewModel.selectedDuration == Exercise.fourSevenEight.defaultPickerDuration)
    }

    @Test func theSettingsAreKeptAndTheDurationIsNotWhenTheSheetOpensAgain() {
        let settings = AppSettingsStore(store: InMemoryDocumentStore())
        let viewModel = makeViewModel(.box, settings: settings)
        viewModel.select(duration: .seconds(60))
        viewModel.setHaptics(isOn: false)
        viewModel.setSound(isOn: false)
        viewModel.select(sound: .pulse)

        let reopened = makeViewModel(.box, settings: settings)
        #expect(reopened.isHapticsOn == false)
        #expect(reopened.isSoundOn == false)
        #expect(reopened.soundID == .pulse)
        #expect(reopened.selectedDuration == Exercise.box.defaultPickerDuration)
    }

    @Test func startingASessionWritesTheLastSessionWithTheChosenLength() {
        let lastSession = LastSessionStore(store: InMemoryDocumentStore())
        let viewModel = makeViewModel(.coherent, lastSession: lastSession)
        viewModel.select(duration: .seconds(600))
        #expect(lastSession.quickStart.exercise == .box)
        viewModel.sessionStarted()
        #expect(lastSession.quickStart.exercise == .coherent)
        #expect(lastSession.quickStart.requested == .seconds(600))
    }

    // MARK: Duration picker (#205)

    @Test func theSheetOpensOnTheDefaultRoundedToWholeMinutes() {
        #expect(makeViewModel(.box).selectedMinutes == 5)
        #expect(makeViewModel(.fourSevenEight).selectedMinutes == 1)
    }

    @Test func thePickerOffersOneToThirtyMinutesForEveryExercise() {
        for exercise in Exercise.builtIn {
            #expect(makeViewModel(exercise).pickerMinutes == Array(1 ... 30), "\(exercise.id)")
        }
    }

    @Test func pickingMinutesUpdatesTheDurationAndTheSessionLength() {
        let viewModel = makeViewModel(.box)
        viewModel.select(minutes: 12)
        #expect(viewModel.selectedDuration == .seconds(720))
        #expect(viewModel.selectedMinutes == 12)
        #expect(viewModel.sessionLength.cycleCount == 45)
    }

    @Test func fourSevenEightCanPickThirtyMinutes() {
        let viewModel = makeViewModel(.fourSevenEight)
        viewModel.select(minutes: 30)
        #expect(viewModel.selectedDuration == .seconds(1800))
    }

    @Test func aMinuteOutsideOneToThirtyIsIgnored() {
        let viewModel = makeViewModel(.box)
        viewModel.select(minutes: 31)
        viewModel.select(minutes: 0)
        #expect(viewModel.selectedMinutes == 5)
    }

    @Test func pickingARealLengthIsRunByTheSession() {
        let lastSession = LastSessionStore(store: InMemoryDocumentStore())
        let viewModel = makeViewModel(.box, lastSession: lastSession)
        viewModel.select(minutes: 17)
        viewModel.sessionStarted()
        #expect(lastSession.quickStart.requested == .seconds(1020))
    }
}
