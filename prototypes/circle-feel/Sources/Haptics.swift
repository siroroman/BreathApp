// PROTOTYPE (issue #13). Core Haptics player: one pattern per Phase, started when the Phase starts.
import CoreHaptics

@MainActor
final class Haptics {
    let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private(set) var status = "idle"
    private var engine: CHHapticEngine?
    private var players: [CHHapticPatternPlayer] = []

    func start() {
        guard supported, engine == nil else { return }
        do {
            let e = try CHHapticEngine()
            e.playsHapticsOnly = true
            e.isAutoShutdownEnabled = false
            e.stoppedHandler = { reason in print("haptic engine stopped: \(reason.rawValue)") }
            e.resetHandler = { [weak self] in
                Task { @MainActor in try? self?.engine?.start() }
            }
            try e.start()
            engine = e
            status = "engine running"
        } catch {
            status = "engine failed: \(error)"
        }
    }

    func stop() {
        players.forEach { try? $0.stop(atTime: CHHapticTimeImmediate) }
        players = []
        engine?.stop()
        engine = nil
        status = "idle"
    }

    /// `level` maps seconds-within-the-span to the circle level 0...1.
    func play(_ span: Span, config: HapticConfig, level: (Double) -> Double) {
        guard supported, let engine else { return }
        let style = config.style(for: span.kind)
        let s = Float(config.strength)
        let d = span.seconds
        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []

        func transient(_ t: Double, _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: min(max(intensity, 0), 1)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ], relativeTime: t)
        }
        func continuous(_ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: min(max(intensity, 0), 1)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ], relativeTime: 0, duration: min(d, 30))
        }

        switch style {
        case .off:
            return
        case .tap:
            let sharp: Float = switch span.kind {
            case .inhale: 0.35
            case .hold: 0.9
            case .exhale: 0.15
            case .rest: 0.1
            }
            events.append(transient(0, s, sharp))
        case .seconds:
            var t = 0.0
            while t < d - 0.05 { events.append(transient(t, s * 0.6, 0.7)); t += 1 }
        case .ramp:
            let dur = min(d, 30), n = 12
            events.append(continuous(s, 0.2))
            let points = (0...n).map { i -> CHHapticParameterCurve.ControlPoint in
                let rel = dur * Double(i) / Double(n)
                return .init(relativeTime: rel, value: Float(0.12 + 0.88 * level(rel)))
            }
            curves.append(CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                                 controlPoints: points, relativeTime: 0))
        case .pulses:
            var t = 0.0
            while t < d - 0.05 {
                events.append(transient(t, s * Float(0.15 + 0.85 * level(t)), 0.35))
                t += config.pulseEvery
            }
        case .hum:
            events.append(continuous(s * 0.35, 0.1))
        }

        do {
            try engine.start()
            let player = try engine.makePlayer(with: CHHapticPattern(events: events, parameterCurves: curves))
            try player.start(atTime: CHHapticTimeImmediate)
            players.append(player)
            if players.count > 4 { players.removeFirst() }
        } catch {
            status = "play failed: \(error)"
        }
    }
}
