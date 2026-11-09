import BreathnestKit
import CoreHaptics
import os

/// Turns the Kit's `HapticEvent`s into Core Haptics values. Pure, so a test can read what the phone is asked to
/// play without an engine.
enum HapticMapping {
    static func events(for events: [HapticEvent]) -> [CHHapticEvent] {
        events.map { event in
            // A continuous event gets its loudness from the intensity curve, a multiplier, so its own intensity is 1.
            let intensity = event.intensityCurve.isEmpty ? event.intensity : 1
            return CHHapticEvent(
                eventType: event.kind == .continuous ? .hapticContinuous : .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(event.sharpness)),
                ],
                relativeTime: seconds(event.time),
                duration: seconds(event.duration)
            )
        }
    }

    static func curves(for events: [HapticEvent]) -> [CHHapticParameterCurve] {
        events.filter { !$0.intensityCurve.isEmpty }.map { event in
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: event.intensityCurve.map {
                    CHHapticParameterCurve.ControlPoint(relativeTime: seconds($0.time), value: Float($0.value))
                },
                relativeTime: seconds(event.time)
            )
        }
    }

    static func seconds(_ duration: Duration) -> TimeInterval {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }
}

/// Plays the Haptic plan through Core Haptics. Does nothing where the device has no haptic engine (the
/// Simulator), and a failure to play never reaches the Session: haptics are an extra, not part of it.
///
/// The system can stop the engine (an interruption, a media reset). The next Phase's `play` starts it again, or
/// builds a new one after a reset, so the Session recovers without being told.
@MainActor
final class CoreHapticsPlayer: HapticPlayer {
    private let supportsHaptics: Bool
    private var engine: CHHapticEngine?
    private var player: (any CHHapticAdvancedPatternPlayer)?
    private let log = Logger(subsystem: "com.siroroman.breathnest", category: "haptics")

    init(supportsHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics) {
        self.supportsHaptics = supportsHaptics
    }

    func play(_ events: [HapticEvent]) {
        guard supportsHaptics, !events.isEmpty else { return }
        do {
            let engine = try startedEngine()
            try? player?.stop(atTime: CHHapticTimeImmediate)
            let pattern = try CHHapticPattern(
                events: HapticMapping.events(for: events), parameterCurves: HapticMapping.curves(for: events)
            )
            let next = try engine.makeAdvancedPlayer(with: pattern)
            try next.start(atTime: CHHapticTimeImmediate)
            player = next
        } catch {
            log.error("Could not play a haptic: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        engine?.stop()
    }

    /// The engine, started. Starting one that already runs does nothing, so a stop by the system needs no check.
    private func startedEngine() throws -> CHHapticEngine {
        let engine = try engine ?? makeEngine()
        try engine.start()
        self.engine = engine
        return engine
    }

    private func makeEngine() throws -> CHHapticEngine {
        let engine = try CHHapticEngine()
        // Both arrive off the main thread. A stopped engine is started by the next `play`; after a reset the
        // engine and its players are gone, so the next `play` builds new ones.
        engine.stoppedHandler = { [weak self] _ in
            Task { @MainActor in self?.player = nil }
        }
        engine.resetHandler = { [weak self] in
            Task { @MainActor in
                self?.player = nil
                self?.engine = nil
            }
        }
        return engine
    }
}
