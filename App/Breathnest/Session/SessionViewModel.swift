import BreathnestKit
import Observation

/// The state of one running Session: owns the engine, feeds it the time and releases the screen. Holds no text
/// (ADR 0002). The ticker task is started by `run(ticker:)` and cancelled when the Session ends.
@MainActor
@Observable
final class SessionViewModel {
    enum Stage: Hashable {
        case leadIn, breathing, completed, stopped
    }

    let exercise: Exercise
    private(set) var snapshot: SessionEngine.Snapshot

    @ObservationIgnored private var engine: SessionEngine
    @ObservationIgnored private let screenAwake: any ScreenAwake
    @ObservationIgnored private let speed: Double
    @ObservationIgnored private let origin: ContinuousClock.Instant
    @ObservationIgnored private var task: Task<Void, Never>?

    /// `speed` scales the time fed to the engine; the app passes 1 except for the DEBUG launch argument.
    init(
        exercise: Exercise, requested: Duration, screenAwake: any ScreenAwake, speed: Double = 1,
        startedAt: ContinuousClock.Instant
    ) {
        self.exercise = exercise
        self.screenAwake = screenAwake
        self.speed = speed
        self.requested = requested
        origin = startedAt
        engine = SessionEngine(exercise: exercise, requested: requested, startingAt: startedAt)
        snapshot = engine.snapshot
    }

    var stage: Stage {
        switch snapshot.state {
        case .leadIn: .leadIn
        case .breathing: .breathing
        case .completed: .completed
        case .stopped: .stopped
        case .paused: snapshot.phase == nil && snapshot.leadInLeft > .zero ? .leadIn : .breathing
        }
    }

    var isPaused: Bool { snapshot.state == .paused }
    var phaseKind: PhaseKind? { snapshot.phase?.kind }
    var timeLeft: Duration { snapshot.timeLeft }
    var cycleCount: Int { snapshot.cycleCount }
    var sessionLength: SessionLength { exercise.sessionLength(for: requested) }
    var totalLength: Duration { sessionLength.totalLength }
    @ObservationIgnored private let requested: Duration

    /// The Lead-in time left rounded up: 3, 2, 1.
    var leadInDigit: Int {
        let seconds = snapshot.leadInLeft / .seconds(1)
        return Int(seconds.rounded(.up))
    }

    /// Keeps the screen on from Start.
    func begin() {
        screenAwake.setAwake(true)
    }

    /// Reads the ticker until the Session ends or the task is cancelled.
    func run(ticker: any Ticker) {
        task?.cancel()
        task = Task { [weak self] in
            for await instant in ticker.ticks() {
                guard let self, !Task.isCancelled else { return }
                tick(now: instant)
            }
        }
    }

    func tick(now: ContinuousClock.Instant) {
        engine.advance(to: fed(now))
        refresh()
    }

    func pause(now: ContinuousClock.Instant) {
        engine.pause(at: fed(now))
        refresh()
    }

    func resume(now: ContinuousClock.Instant) {
        engine.resume(at: fed(now))
        refresh()
    }

    /// The scene is no longer active (call, lock, Control Center, app switch): the Session pauses.
    func sceneBecameInactive(now: ContinuousClock.Instant) {
        pause(now: now)
    }

    func stop(now: ContinuousClock.Instant) {
        engine.stop(at: fed(now))
        refresh()
    }

    /// Releases the screen and the ticker, for when the cover goes away by any path.
    func end() {
        task?.cancel()
        task = nil
        screenAwake.setAwake(false)
    }

    private func fed(_ now: ContinuousClock.Instant) -> ContinuousClock.Instant {
        speed == 1 ? now : origin.advanced(by: (now - origin) * speed)
    }

    private func refresh() {
        snapshot = engine.snapshot
        if stage == .completed || stage == .stopped { end() }
    }
}

extension SessionViewModel: Identifiable {
    nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
}
