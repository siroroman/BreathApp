import Testing

@testable import BreathnestKit

@Suite struct BreathLevelTests {
    @Test func inhaleRunsFromEmptyToFullAndExhaleBack() {
        let pattern = Exercise.coherent.pattern
        #expect(pattern.breathLevel(at: .zero) == 0)
        #expect(pattern.breathLevel(at: .seconds(5.5)) == 1)
        #expect(pattern.breathLevel(at: .seconds(11)) == 0)
    }

    @Test func inhaleRisesAndExhaleFallsStepByStep() {
        let pattern = Exercise.coherent.pattern
        let levels = (0 ... 220).map { pattern.breathLevel(at: .seconds(Double($0) * 0.05)) }
        #expect(zip(levels[0 ... 110], levels[1 ... 110]).allSatisfy { $0 < $1 })
        #expect(zip(levels[110 ... 219], levels[111 ... 220]).allSatisfy { $0 > $1 })
    }

    @Test func endsAreEasedNotLinear() {
        let pattern = Exercise.coherent.pattern
        // Linear would be 0.1 / 5.5 = 0.018 after 0.1 s; an ease-in-out has barely left 0.
        #expect(pattern.breathLevel(at: .seconds(0.1)) < 0.002)
        #expect(pattern.breathLevel(at: .seconds(5.4)) > 0.998)
        #expect(pattern.breathLevel(at: .seconds(5.6)) > 0.998)
        #expect(pattern.breathLevel(at: .seconds(10.9)) < 0.002)
    }
}
