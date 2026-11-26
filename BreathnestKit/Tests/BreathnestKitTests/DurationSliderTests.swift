import Testing

@testable import BreathnestKit

@Suite struct DurationSliderTests {
    @Test(arguments: [Exercise.box, .coherent, .physiologicalSigh])
    func otherExercisesSlideFromOneToSixtyMinutesInWholeMinutes(exercise: Exercise) {
        let steps = exercise.sliderDurations
        #expect(steps.count == 60)
        #expect(steps.first == .seconds(60))
        #expect(steps.last == .seconds(3600))
        #expect(zip(steps, steps.dropFirst()).allSatisfy { $1 - $0 == .seconds(60) })
    }

    @Test func fourSevenEightSlidesOnlyBetweenFourAndEightCycles() {
        let steps = Exercise.fourSevenEight.sliderDurations
        #expect(steps == (4 ... 8).map { Duration.seconds(19 * $0) })
        #expect(steps.map { Exercise.fourSevenEight.sessionLength(for: $0).cycleCount } == [4, 5, 6, 7, 8])
    }

    @Test func fourSevenEightSliderNeverOffersALengthBeyondTheChips() {
        let longestChip = Exercise.fourSevenEight.sessionLength(for: Exercise.fourSevenEight.durationOptions.max()!)
        let longestStep = Exercise.fourSevenEight.sliderDurations.last!
        #expect(Exercise.fourSevenEight.sessionLength(for: longestStep).cycleCount == longestChip.cycleCount)
    }

    @Test func everyChipHasASliderStepWithTheSameCycleCount() {
        for exercise in Exercise.builtIn {
            let stepCycles = Set(exercise.sliderDurations.map { exercise.sessionLength(for: $0).cycleCount })
            for option in exercise.durationOptions {
                #expect(stepCycles.contains(exercise.sessionLength(for: option).cycleCount), "\(exercise.id) \(option)")
            }
        }
    }
}
