import Foundation
import Testing

@testable import BreathnestKit

@Suite struct CustomExerciseTests {
    private func record(_ inhale: Int, _ hold1: Int, _ exhale: Int, _ hold2: Int) -> CustomExerciseRecord? {
        CustomExerciseRecord(
            name: "Evening calm", icon: .moon, description: "Wind-down",
            inhale: inhale, holdAfterInhale: hold1, exhale: exhale, holdAfterExhale: hold2
        )
    }

    @Test func twoHoldsGiveFourPhases() throws {
        let exercise = try #require(record(4, 2, 6, 1)).exercise
        #expect(exercise.pattern.phases == [
            Phase(kind: .inhale, duration: .seconds(4)),
            Phase(kind: .hold, duration: .seconds(2)),
            Phase(kind: .exhale, duration: .seconds(6)),
            Phase(kind: .hold, duration: .seconds(1)),
        ])
    }

    @Test func oneHoldLeavesTheOtherPhaseOut() throws {
        let afterInhale = try #require(record(4, 7, 8, 0)).exercise
        #expect(afterInhale.pattern.phases.map(\.kind) == [.inhale, .hold, .exhale])
        let afterExhale = try #require(record(4, 0, 6, 3)).exercise
        #expect(afterExhale.pattern.phases.map(\.kind) == [.inhale, .exhale, .hold])
    }

    @Test func noHoldIsInhaleAndExhale() throws {
        let exercise = try #require(record(5, 0, 5, 0)).exercise
        #expect(exercise.pattern.phases.map(\.kind) == [.inhale, .exhale])
        #expect(exercise.pattern.cycleLength == .seconds(10))
    }

    @Test func inhaleAndExhaleNeedAtLeastOneSecond() {
        #expect(record(0, 0, 4, 0) == nil)
        #expect(record(4, 0, 0, 0) == nil)
    }

    @Test func aNegativeHoldIsRefused() {
        #expect(record(4, -1, 4, 0) == nil)
    }

    @Test func phasesAboveThirtySecondsAreRefused() {
        #expect(record(31, 0, 4, 0) == nil)
        #expect(record(4, 31, 4, 0) == nil)
        #expect(record(30, 30, 30, 30) != nil)
    }

    @Test func cycleCountOfACustomPattern() throws {
        let exercise = try #require(record(4, 2, 6, 0)).exercise // 12 s per cycle
        #expect(exercise.sessionLength(for: .seconds(300)).cycleCount == 25)
        #expect(exercise.sessionLength(for: .seconds(180)).totalLength == .seconds(180))
    }

    @Test func eachRecordGetsItsOwnID() throws {
        let first = try #require(record(4, 0, 4, 0))
        let second = try #require(record(4, 0, 4, 0))
        #expect(first.id != second.id)
        #expect(first.exercise.id == first.id)
    }

    @Test func durationOptionsAreOneThreeFiveAndTenMinutes() throws {
        let exercise = try #require(record(4, 0, 4, 0)).exercise
        #expect(exercise.durationOptions == [.seconds(60), .seconds(180), .seconds(300), .seconds(600)])
        #expect(exercise.defaultDuration == .seconds(300))
    }

    @Test func recordEncodesAndDecodesToTheSameValue() throws {
        let original = try #require(record(4, 2, 6, 0))
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(CustomExerciseRecord.self, from: data) == original)
    }
}
