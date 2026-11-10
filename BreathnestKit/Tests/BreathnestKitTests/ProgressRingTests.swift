import Testing

@testable import BreathnestKit

private let base = ContinuousClock().now

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
        let first = try #require(arcs.first)
        let last = try #require(arcs.last)
        #expect(first.start == 0)
        #expect(abs(last.end - 1) < 1e-12)
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

    // MARK: Lit state

    @Test(arguments: Exercise.builtIn)
    func inTheLeadInTheWholeRingIsUnlit(exercise: Exercise) {
        let ring = ProgressRing(pattern: exercise.pattern)
        let fills = ring.fills(phaseIndex: nil, fractionOfPhase: 0)
        #expect(fills.count == ring.arcs.count)
        for (fill, arc) in zip(fills, ring.arcs) {
            #expect(fill == (arc.segmentCount == 0 ? .fraction(0) : .segments(0)))
        }
    }

    @Test func theArcsBeforeThePhaseAreFullAndTheOnesAfterItAreEmpty() {
        let ring = ProgressRing(pattern: Exercise.box.pattern)
        let fills = ring.fills(phaseIndex: 2, fractionOfPhase: 0.5)
        #expect(fills == [.fraction(1), .segments(4), .fraction(0.5), .segments(0)])
    }

    @Test func anInhaleFillsSmoothlyFromTheStartOfItsArc() {
        let ring = ProgressRing(pattern: Exercise.box.pattern)
        #expect(ring.fills(phaseIndex: 0, fractionOfPhase: 0)[0] == .fraction(0))
        #expect(ring.fills(phaseIndex: 0, fractionOfPhase: 0.3)[0] == .fraction(0.3))
    }

    @Test func aHoldLightsOneSegmentWhenItsSecondIsComplete() {
        let ring = ProgressRing(pattern: Exercise.box.pattern)
        #expect(ring.fills(phaseIndex: 1, fractionOfPhase: 0)[1] == .segments(0))
        #expect(ring.fills(phaseIndex: 1, fractionOfPhase: 0.24)[1] == .segments(0))
        #expect(ring.fills(phaseIndex: 1, fractionOfPhase: 0.25)[1] == .segments(1))
        #expect(ring.fills(phaseIndex: 1, fractionOfPhase: 0.76)[1] == .segments(3))
        #expect(ring.fills(phaseIndex: 1, fractionOfPhase: 0.999)[1] == .segments(3))
    }

    @Test func aFinishedHoldIsFullyLitOnceTheNextPhaseStarts() {
        let ring = ProgressRing(pattern: Exercise.fourSevenEight.pattern)
        #expect(ring.fills(phaseIndex: 2, fractionOfPhase: 0)[1] == .segments(7))
    }

    @Test func theRingRestartsAtTheTopAtTheStartOfEachCycle() {
        var engine = SessionEngine(exercise: .box, requested: .seconds(64), startingAt: base)
        let ring = ProgressRing(pattern: Exercise.box.pattern)
        engine.advance(to: base.advanced(by: .seconds(3 + 16)))
        let snapshot = engine.snapshot
        #expect(snapshot.cycle == 2)
        let fills = ring.fills(phaseIndex: snapshot.phaseIndex, fractionOfPhase: snapshot.fractionOfPhase)
        #expect(fills == [.fraction(0), .segments(0), .fraction(0), .segments(0)])
    }

    @Test func theLeadInOfAnEngineIsUnlit() {
        let engine = SessionEngine(exercise: .box, requested: .seconds(64), startingAt: base)
        let snapshot = engine.snapshot
        #expect(snapshot.phaseIndex == nil)
        let fills = ProgressRing(pattern: Exercise.box.pattern)
            .fills(phaseIndex: snapshot.phaseIndex, fractionOfPhase: snapshot.fractionOfPhase)
        #expect(fills == [.fraction(0), .segments(0), .fraction(0), .segments(0)])
    }
}
