import Testing

@testable import BreathnestKit

@Suite struct ProgressRingTests {
    private func seconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }

    // MARK: Arcs

    @Test(arguments: Exercise.builtIn)
    func everyPhaseTakesTheShareOfTheRingThatItsSecondsTakeOfTheCycle(exercise: Exercise) {
        let pattern = exercise.pattern
        let ring = ProgressRing(pattern: pattern)
        let cycle = seconds(pattern.cycleLength)
        #expect(ring.arcs.count == pattern.phases.count)
        for (arc, phase) in zip(ring.arcs, pattern.phases) {
            #expect(arc.kind == phase.kind)
            #expect(abs((arc.end - arc.start) - seconds(phase.duration) / cycle) < 1e-12)
        }
    }

    @Test(arguments: Exercise.builtIn)
    func arcsFollowOneAnotherFromTheTopAndFillTheWholeRing(exercise: Exercise) throws {
        let arcs = ProgressRing(pattern: exercise.pattern).arcs
        #expect(try #require(arcs.first).start == 0)
        #expect(abs(try #require(arcs.last).end - 1) < 1e-12)
        for (previous, next) in zip(arcs, arcs.dropFirst()) {
            #expect(previous.end == next.start)
        }
    }

    @Test func boxHasFourEqualQuartersAndAHoldOfFourSegments() {
        let arcs = ProgressRing(pattern: Exercise.box.pattern).arcs
        #expect(arcs.map(\.kind) == [.inhale, .hold, .exhale, .hold])
        #expect(arcs.map(\.start) == [0, 0.25, 0.5, 0.75])
        #expect(arcs.map(\.segmentCount) == [0, 4, 0, 4])
    }

    @Test func fourSevenEightGivesTheLongHoldSevenSegments() {
        let arcs = ProgressRing(pattern: Exercise.fourSevenEight.pattern).arcs
        #expect(arcs.map(\.kind) == [.inhale, .hold, .exhale])
        #expect(arcs.map(\.segmentCount) == [0, 7, 0])
        #expect(abs(arcs[1].end - arcs[1].start - 7.0 / 19) < 1e-12)
    }

    @Test func coherentBreathingSplitsTheRingInHalves() {
        let arcs = ProgressRing(pattern: Exercise.coherent.pattern).arcs
        #expect(arcs.map(\.start) == [0, 0.5])
        #expect(arcs.map(\.end) == [0.5, 1])
    }

    @Test func physiologicalSighHasTwoInhaleArcsInARow() {
        let arcs = ProgressRing(pattern: Exercise.physiologicalSigh.pattern).arcs
        #expect(arcs.map(\.kind) == [.inhale, .inhale, .exhale])
        #expect(abs(arcs[0].end - 2.0 / 9) < 1e-12)
        #expect(abs(arcs[1].end - 3.0 / 9) < 1e-12)
    }

    @Test func aHoldOrRestLightsOneSegmentPerStartedSecond() throws {
        let pattern = try #require(Pattern(phases: [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(2.5)),
            Phase(kind: .exhale, duration: .seconds(4)),
            Phase(kind: .rest, duration: .seconds(0.4)),
        ]))
        #expect(ProgressRing(pattern: pattern).arcs.map(\.segmentCount) == [0, 3, 0, 1])
    }
}
