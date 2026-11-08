import Testing

@testable import BreathnestKit

@Suite struct BreathLevelTests {
    @Test func inhaleRunsFromEmptyToFullAndExhaleBack() {
        let pattern = Exercise.coherent.pattern
        #expect(pattern.breathLevel(at: .zero) == 0)
        #expect(pattern.breathLevel(at: .seconds(5.5)) == 1)
        #expect(pattern.breathLevel(at: .seconds(11)) == 0)
    }
}
