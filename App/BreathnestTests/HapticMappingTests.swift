import BreathnestKit
import CoreHaptics
import Testing

@testable import Breathnest

@MainActor @Suite struct HapticMappingTests {
    /// What the Kit's Haptic plan asks for at the start of the box Phase at `index`.
    private func plan(_ index: Int) -> [HapticEvent] {
        let pattern = Exercise.box.pattern
        return pattern.hapticEvents(for: .phaseStarted(pattern.phases[index].kind), phaseIndex: index)
    }

    @Test func aContinuousEventMapsToAContinuousHapticWithItsDuration() throws {
        let inhale = plan(0)
        let events = HapticMapping.events(for: inhale)
        let event = try #require(events.first)
        #expect(events.count == 1)
        #expect(event.type == .hapticContinuous)
        #expect(event.relativeTime == 0)
        #expect(event.duration == HapticMapping.seconds(inhale[0].duration))
    }

    @Test func aContinuousEventTakesItsLoudnessFromTheCurve() throws {
        let inhale = plan(0)
        let curves = HapticMapping.curves(for: inhale)
        let curve = try #require(curves.first)
        #expect(curve.parameterID == .hapticIntensityControl)
        #expect(curve.controlPoints.first?.value == inhale[0].intensityCurve.first.map { Float($0.value) })
        let event = try #require(HapticMapping.events(for: inhale).first)
        let intensity = event.eventParameters.first { $0.parameterID == .hapticIntensity }
        #expect(intensity?.value == 1)
    }

    @Test func aLongCurveIsChainedFromCurvesOfAtMostSixteenPoints() throws {
        let inhale = plan(0)
        let source = inhale[0].intensityCurve
        #expect(source.count > HapticMapping.maxCurvePoints)
        let curves = HapticMapping.curves(for: inhale)
        #expect(curves.count > 1)
        #expect(curves.allSatisfy { $0.controlPoints.count <= HapticMapping.maxCurvePoints })
        // Each curve starts where the one before it ended, and together they end where the source ends.
        for (before, after) in zip(curves, curves.dropFirst()) {
            #expect(after.relativeTime == before.relativeTime + (before.controlPoints.last?.relativeTime ?? -1))
            #expect(after.controlPoints.first?.value == before.controlPoints.last?.value)
        }
        let last = try #require(curves.last)
        let end = last.relativeTime + (last.controlPoints.last?.relativeTime ?? -1)
        #expect(abs(end - HapticMapping.seconds(try #require(source.last).time)) < 1e-9)
        #expect(last.controlPoints.last?.value == source.last.map { Float($0.value) })
    }

    @Test func aTransientEventMapsToATransientHapticAtItsTime() throws {
        let hold = plan(1)
        let events = HapticMapping.events(for: hold)
        #expect(events.count == hold.count)
        #expect(events.allSatisfy { $0.type == .hapticTransient })
        #expect(events.map(\.relativeTime) == hold.map { HapticMapping.seconds($0.time) })
        #expect(HapticMapping.curves(for: hold).isEmpty)
    }

    @Test func secondsConvertsWholeAndFractionalDurations() {
        #expect(HapticMapping.seconds(.seconds(3)) == 3)
        #expect(HapticMapping.seconds(.milliseconds(1500)) == 1.5)
        #expect(HapticMapping.seconds(.zero) == 0)
    }

    @Test func withoutHardwareSupportPlayingAndStoppingDoNothing() {
        let player = CoreHapticsPlayer(supportsHaptics: false)
        player.play(plan(0))
        player.stop()
    }

    @Test func theEngineIsStartedForEveryPlayAndBuiltAgainAfterAReset() {
        let engines = FakeEngines()
        let player = CoreHapticsPlayer(supportsHaptics: true, makeEngine: engines.make)
        player.play(plan(0))
        player.play(plan(1))
        #expect(engines.made.count == 1)
        #expect(engines.made[0].played == 2)

        player.stop()
        player.play(plan(0))
        #expect(engines.made[0].stops == 1)
        #expect(engines.made[0].played == 3)

        engines.reset()
        player.play(plan(0))
        #expect(engines.made.count == 2)
        #expect(engines.made[1].played == 1)
    }

    @Test func aFailingEngineNeverReachesTheCaller() {
        let engines = FakeEngines()
        engines.fails = true
        let player = CoreHapticsPlayer(supportsHaptics: true, makeEngine: engines.make)
        player.play(plan(0))
        engines.fails = false
        player.play(plan(0))
        #expect(engines.made.count == 1)
    }
}

@MainActor private final class FakeEngine: HapticEngineDriving {
    var played = 0
    var stops = 0
    func play(_ pattern: CHHapticPattern) throws { played += 1 }
    func stop() { stops += 1 }
}

@MainActor private final class FakeEngines {
    struct Failure: Error {}
    var made: [FakeEngine] = []
    var fails = false
    private var onReset: (@MainActor () -> Void)?

    func make(onReset: @escaping @MainActor () -> Void) throws -> any HapticEngineDriving {
        if fails { throw Failure() }
        self.onReset = onReset
        let engine = FakeEngine()
        made.append(engine)
        return engine
    }

    func reset() { onReset?() }
}
