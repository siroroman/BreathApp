/// Which tone a sound cue plays: the chosen sound has one version per cue (#210).
public enum SoundCue: String, Sendable, CaseIterable {
    /// The start of an inhale: the higher tone.
    case inhale
    /// The start of an exhale: the lower tone.
    case exhale
    /// One tick of a hold, played with the haptic tick.
    case tick
}

/// One sound the phone plays during a Phase.
public struct SoundEvent: Sendable, Hashable {
    public let cue: SoundCue
    /// When it plays, from the start of the Phase.
    public let time: Duration

    public init(cue: SoundCue, time: Duration) {
        self.cue = cue
        self.time = time
    }

    /// The same event played `speed` times faster, for the DEBUG speed, so the sounds stay with their haptics.
    public func sped(by speed: Double) -> SoundEvent {
        speed == 1 ? self : SoundEvent(cue: cue, time: time / speed)
    }
}

public extension Pattern {
    /// The Sound plan: what the start of the Phase at `phaseIndex` of this Pattern asks the phone to play. An inhale
    /// and an exhale are one tone at the start. A hold ticks exactly where the Haptic plan ticks, so the sound and
    /// the haptic stay together by construction. A rest, the Lead-in and completion have no sound, and neither has
    /// an index outside the Pattern.
    func soundEvents(for transition: SessionEngine.Transition, phaseIndex: Int) -> [SoundEvent] {
        guard case let .phaseStarted(kind) = transition, phases.indices.contains(phaseIndex) else { return [] }
        switch kind {
        case .inhale: return [SoundEvent(cue: .inhale, time: .zero)]
        case .exhale: return [SoundEvent(cue: .exhale, time: .zero)]
        case .hold:
            return hapticEvents(for: transition, phaseIndex: phaseIndex).map { SoundEvent(cue: .tick, time: $0.time) }
        case .rest: return []
        }
    }
}
