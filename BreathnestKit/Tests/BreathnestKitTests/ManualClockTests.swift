import Testing

@Suite struct ManualClockTests {
    @Test(.timeLimit(.minutes(1)))
    func tenMinuteSleepEndsOnlyWhenTheClockReachesTheDeadline() async throws {
        let clock = ManualClock()
        let sleeper = Task { try await clock.sleep(for: .seconds(600)) }
        await clock.waitForSleepers(1)

        clock.advance(by: .seconds(599))
        #expect(clock.sleeperCount == 1)

        clock.advance(by: .seconds(1))
        try await sleeper.value
        #expect(clock.sleeperCount == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func sleepUntilAPastDeadlineReturnsAtOnce() async throws {
        let clock = ManualClock()
        clock.advance(by: .seconds(10))

        try await clock.sleep(until: clock.now.advanced(by: .seconds(-5)))

        #expect(clock.sleeperCount == 0)
    }
}
