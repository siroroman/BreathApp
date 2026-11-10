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
    @ObservationIgnored private let haptics: any HapticPlayer
    @ObservationIgnored private let isHapticsOn: Bool
    /// How many Phases have started, counted over every Cycle; the Pattern's Phase index is this modulo its length.
    @ObservationIgnored private var phasesStarted = 0
    @ObservationIgnored private let speed: Double
    @ObservationIgnored private let origin: ContinuousClock.Instant
    @ObservationIgnored private var task: Task<Void, Never>?

    /// `speed` scales the time fed to the engine; the app passes 1 except for the DEBUG launch argument.
    init(
        exercise: Exercise, requested: Duration, screenAwake: any ScreenAwake, haptics: any HapticPlayer,
        isHapticsOn: Bool, speed: Double = 1, startedAt: ContinuousClock.Instant
    ) {
        self.exercise = exercise
        self.screenAwake = screenAwake
        self.haptics = haptics
        self.isHapticsOn = isHapticsOn
        self.speed = speed
        self.requested = requested
        ring = ProgressRing(pattern: exercise.pattern)
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
    /// 0 (empty) to 1 (full) for the torus; 0 in the Lead-in and after the end.
    var breathLevel: Double { snapshot.breathLevel }
    var cycleCount: Int { snapshot.cycleCount }
    /// The ring of the Exercise's Pattern, laid out once.
    let ring: ProgressRing
    /// What is lit on `ring`; nothing in the Lead-in.
    var ringFills: [ProgressRing.ArcFill] {
        ring.fills(phaseIndex: snapshot.phaseIndex, fractionOfPhase: snapshot.fractionOfPhase)
    }

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
        handle(engine.advance(to: fed(now)))
        refresh()
    }

    func pause(now: ContinuousClock.Instant) {
        handle(engine.pause(at: fed(now)), plays: false)
        haptics.stop()
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
        handle(engine.stop(at: fed(now)), plays: false)
        refresh()
    }

    /// Releases the screen and the ticker, for when the cover goes away by any path.
    func end() {
        task?.cancel()
        task = nil
        haptics.stop()
        screenAwake.setAwake(false)
    }

    private func fed(_ now: ContinuousClock.Instant) -> ContinuousClock.Instant {
        speed == 1 ? now : origin.advanced(by: (now - origin) * speed)
    }

    /// Plays the haptic of each Phase the time crossed, once, at its start. Every Phase is counted, but a batch
    /// that pauses, stops or completes the Session plays none: the haptic would be cut at once.
    private func handle(_ transitions: [SessionEngine.Transition], plays: Bool = true) {
        let pattern = exercise.pattern
        let isPlaying = plays && isHapticsOn && !transitions.contains(.completed)
        for transition in transitions {
            guard case .phaseStarted = transition else { continue }
            defer { phasesStarted += 1 }
            guard isPlaying else { continue }
            haptics.play(pattern.hapticEvents(for: transition, phaseIndex: phasesStarted % pattern.phases.count))
        }
    }

    private func refresh() {
        snapshot = engine.snapshot
        if stage == .completed || stage == .stopped { end() }
    }
}

extension SessionViewModel: Identifiable {
    nonisolated var id: ObjectIdentifier { ObjectIdentifier(self) }
}
