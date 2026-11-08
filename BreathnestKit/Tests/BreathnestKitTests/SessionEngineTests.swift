import Testing

@testable import BreathnestKit

/// Made-up time: a base reading plus seconds. Nothing here waits and no clock is faked.
private let base = ContinuousClock().now

private func at(_ seconds: Double) -> ContinuousClock.Instant {
    base.advanced(by: .seconds(seconds))
}

@Suite struct SessionEngineTests {
    // Box breathing: 4 inhale, 4 hold, 4 exhale, 4 hold = a 16 s Cycle, so 64 s is exactly 4 Cycles.
    private func box(_ requested: Duration = .seconds(64)) -> SessionEngine {
        SessionEngine(exercise: .box, requested: requested, startingAt: at(0))
    }

    // MARK: Lead-in

    @Test func startsInTheLeadInWithTheWholeSessionAhead() {
        let snapshot = box().snapshot
        #expect(snapshot.state == .leadIn)
        #expect(snapshot.leadInLeft == .seconds(3))
        #expect(snapshot.phase == nil)
        #expect(snapshot.breathLevel == 0)
        #expect(snapshot.timeLeft == .seconds(64))
        #expect(snapshot.cycle == 1)
        #expect(snapshot.cycleCount == 4)
    }

    @Test func leadInCountsDownAndTheSessionLengthStaysWhole() {
        var engine = box()
        let transitions = engine.advance(to: at(1.5))
        #expect(transitions.isEmpty)
        #expect(engine.snapshot.state == .leadIn)
        #expect(engine.snapshot.leadInLeft == .seconds(1.5))
        #expect(engine.snapshot.timeLeft == .seconds(64))
    }

    @Test func leadInEndsAfterThreeSecondsAndTheFirstPhaseStarts() {
        var engine = box()
        let transitions = engine.advance(to: at(3))
        #expect(transitions == [.leadInEnded, .phaseStarted(.inhale)])
        #expect(engine.snapshot.state == .breathing)
        #expect(engine.snapshot.leadInLeft == .zero)
        #expect(engine.snapshot.timeLeft == .seconds(64))
    }
}
