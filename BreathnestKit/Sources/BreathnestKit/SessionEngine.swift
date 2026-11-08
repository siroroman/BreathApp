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

    public struct Snapshot: Sendable, Hashable {
        public let state: State
        public let phase: Phase?
        public let leadInLeft: Duration
        public let timeLeft: Duration
        public let cycle: Int
        public let cycleCount: Int
        public let breathLevel: Double
    }

    /// The Lead-in is the same for every Exercise and does not count toward the Session's length.
    public static let leadInLength: Duration = .seconds(3)

    private let sessionLength: SessionLength
    private var state: State = .leadIn
    private var lastSeen: ContinuousClock.Instant
    private var leadInLeft = leadInLength

    /// Starts in the Lead-in at `start`. The length is the whole number of Cycles nearest to `requested`.
    public init(exercise: Exercise, requested: Duration, startingAt start: ContinuousClock.Instant) {
        sessionLength = exercise.sessionLength(for: requested)
        lastSeen = start
    }

    public var snapshot: Snapshot {
        Snapshot(
            state: state,
            phase: nil,
            leadInLeft: leadInLeft,
            timeLeft: sessionLength.totalLength,
            cycle: 1,
            cycleCount: sessionLength.cycleCount,
            breathLevel: 0
        )
    }

    /// Moves time forward to `now` and returns the transitions it crossed, in order.
    @discardableResult
    public mutating func advance(to now: ContinuousClock.Instant) -> [Transition] {
        let delta = now - lastSeen
        lastSeen = now
        guard delta >= leadInLeft else {
            leadInLeft -= delta
            return []
        }
        leadInLeft = .zero
        state = .breathing
        return [.leadInEnded, .phaseStarted(.inhale)]
    }
}
