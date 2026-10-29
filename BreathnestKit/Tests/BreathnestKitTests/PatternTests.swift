import Testing

@testable import BreathnestKit

@Suite struct PatternTests {
    @Test func emptyPhaseListFails() {
        #expect(Pattern(phases: []) == nil)
    }

    @Test func zeroDurationPhaseFails() {
        #expect(Pattern(phases: [Phase(kind: .inhale, duration: .seconds(4)), Phase(kind: .hold, duration: .zero)]) ==
            nil)
    }

    @Test func negativeDurationPhaseFails() {
        #expect(Pattern(phases: [Phase(kind: .exhale, duration: .seconds(-1))]) == nil)
    }

    @Test func keepsPhasesInOrder() throws {
        let phases = [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(7)),
            Phase(kind: .exhale, duration: .seconds(8)),
        ]
        let pattern = try #require(Pattern(phases: phases))
        #expect(pattern.phases == phases)
    }

    @Test func allowsTwoPhasesOfTheSameKindInARow() {
        let pattern = Pattern(phases: [
            Phase(kind: .inhale, duration: .seconds(2)),
            Phase(kind: .inhale, duration: .seconds(1)),
            Phase(kind: .exhale, duration: .seconds(6)),
        ])
        #expect(pattern != nil)
    }

    @Test func cycleLengthIsTheSumOfItsPhases() throws {
        let pattern = try #require(Pattern(phases: [
            Phase(kind: .inhale, duration: .seconds(5.5)),
            Phase(kind: .exhale, duration: .seconds(5.5)),
        ]))
        #expect(pattern.cycleLength == .seconds(11))
    }
}
