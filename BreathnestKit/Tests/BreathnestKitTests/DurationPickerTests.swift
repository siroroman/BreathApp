import Testing

@testable import BreathnestKit

@Suite struct DurationPickerTests {
    @Test(arguments: Exercise.builtIn)
    func everyExerciseOffersOneToThirtyWholeMinutes(exercise: Exercise) {
        let values = exercise.pickerDurations
        #expect(values.count == 30)
        #expect(values.first == .seconds(60))
        #expect(values.last == .seconds(1800))
        #expect(zip(values, values.dropFirst()).allSatisfy { $1 - $0 == .seconds(60) })
    }

    @Test func fourSevenEightIsNotLimitedToItsOldSafeLengths() {
        #expect(Exercise.fourSevenEight.pickerDurations.contains(.seconds(1800)))
    }

    @Test(arguments: Exercise.builtIn)
    func theDefaultIsAPickerValue(exercise: Exercise) {
        #expect(exercise.pickerDurations.contains(exercise.defaultPickerDuration))
    }

    @Test func theDefaultIsTheDefaultDurationRoundedToWholeMinutes() {
        #expect(Exercise.box.defaultPickerDuration == .seconds(300))
        #expect(Exercise.fourSevenEight.defaultPickerDuration == .seconds(60))
    }
}
