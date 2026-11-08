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

    // MARK: Late and earlier times

    @Test func aLateTickReturnsEveryTransitionItCrossedInOrder() {
        var engine = box()
        // Box: inhale 0-4 s, hold 4-8 s, exhale 8-12 s of breathing. One tick lands 9 s in.
        let transitions = engine.advance(to: at(3 + 9))
        #expect(transitions == [.leadInEnded, .phaseStarted(.inhale), .phaseStarted(.hold), .phaseStarted(.exhale)])
        #expect(engine.snapshot.phase?.kind == .exhale)
        #expect(engine.snapshot.fractionOfPhase == 0.25)
    }

    @Test func aTickPastTheEndCrossesEveryPhaseAndCompletes() {
        var engine = box()
        let transitions = engine.advance(to: at(10000))
        #expect(transitions.first == .leadInEnded)
        #expect(transitions.last == .completed)
        #expect(transitions.filter { $0 == .phaseStarted(.inhale) }.count == 4)
        #expect(transitions.count == 1 + 16 + 1) // Lead-in end, 4 Cycles of 4 Phases, completed
        #expect(engine.snapshot.state == .completed)
    }

    @Test func aTimeEarlierThanOneAlreadySeenIsIgnored() {
        var engine = box()
        engine.advance(to: at(10))
        let before = engine.snapshot
        #expect(engine.advance(to: at(5)).isEmpty)
        #expect(engine.snapshot == before)
        // Time still runs from the latest time seen: 11 s is 8 s of breathing.
        engine.advance(to: at(11))
        #expect(engine.snapshot.timeLeft == .seconds(64 - 8))
    }

    @Test func theSameTimeTwiceChangesNothing() {
        var engine = box()
        engine.advance(to: at(10))
        let before = engine.snapshot
        #expect(engine.advance(to: at(10)).isEmpty)
        #expect(engine.snapshot == before)
    }

    // MARK: Pause and Resume

    @Test func pauseFreezesTheSessionMidPhaseAndResumeContinuesFromTheSamePoint() {
        var engine = box()
        engine.advance(to: at(3 + 5)) // 1 s into the hold
        let frozen = engine.snapshot
        #expect(engine.pause(at: at(3 + 5)).isEmpty)
        #expect(engine.snapshot.state == .paused)
        #expect(engine.advance(to: at(3 + 500)).isEmpty)
        #expect(engine.snapshot.phase == frozen.phase)
        #expect(engine.snapshot.fractionOfPhase == frozen.fractionOfPhase)
        #expect(engine.snapshot.timeLeft == frozen.timeLeft)
        #expect(engine.snapshot.breathLevel == frozen.breathLevel)

        engine.resume(at: at(3 + 500))
        #expect(engine.snapshot.state == .breathing)
        #expect(engine.snapshot.timeLeft == frozen.timeLeft)
        // The paused time never counted: 3 more seconds end the hold, 4 s into it.
        #expect(engine.advance(to: at(3 + 503)) == [.phaseStarted(.exhale)])
        #expect(engine.snapshot.timeLeft == .seconds(64 - 8))
    }

    @Test func pauseCountsTheTimeUpToThePauseAndReturnsWhatItCrossed() {
        var engine = box()
        let transitions = engine.pause(at: at(3 + 4.5))
        #expect(transitions == [.leadInEnded, .phaseStarted(.inhale), .phaseStarted(.hold)])
        #expect(engine.snapshot.state == .paused)
        #expect(engine.snapshot.phase?.kind == .hold)
        #expect(engine.snapshot.fractionOfPhase == 0.125)
    }

    @Test func pauseAndResumeDuringTheLeadInKeepTheCountdown() {
        var engine = box()
        engine.pause(at: at(1.5))
        #expect(engine.snapshot.state == .paused)
        #expect(engine.snapshot.leadInLeft == .seconds(1.5))
        engine.resume(at: at(100))
        #expect(engine.snapshot.state == .leadIn)
        #expect(engine.snapshot.leadInLeft == .seconds(1.5))
        #expect(engine.advance(to: at(101.5)) == [.leadInEnded, .phaseStarted(.inhale)])
        #expect(engine.snapshot.timeLeft == .seconds(64))
    }

    @Test func resumingARunningSessionOrPausingAPausedOneChangesNothing() {
        var engine = box()
        engine.advance(to: at(5))
        engine.resume(at: at(6))
        #expect(engine.snapshot.timeLeft == .seconds(64 - 2)) // the 6 s was not counted as paused time
        engine.pause(at: at(7))
        let paused = engine.snapshot
        #expect(engine.pause(at: at(9)).isEmpty)
        #expect(engine.snapshot == paused)
    }

    @Test func aPauseOrResumeAtAnEarlierTimeIsIgnored() {
        var engine = box()
        engine.advance(to: at(10))
        #expect(engine.pause(at: at(8)).isEmpty)
        #expect(engine.snapshot.state == .breathing)
        engine.pause(at: at(10))
        engine.resume(at: at(9))
        #expect(engine.snapshot.state == .paused)
    }

    @Test func aPauseAtOrAfterTheEndLeavesTheSessionCompleted() {
        var engine = box()
        #expect(engine.pause(at: at(3 + 70)).last == .completed)
        #expect(engine.snapshot.state == .completed)
        engine.resume(at: at(3 + 80))
        #expect(engine.snapshot.state == .completed)
    }
}
