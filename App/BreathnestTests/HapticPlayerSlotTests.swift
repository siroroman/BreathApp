import Testing

@testable import Breathnest

@MainActor @Suite struct HapticPlayerSlotTests {
    @Test func aLateStopDoesNotClearAPlayerStartedAfterIt() {
        let slot = HapticPlayerSlot<String>()
        slot.hold("old")
        // The engine stops and reports it off the main thread; the main actor has not heard yet.
        let late = slot.stopReported()
        // Meanwhile the next Phase starts a new player.
        slot.hold("new")
        late()
        #expect(slot.player == "new")
    }

    @Test func aStopWithNoNewPlayerInBetweenClearsThePlayer() {
        let slot = HapticPlayerSlot<String>()
        slot.hold("old")
        let late = slot.stopReported()
        late()
        #expect(slot.player == nil)
    }

    @Test func releasingHandsBackThePlayerAndEmptiesTheSlot() {
        let slot = HapticPlayerSlot<String>()
        slot.hold("old")
        #expect(slot.release() == "old")
        #expect(slot.player == nil)
        #expect(slot.release() == nil)
    }

    @Test func aStopReportedBeforeReleaseLeavesTheSlotEmptyWhenItArrives() {
        let slot = HapticPlayerSlot<String>()
        slot.hold("old")
        let late = slot.stopReported()
        _ = slot.release()
        slot.hold("new")
        late()
        #expect(slot.player == "new")
    }
}
