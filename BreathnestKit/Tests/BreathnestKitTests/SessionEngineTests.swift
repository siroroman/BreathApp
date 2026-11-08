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

    // MARK: Breathing

    @Test func breathingReportsThePhaseAndHowFarThroughItTheSessionIs() {
        var engine = box()
        engine.advance(to: at(4)) // one second into the first inhale
        let snapshot = engine.snapshot
        #expect(snapshot.phase == Phase(kind: .inhale, duration: .seconds(4)))
        #expect(snapshot.fractionOfPhase == 0.25)
        #expect(snapshot.secondsLeftInPhase == 3)
        #expect(snapshot.timeLeft == .seconds(63))
        #expect(snapshot.cycle == 1)
    }

    @Test func breathLevelComesFromTheBreathLevelFunction() {
        var engine = box()
        engine.advance(to: at(4))
        #expect(engine.snapshot.breathLevel == Exercise.box.pattern.breathLevel(at: .seconds(1)))
        engine.advance(to: at(3 + 20)) // 20 s of breathing: 4 s into the second Cycle
        #expect(engine.snapshot.breathLevel == Exercise.box.pattern.breathLevel(at: .seconds(4)))
    }

    @Test func secondsLeftInThePhaseRoundUpSoACountdownNeverShowsZero() {
        var engine = SessionEngine(exercise: .coherent, requested: .seconds(66), startingAt: at(0))
        engine.advance(to: at(3)) // the first inhale takes 5.5 s
        #expect(engine.snapshot.secondsLeftInPhase == 6)
        engine.advance(to: at(3 + 5.4))
        #expect(engine.snapshot.secondsLeftInPhase == 1)
    }

    @Test func aPhaseStartsExactlyWhenThePreviousOneEnds() {
        var engine = box()
        engine.advance(to: at(3))
        #expect(engine.advance(to: at(3 + 3.999)).isEmpty)
        #expect(engine.advance(to: at(3 + 4)) == [.phaseStarted(.hold)])
        #expect(engine.snapshot.phase?.kind == .hold)
        #expect(engine.snapshot.fractionOfPhase == 0)
        #expect(engine.snapshot.secondsLeftInPhase == 4)
    }

    @Test func aNewCycleStartsWithTheFirstPhaseAgain() {
        var engine = box()
        engine.advance(to: at(3 + 15))
        #expect(engine.snapshot.cycle == 1)
        #expect(engine.advance(to: at(3 + 16)) == [.phaseStarted(.inhale)])
        #expect(engine.snapshot.cycle == 2)
    }

    @Test func theSessionCompletesAfterTheExactTotalLengthPlusTheLeadIn() {
        var engine = box()
        engine.advance(to: at(3 + 63.999))
        #expect(engine.snapshot.state == .breathing)
        #expect(engine.advance(to: at(3 + 64)) == [.completed])
        let snapshot = engine.snapshot
        #expect(snapshot.state == .completed)
        #expect(snapshot.phase == nil)
        #expect(snapshot.timeLeft == .zero)
        #expect(snapshot.cycle == 4)
        #expect(snapshot.breathLevel == 0)
    }

    @Test func aCompletedSessionStaysCompleted() {
        var engine = box()
        engine.advance(to: at(3 + 64))
        #expect(engine.advance(to: at(1000)).isEmpty)
        #expect(engine.snapshot.state == .completed)
    }
}
