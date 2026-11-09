/// One haptic event as plain values, which the app turns into a Core Haptics event (ADR 0001).
public struct HapticEvent: Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        /// A buzz that lasts `duration` and follows `intensityCurve`.
        case continuous
        /// A single tick.
        case transient
    }

    /// One control point of a continuous event's intensity.
    public struct IntensityPoint: Sendable, Hashable {
        /// From the start of the Phase.
        public let time: Duration
        public let value: Double
    }

    public let kind: Kind
    /// When the event starts, from the start of the Phase.
    public let time: Duration
    /// How long a continuous event lasts; zero for a transient one.
    public let duration: Duration
    /// The intensity at `time`, from 0 to 1.
    public let intensity: Double
    public let sharpness: Double
    /// Where the intensity goes during a continuous event, from its start to its end; empty for a transient one.
    public let intensityCurve: [IntensityPoint]
}

public extension Pattern {
    /// The Haptic plan: what the start of the Phase at `phaseIndex` of this Pattern asks the phone to play.
    ///
    /// Inhale and exhale are one continuous event whose intensity follows the Breath level curve, so haptic
    /// and shape stay in step: inhale rises from 0.35 to 1, exhale falls from 1 to 0.65. A run of inhales is
    /// one curve, so a double inhale rises once. Hold and rest tick at the start and at every whole second
    /// after it. The Lead-in and completion play nothing, and neither does an index outside the Pattern.
    func hapticEvents(for transition: SessionEngine.Transition, phaseIndex: Int) -> [HapticEvent] {
        guard case .phaseStarted = transition, phases.indices.contains(phaseIndex) else { return [] }
        let phase = phases[phaseIndex]
        switch phase.kind {
        case .inhale:
            return [continuousEvent(for: phaseIndex, sharpness: 0.7) { 0.35 + 0.65 * $0 }]
        case .exhale:
            return [continuousEvent(for: phaseIndex, sharpness: 0.25) { 0.65 + 0.35 * $0 }]
        case .hold, .rest:
            let ticks = Int(phase.duration.components.seconds) + (phase.duration.components.attoseconds > 0 ? 1 : 0)
            return (0 ..< ticks).map {
                HapticEvent(
                    kind: .transient,
                    time: .seconds($0),
                    duration: .zero,
                    intensity: 1,
                    sharpness: 1,
                    intensityCurve: []
                )
            }
        }
    }
}

private extension Pattern {
    /// Steps between control points of a continuous event.
    static var curveStep: Duration { .milliseconds(100) }

    func continuousEvent(
        for phaseIndex: Int, sharpness: Double, intensity: (Double) -> Double
    ) -> HapticEvent {
        let start = phases[..<phaseIndex].reduce(Duration.zero) { $0 + $1.duration }
        let length = phases[phaseIndex].duration
        var points: [HapticEvent.IntensityPoint] = []
        var time = Duration.zero
        while time < length {
            points.append(point(at: time, from: start, intensity))
            time += Self.curveStep
        }
        points.append(point(at: length, from: start, intensity))
        return HapticEvent(
            kind: .continuous, time: .zero, duration: length,
            intensity: points[0].value, sharpness: sharpness, intensityCurve: points
        )
    }

    func point(at time: Duration, from start: Duration, _ intensity: (Double) -> Double) -> HapticEvent.IntensityPoint {
        HapticEvent.IntensityPoint(time: time, value: intensity(breathLevel(at: start + time)))
    }
}
