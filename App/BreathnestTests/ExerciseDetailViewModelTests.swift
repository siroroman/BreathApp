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

    // MARK: Duration slider (#55)

    @Test func sliderStartsAtTheStepOfTheDefaultChip() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        #expect(viewModel.sliderDurations[viewModel.sliderPosition] == .seconds(300))
    }

    @Test func movingTheSliderUpdatesTheDurationAndTheResultLine() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        viewModel.select(sliderPosition: 3)
        #expect(viewModel.selectedDuration == .seconds(240))
        #expect(viewModel.sliderPosition == 3)
        #expect(viewModel.sessionLength.cycleCount == 15)
    }

    @Test func theChipFollowsTheSliderWhenItMatchesAndNoChipIsSelectedOtherwise() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        viewModel.select(sliderPosition: 9)
        #expect(viewModel.isSelected(option: .seconds(600)))
        #expect(viewModel.isSelected(option: .seconds(300)) == false)
        viewModel.select(sliderPosition: 3)
        #expect(viewModel.durationOptions.allSatisfy { viewModel.isSelected(option: $0) == false })
    }

    @Test func tappingAChipMovesTheSlider() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        viewModel.select(duration: .seconds(60))
        #expect(viewModel.sliderPosition == 0)
        viewModel.select(duration: .seconds(600))
        #expect(viewModel.sliderPosition == 9)
    }

    @Test func aSliderPositionOutOfRangeIsClamped() {
        let viewModel = ExerciseDetailViewModel(exercise: .box)
        viewModel.select(sliderPosition: 500)
        #expect(viewModel.selectedDuration == .seconds(3600))
        viewModel.select(sliderPosition: -4)
        #expect(viewModel.selectedDuration == .seconds(60))
    }

    @Test func fourSevenEightChipsSelectTheSliderStepWithTheSameCycles() {
        let viewModel = ExerciseDetailViewModel(exercise: .fourSevenEight)
        #expect(viewModel.sliderDurations.count == 5)
        #expect(viewModel.isSelected(option: .seconds(75)))
        viewModel.select(duration: .seconds(120))
        #expect(viewModel.sliderPosition == 2)
        #expect(viewModel.isSelected(option: .seconds(120)))
        viewModel.select(sliderPosition: 3)
        #expect(viewModel.sessionLength.cycleCount == 7)
        #expect(viewModel.durationOptions.allSatisfy { viewModel.isSelected(option: $0) == false })
    }

    @Test func sliderValuesAreWholeMinutesOnlyWhereEveryLengthIsAWholeMinute() {
        #expect(ExerciseDetailViewModel(exercise: .coherent).optionsAreWholeMinutes)
        #expect(ExerciseDetailViewModel(exercise: .fourSevenEight).optionsAreWholeMinutes == false)
    }
}
