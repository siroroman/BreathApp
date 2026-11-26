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
            #expect(viewModel.selectedDuration == exercise.defaultDuration)
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

    @Test func aDurationThatIsNotAnOptionIsIgnored() {
        let viewModel = makeViewModel(.fourSevenEight)
        viewModel.select(duration: .seconds(300))
        #expect(viewModel.selectedDuration == Exercise.fourSevenEight.defaultDuration)
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
        #expect(reopened.selectedDuration == Exercise.box.defaultDuration)
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

    @Test func fourSevenEightOffersOneMinuteFifteenAndTwoLongerOptions() {
        let viewModel = makeViewModel(.fourSevenEight)
        #expect(viewModel.durationOptions == [.seconds(75), .seconds(120), .seconds(150)])
        #expect(viewModel.selectedDuration == .seconds(75))
        #expect(viewModel.optionsAreWholeMinutes == false)
    }

    @Test func boxOptionsAreWholeMinutes() {
        #expect(makeViewModel(.box).optionsAreWholeMinutes)
    }
}
