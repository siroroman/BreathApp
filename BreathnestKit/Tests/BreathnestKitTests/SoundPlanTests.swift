import Testing

@testable import BreathnestKit

@Suite struct SoundPlanTests {
    private let box = Exercise.box.pattern

    @Test func inhaleIsOneInhaleToneAtTheStart() {
        #expect(box.soundEvents(for: .phaseStarted(.inhale), phaseIndex: 0) == [SoundEvent(cue: .inhale, time: .zero)])
    }

    @Test func exhaleIsOneExhaleToneAtTheStart() {
        #expect(box.soundEvents(for: .phaseStarted(.exhale), phaseIndex: 2) == [SoundEvent(cue: .exhale, time: .zero)])
    }

    @Test func aHoldTicksAtTheTimesOfItsHapticTicks() {
        let haptics = box.hapticEvents(for: .phaseStarted(.hold), phaseIndex: 1)
        let events = box.soundEvents(for: .phaseStarted(.hold), phaseIndex: 1)
        #expect(events.count == 4)
        #expect(events.map(\.cue) == Array(repeating: .tick, count: 4))
        #expect(events.map(\.time) == haptics.map(\.time))
        #expect(events.map(\.time) == [.zero, .seconds(1), .seconds(2), .seconds(3)])
    }

    @Test func aRestHasNoSound() {
        let pattern = Pattern(validated: [
            Phase(kind: .inhale, duration: .seconds(4)), Phase(kind: .rest, duration: .seconds(2)),
        ])
        #expect(pattern.soundEvents(for: .phaseStarted(.rest), phaseIndex: 1).isEmpty)
    }

    @Test func theLeadInCompletionAndAnIndexOutsideThePatternHaveNoSound() {
        #expect(box.soundEvents(for: .leadInEnded, phaseIndex: 0).isEmpty)
        #expect(box.soundEvents(for: .completed, phaseIndex: 0).isEmpty)
        #expect(box.soundEvents(for: .phaseStarted(.inhale), phaseIndex: 9).isEmpty)
    }

    @Test func spedByDividesTheTime() {
        let event = SoundEvent(cue: .tick, time: .seconds(2))
        #expect(event.sped(by: 4).time == .milliseconds(500))
        #expect(event.sped(by: 1) == event)
    }
}
