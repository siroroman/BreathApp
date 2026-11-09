import Testing

@testable import BreathnestKit

@Suite struct HapticPlanTests {
    private let coherent = Exercise.coherent.pattern

    @Test func inhaleIsOneContinuousEventFromThirtyFiveToFullIntensity() throws {
        let events = coherent.hapticEvents(for: .phaseStarted(.inhale), phaseIndex: 0)
        let event = try #require(events.first)
        #expect(events.count == 1)
        #expect(event.kind == .continuous)
        #expect(event.time == .zero)
        #expect(event.duration == .seconds(5.5))
        #expect(event.sharpness == 0.7)
        #expect(event.intensity == 0.35)
        let last = try #require(event.intensityCurve.last)
        #expect(last.value == 1.0)
    }

    @Test func exhaleIsOneContinuousEventFromFullToSixtyFiveIntensity() throws {
        let events = coherent.hapticEvents(for: .phaseStarted(.exhale), phaseIndex: 1)
        let event = try #require(events.first)
        #expect(events.count == 1)
        #expect(event.kind == .continuous)
        #expect(event.duration == .seconds(5.5))
        #expect(event.sharpness == 0.25)
        #expect(event.intensity == 1.0)
        let last = try #require(event.intensityCurve.last)
        #expect(last.value == 0.65)
    }

    @Test func leadInEndedAndCompletedPlayNothing() {
        #expect(coherent.hapticEvents(for: .leadInEnded, phaseIndex: 0).isEmpty)
        #expect(coherent.hapticEvents(for: .completed, phaseIndex: 0).isEmpty)
    }

    @Test func aPhaseIndexOutsideThePatternPlaysNothing() {
        #expect(coherent.hapticEvents(for: .phaseStarted(.inhale), phaseIndex: 2).isEmpty)
        #expect(coherent.hapticEvents(for: .phaseStarted(.inhale), phaseIndex: -1).isEmpty)
    }

    @Test func intensityFollowsTheBreathLevelCurve() throws {
        let inhale = try #require(coherent.hapticEvents(for: .phaseStarted(.inhale), phaseIndex: 0).first)
        let exhale = try #require(coherent.hapticEvents(for: .phaseStarted(.exhale), phaseIndex: 1).first)
        for point in inhale.intensityCurve {
            let level = coherent.breathLevel(at: point.time)
            #expect(abs(point.value - (0.35 + 0.65 * level)) < 1e-9)
        }
        for point in exhale.intensityCurve {
            let level = coherent.breathLevel(at: .seconds(5.5) + point.time)
            #expect(abs(point.value - (0.65 + 0.35 * level)) < 1e-9)
        }
    }

    @Test func holdTicksAtTheStartAndEveryWholeSecondAfter() {
        let events = Exercise.box.pattern.hapticEvents(for: .phaseStarted(.hold), phaseIndex: 1)
        #expect(events.map(\.time) == [.zero, .seconds(1), .seconds(2), .seconds(3)])
        #expect(events.allSatisfy { $0.kind == .transient && $0.intensity == 1.0 && $0.sharpness == 1.0 })
        #expect(events.allSatisfy { $0.duration == .zero && $0.intensityCurve.isEmpty })
    }

    @Test func holdOfSevenSecondsTicksSevenTimes() {
        let events = Exercise.fourSevenEight.pattern.hapticEvents(for: .phaseStarted(.hold), phaseIndex: 1)
        #expect(events.count == 7)
    }

    @Test func aFractionalRestTicksOnlyOnWholeSeconds() throws {
        let pattern = try #require(Pattern(phases: [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .rest, duration: .seconds(2.5)),
        ]))
        let events = pattern.hapticEvents(for: .phaseStarted(.rest), phaseIndex: 1)
        #expect(events.map(\.time) == [.zero, .seconds(1), .seconds(2)])
        let short = try #require(Pattern(phases: [Phase(kind: .rest, duration: .seconds(0.5))]))
        #expect(short.hapticEvents(for: .phaseStarted(.rest), phaseIndex: 0).map(\.time) == [.zero])
    }

    @Test func doubleInhaleRisesOnceAcrossBothInhales() throws {
        let sigh = Exercise.physiologicalSigh.pattern
        let first = try #require(sigh.hapticEvents(for: .phaseStarted(.inhale), phaseIndex: 0).first)
        let second = try #require(sigh.hapticEvents(for: .phaseStarted(.inhale), phaseIndex: 1).first)
        let values = (first.intensityCurve + second.intensityCurve).map(\.value)
        #expect(first.intensity == 0.35)
        #expect(zip(values, values.dropFirst()).allSatisfy { $0 <= $1 })
        let firstEnd = try #require(first.intensityCurve.last)
        let secondEnd = try #require(second.intensityCurve.last)
        #expect(abs(second.intensity - firstEnd.value) < 1e-9)
        #expect(abs(secondEnd.value - 1.0) < 1e-9)
    }

    @Test func everyPhaseOfTheBoxPatternHasEventsInItsOwnPlace() {
        let box = Exercise.box.pattern
        let counts = box.phases.indices.map { index in
            box.hapticEvents(for: .phaseStarted(box.phases[index].kind), phaseIndex: index).count
        }
        #expect(counts == [1, 4, 1, 4])
    }
}
