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
        #expect(curve.controlPoints.count == inhale[0].intensityCurve.count)
        #expect(curve.controlPoints.first?.value == inhale[0].intensityCurve.first.map { Float($0.value) })
        let event = try #require(HapticMapping.events(for: inhale).first)
        let intensity = event.eventParameters.first { $0.parameterID == .hapticIntensity }
        #expect(intensity?.value == 1)
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
}
