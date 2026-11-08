/// The state of one Session, advanced by the times the app passes in.
///
/// A pure value: no timer, no task, no clock object. The app reads its clock, hands the reading in as
/// a `ContinuousClock.Instant` and gets back the transitions that time crossed.
public struct SessionEngine: Sendable {
    public enum State: Sendable, Hashable {
        case leadIn
        case breathing
        case paused
        case completed
        case stopped
    }

    public enum Transition: Sendable, Hashable {
        case phaseStarted(PhaseKind)
        case leadInEnded
        case completed
    }

    /// Everything a screen needs after an update. In the Lead-in there is no Phase and the Breath level is 0.
    public struct Snapshot: Sendable, Hashable {
        public let state: State
        /// The Phase the Session is in; `nil` in the Lead-in and once the Session has completed.
        public let phase: Phase?
        /// How far through `phase` the Session is, from 0 to 1.
        public let fractionOfPhase: Double
        /// Whole seconds left in `phase`, rounded up so a countdown never shows 0 while the Phase runs.
        public let secondsLeftInPhase: Int
        public let leadInLeft: Duration
        /// The time left in the whole Session, the Lead-in not counted.
        public let timeLeft: Duration
        /// The number of the current Cycle, counted from 1, out of `cycleCount`.
        public let cycle: Int
        public let cycleCount: Int
        public let breathLevel: Double
    }

    /// The Lead-in is the same for every Exercise and does not count toward the Session's length.
    public static let leadInLength: Duration = .seconds(3)

    private let pattern: Pattern
    private let sessionLength: SessionLength
    private var state: State = .leadIn
    private var lastSeen: ContinuousClock.Instant
    private var leadInLeft = leadInLength
    /// Time spent breathing so far; the Lead-in and any pause are not in it.
    private var breathed: Duration = .zero

    /// Starts in the Lead-in at `start`. The length is the whole number of Cycles nearest to `requested`.
    public init(exercise: Exercise, requested: Duration, startingAt start: ContinuousClock.Instant) {
        pattern = exercise.pattern
        sessionLength = exercise.sessionLength(for: requested)
        lastSeen = start
    }

    public var snapshot: Snapshot {
        if state == .completed {
            return Snapshot(
                state: state, phase: nil, fractionOfPhase: 1, secondsLeftInPhase: 0, leadInLeft: .zero,
                timeLeft: .zero, cycle: sessionLength.cycleCount, cycleCount: sessionLength.cycleCount,
                breathLevel: 0
            )
        }
        guard leadInLeft == .zero else {
            return Snapshot(
                state: state, phase: nil, fractionOfPhase: 0, secondsLeftInPhase: 0, leadInLeft: leadInLeft,
                timeLeft: sessionLength.totalLength, cycle: 1, cycleCount: sessionLength.cycleCount,
                breathLevel: 0
            )
        }
        let position = position(at: breathed)
        let phase = pattern.phases[position.phaseIndex]
        return Snapshot(
            state: state,
            phase: phase,
            fractionOfPhase: position.intoPhase / phase.duration,
            secondsLeftInPhase: (phase.duration - position.intoPhase).wholeSecondsRoundedUp,
            leadInLeft: .zero,
            timeLeft: sessionLength.totalLength - breathed,
            cycle: position.cycleIndex + 1,
            cycleCount: sessionLength.cycleCount,
            breathLevel: pattern.breathLevel(at: position.intoCycle)
        )
    }

