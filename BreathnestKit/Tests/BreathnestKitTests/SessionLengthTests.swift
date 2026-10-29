import Testing

@testable import BreathnestKit

@Suite struct SessionLengthTests {
    @Test(arguments: [
        (Exercise.box, 19, Duration.seconds(304)),
        (Exercise.fourSevenEight, 16, Duration.seconds(304)),
        (Exercise.coherent, 27, Duration.seconds(297)),
        (Exercise.physiologicalSigh, 33, Duration.seconds(297)),
    ])
    func fiveMinutesRoundsToTheNearestWholeCycles(exercise: Exercise, cycleCount: Int, totalLength: Duration) {
        let length = exercise.sessionLength(for: .seconds(300))
        #expect(length.cycleCount == cycleCount)
        #expect(length.totalLength == totalLength)
    }

    @Test(arguments: [
        (Duration.seconds(75), 4),
        (Duration.seconds(120), 6),
        (Duration.seconds(150), 8),
    ])
    func fourSevenEightOptionsGiveFourSixAndEightCycles(requested: Duration, cycleCount: Int) {
        #expect(Exercise.fourSevenEight.sessionLength(for: requested).cycleCount == cycleCount)
    }

    @Test func halfwayBetweenTwoCycleCountsRoundsUp() {
        // Coherent breathing has an 11 second Cycle, so 60.5 seconds is exactly 5.5 Cycles.
        #expect(Exercise.coherent.sessionLength(for: .seconds(60.5)).cycleCount == 6)
    }

    @Test func justBelowHalfwayRoundsDown() {
        #expect(Exercise.coherent.sessionLength(for: .seconds(60.4)).cycleCount == 5)
    }

    @Test(arguments: [Duration.seconds(5), .seconds(1), .zero, .seconds(-60)])
    func lastsAtLeastOneCycle(requested: Duration) {
        let length = Exercise.box.sessionLength(for: requested)
        #expect(length.cycleCount == 1)
        #expect(length.totalLength == .seconds(16))
    }
}
