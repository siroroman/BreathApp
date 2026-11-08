import BreathnestKit
import Testing

@testable import Breathnest

@MainActor
@Suite struct ExerciseDetailViewModelTests {
    @Test func opensOnTheDefaultDurationOption() {
        for exercise in Exercise.builtIn {
            let viewModel = ExerciseDetailViewModel(exercise: exercise)
            #expect(viewModel.selectedDuration == exercise.defaultDuration)
        }
    }

    @Test func hapticsAreOnWhenTheSheetOpens() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        #expect(viewModel.isHapticsOn)
    }

    @Test func boxAtFiveMinutesRunsNineteenCyclesInFiveMinutesFourSeconds() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        #expect(viewModel.sessionLength.cycleCount == 19)
        #expect(viewModel.sessionLength.totalLength == .seconds(304))
    }

    @Test func choosingAnotherOptionUpdatesTheSessionLength() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        viewModel.select(duration: .seconds(600))
        #expect(viewModel.selectedDuration == .seconds(600))
        #expect(viewModel.sessionLength.cycleCount == 38)
        #expect(viewModel.sessionLength.totalLength == .seconds(608))
    }

    @Test func aDurationThatIsNotAnOptionIsIgnored() {
        let viewModel = ExerciseDetailViewModel(exercise: .fourSevenEight)
        viewModel.select(duration: .seconds(300))
        #expect(viewModel.selectedDuration == Exercise.fourSevenEight.defaultDuration)
    }

    @Test func turningHapticsOffIsKeptUntilTheNextSheet() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        viewModel.select(duration: .seconds(60))
        viewModel.setHaptics(isOn: false)
        #expect(viewModel.isHapticsOn == false)

        let reopened = ExerciseDetailViewModel(exercise: .box)
        #expect(reopened.isHapticsOn)
        #expect(reopened.selectedDuration == Exercise.box.defaultDuration)
    }

    @Test func fourSevenEightOffersOneMinuteFifteenAndTwoLongerOptions() {
        let viewModel = ExerciseDetailViewModel(exercise: .fourSevenEight)
        #expect(viewModel.durationOptions == [.seconds(75), .seconds(120), .seconds(150)])
        #expect(viewModel.selectedDuration == .seconds(75))
        #expect(viewModel.optionsAreWholeMinutes == false)
    }

    @Test func boxOptionsAreWholeMinutes() {
        #expect(ExerciseDetailViewModel(exercise: .box).optionsAreWholeMinutes)
    }
}
