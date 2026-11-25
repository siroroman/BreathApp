import Testing

@testable import Breathnest

@Suite struct PlayerGenerationTests {
    @Test func aStopFromBeforeANewPlayerIsNoLongerCurrent() {
        let generation = PlayerGeneration()
        let stopped = generation.current
        generation.advance()
        #expect(!generation.isCurrent(stopped))
    }

    @Test func aStopWithNoNewPlayerInBetweenIsStillCurrent() {
        let generation = PlayerGeneration()
        generation.advance()
        let stopped = generation.current
        #expect(generation.isCurrent(stopped))
    }
}