    /// Moves time forward to `now` and returns the transitions it crossed, in order.
    /// A time earlier than one already seen is ignored.
    @discardableResult
    public mutating func advance(to now: ContinuousClock.Instant) -> [Transition] {
        guard now >= lastSeen else { return [] }
        var delta = now - lastSeen
        lastSeen = now
        var transitions: [Transition] = []
        var lastStarted = -1
        switch state {
        case .leadIn:
            guard delta >= leadInLeft else {
                leadInLeft -= delta
                return []
            }
            delta -= leadInLeft
            leadInLeft = .zero
            state = .breathing
            transitions.append(.leadInEnded)
        case .breathing:
            lastStarted = phaseOrdinal(at: breathed)
        case .paused, .completed, .stopped:
            return []
        }
        breathed = min(breathed + delta, sessionLength.totalLength)
        let finished = breathed == sessionLength.totalLength
        let lastToStart = finished ? phaseTotal - 1 : phaseOrdinal(at: breathed)
        for ordinal in (lastStarted + 1) ..< (lastToStart + 1) {
            transitions.append(.phaseStarted(pattern.phases[ordinal % pattern.phases.count].kind))
        }
        if finished {
            state = .completed
            transitions.append(.completed)
        }
        return transitions
    }

    /// Counts the time up to `now`, then freezes the Session where it is. Returns what that time crossed.
    /// Ignored in a paused or final state, and for a time earlier than one already seen.
    @discardableResult
    public mutating func pause(at now: ContinuousClock.Instant) -> [Transition] {
        guard now >= lastSeen, state == .leadIn || state == .breathing else { return [] }
        let transitions = advance(to: now)
        if state != .completed { state = .paused }
        return transitions
    }

    /// Ends the Session at once, wherever it is, after counting the time up to `now`. That time can still
    /// complete the Session: a Session that was already over stays completed. A `now` earlier than one
    /// already seen stops it at the point it has reached. Returns what the counted time crossed.
    @discardableResult
    public mutating func stop(at now: ContinuousClock.Instant) -> [Transition] {
        guard state != .completed, state != .stopped else { return [] }
        let transitions = advance(to: now)
        if state != .completed { state = .stopped }
        return transitions
    }

    /// Continues from the point `pause(at:)` froze. The time spent paused is not counted.
    /// Ignored unless the Session is paused, and for a time earlier than one already seen.
    public mutating func resume(at now: ContinuousClock.Instant) {
        guard now >= lastSeen, state == .paused else { return }
        lastSeen = now
        state = leadInLeft == .zero ? .breathing : .leadIn
    }
}

private extension SessionEngine {
    /// How many Phases the whole Session has, counting every Cycle.
    var phaseTotal: Int {
        sessionLength.cycleCount * pattern.phases.count
    }

    /// The index, counted over every Cycle of the Session, of the Phase that `elapsed` breathing time falls in.
    func phaseOrdinal(at elapsed: Duration) -> Int {
        let position = position(at: elapsed)
        return position.cycleIndex * pattern.phases.count + position.phaseIndex
    }

    struct Position {
        let cycleIndex: Int
        let phaseIndex: Int
        let intoPhase: Duration
        let intoCycle: Duration
    }

    /// Where `elapsed` breathing time falls: which Cycle, which Phase, and how far into each.
    /// Whole attoseconds, so a Phase boundary is never missed by rounding.
    func position(at elapsed: Duration) -> Position {
        let cycleLength = pattern.cycleLength
        let cycleIndex = Int(elapsed.attoseconds / cycleLength.attoseconds)
        let intoCycle = elapsed - cycleLength * cycleIndex
        var phaseStart = Duration.zero
        for (index, phase) in pattern.phases.enumerated() {
            let phaseEnd = phaseStart + phase.duration
            if intoCycle < phaseEnd || index == pattern.phases.count - 1 {
                return Position(
                    cycleIndex: cycleIndex, phaseIndex: index, intoPhase: intoCycle - phaseStart,
                    intoCycle: intoCycle
                )
            }
            phaseStart = phaseEnd
        }
        preconditionFailure("A Pattern has at least one Phase")
    }
}

private extension Duration {
    var attoseconds: Int128 {
        Int128(components.seconds) * 1_000_000_000_000_000_000 + Int128(components.attoseconds)
    }

    var wholeSecondsRoundedUp: Int {
        let perSecond: Int128 = 1_000_000_000_000_000_000
        return Int((attoseconds + perSecond - 1) / perSecond)
    }
}
