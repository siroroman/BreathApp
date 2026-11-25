import BreathnestKit
import CoreHaptics
import os

/// Turns the Kit's `HapticEvent`s into Core Haptics values. Pure, so a test can read what the phone is asked to
/// play without an engine.
enum HapticMapping {
    /// Core Haptics accepts at most 16 control points in one parameter curve.
    static let maxCurvePoints = 16

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

    /// One curve per run of at most `maxCurvePoints` points. A run starts at the last point of the one before it,
    /// so the chain follows the whole intensity curve of the event.
    static func curves(for events: [HapticEvent]) -> [CHHapticParameterCurve] {
        events.flatMap { event -> [CHHapticParameterCurve] in
            let source = event.intensityCurve
            guard source.count > 1 else { return [] }
            return stride(from: 0, to: source.count - 1, by: maxCurvePoints - 1).map { start in
                let run = source[start ..< min(start + maxCurvePoints, source.count)]
                let origin = seconds(run[start].time)
                let points = run.map {
                    CHHapticParameterCurve.ControlPoint(
                        relativeTime: seconds($0.time) - origin, value: Float($0.value)
                    )
                }
                return CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: points,
                    relativeTime: origin
                )
            }
        }
    }

    static func seconds(_ duration: Duration) -> TimeInterval {
        Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
    }
}

/// The part of Core Haptics the player needs, so a test can stand in for the engine, which the Simulator does
/// not have.
@MainActor
protocol HapticEngineDriving: AnyObject {
    /// Starts the engine (it does nothing when it runs) and plays `pattern` from the start, replacing the one playing.
    func play(_ pattern: CHHapticPattern) throws
    func stop()
}

/// Counts the players an engine has had, so a stop that arrives late can tell whether it is still about the
/// current one. The engine reports a stop off the main thread and the main actor hears of it later: a new
/// player may have started in between, and that stop must not clear it.
final class PlayerGeneration: Sendable {
    private let value = OSAllocatedUnfairLock(initialState: 0)

    var current: Int { value.withLock { $0 } }

    func advance() { value.withLock { $0 += 1 } }

    func isCurrent(_ generation: Int) -> Bool { current == generation }
}

/// The real engine. The system stopping it needs nothing here: every `play` starts it again.
@MainActor
final class SystemHapticEngine: HapticEngineDriving {
    private let engine: CHHapticEngine
    private var player: (any CHHapticAdvancedPatternPlayer)?
    private let generation = PlayerGeneration()

    /// `onReset` runs when the system reset the engine: it and its players are gone and a new one is needed.
    init(onReset: @escaping @MainActor () -> Void) throws {
        engine = try CHHapticEngine()
        let generation = generation
        // Both arrive off the main thread.
        engine.stoppedHandler = { [weak self] _ in
            // Read now, off the main thread: a `play` before the Task runs makes this stop a late one.
            let stopped = generation.current
            Task { @MainActor in
                guard let self, generation.isCurrent(stopped) else { return }
                self.player = nil
            }
        }
        engine.resetHandler = {
            Task { @MainActor in onReset() }
        }
    }

    func play(_ pattern: CHHapticPattern) throws {
        try engine.start()
        try? player?.stop(atTime: CHHapticTimeImmediate)
        let next = try engine.makeAdvancedPlayer(with: pattern)
        try next.start(atTime: CHHapticTimeImmediate)
        generation.advance()
        player = next
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        generation.advance()
        player = nil
        engine.stop()
    }
}

/// Plays the Haptic plan through Core Haptics. Does nothing where the device has no haptic engine (the
/// Simulator), and a failure to play never reaches the Session: haptics are an extra, not part of it.
///
/// The system can stop the engine (an interruption, a media reset). The next Phase's `play` starts it again, or
/// builds a new one after a reset, so the Session recovers without being told.
@MainActor
final class CoreHapticsPlayer: HapticPlayer {
    typealias EngineFactory = @MainActor (_ onReset: @escaping @MainActor () -> Void) throws -> any HapticEngineDriving

    private let supportsHaptics: Bool
    private let makeEngine: EngineFactory
    private var engine: (any HapticEngineDriving)?
    private let log = Logger(subsystem: "com.siroroman.breathnest", category: "haptics")

    init(
        supportsHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics,
        makeEngine: @escaping EngineFactory = { try SystemHapticEngine(onReset: $0) }
    ) {
        self.supportsHaptics = supportsHaptics
        self.makeEngine = makeEngine
    }

    func play(_ events: [HapticEvent]) {
        guard supportsHaptics, !events.isEmpty else { return }
        do {
            let pattern = try CHHapticPattern(
                events: HapticMapping.events(for: events), parameterCurves: HapticMapping.curves(for: events)
            )
            try currentEngine().play(pattern)
        } catch {
            log.error("Could not play a haptic: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() {
        engine?.stop()
    }

    private func currentEngine() throws -> any HapticEngineDriving {
        if let engine { return engine }
        let made = try makeEngine { [weak self] in self?.engine = nil }
        engine = made
        return made
    }
}
