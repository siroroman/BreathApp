import Testing

@testable import BreathnestKit

@Suite struct ExerciseTests {
    @Test func builtInExercisesAreBoxFourSevenEightCoherentAndSigh() {
        #expect(Exercise.builtIn.map(\.id) == ["box", "four-seven-eight", "coherent", "physiological-sigh"])
    }

    @Test func boxIsInhaleHoldExhaleHold() {
        #expect(Exercise.box.pattern.phases == [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(4)),
            Phase(kind: .exhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(4)),
        ])
    }

    @Test func fourSevenEightIsInhaleHoldExhale() {
        #expect(Exercise.fourSevenEight.pattern.phases == [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(7)),
            Phase(kind: .exhale, duration: .seconds(8)),
        ])
    }

    @Test func coherentIsInhaleExhaleOfFiveAndAHalfSeconds() {
        #expect(Exercise.coherent.pattern.phases == [
            Phase(kind: .inhale, duration: .seconds(5.5)),
            Phase(kind: .exhale, duration: .seconds(5.5)),
        ])
    }

    @Test func physiologicalSighIsTwoInhalesThenExhale() {
        #expect(Exercise.physiologicalSigh.pattern.phases == [
            Phase(kind: .inhale, duration: .seconds(2)),
            Phase(kind: .inhale, duration: .seconds(1)),
            Phase(kind: .exhale, duration: .seconds(6)),
        ])
    }

    @Test func durationOptionsMatchTheSpec() {
        #expect(Exercise.box.durationOptions == [.seconds(60), .seconds(180), .seconds(300), .seconds(600)])
        #expect(Exercise.fourSevenEight.durationOptions == [.seconds(75), .seconds(120), .seconds(150)])
        #expect(Exercise.coherent.durationOptions == [.seconds(60), .seconds(300), .seconds(600), .seconds(1200)])
        #expect(Exercise.physiologicalSigh.durationOptions == [.seconds(60), .seconds(300), .seconds(600)])
    }

    @Test func defaultDurationsMatchTheSpec() {
        #expect(Exercise.box.defaultDuration == .seconds(300))
        #expect(Exercise.fourSevenEight.defaultDuration == .seconds(75))
        #expect(Exercise.coherent.defaultDuration == .seconds(300))
        #expect(Exercise.physiologicalSigh.defaultDuration == .seconds(300))
    }

    @Test(arguments: Exercise.builtIn)
    func patternIsValid(exercise: Exercise) {
        #expect(Pattern(phases: exercise.pattern.phases) != nil)
    }

    @Test(arguments: Exercise.builtIn)
    func defaultDurationIsOneOfTheDurationOptions(exercise: Exercise) {
        #expect(exercise.durationOptions.contains(exercise.defaultDuration))
    }
}
