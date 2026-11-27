import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@testable import Breathnest

@MainActor
@Suite struct LogStoreTests {
    private let finished = ISO8601DateFormatter().date(from: "2026-11-24T07:30:00Z")!

    @Test func aCompletedSessionAddsOneEntryWithItsExactLengthAndTheNow() {
        let store = LogStore(store: InMemoryDocumentStore(), now: { finished })
        store.recordCompleted(exercise: .fourSevenEight, length: .seconds(76), customName: nil)
        #expect(store.log.entries.count == 1)
        let entry = store.log.entries[0]
        #expect(entry.exerciseID == "four-seven-eight")
        #expect(entry.length == .seconds(76))
        #expect(entry.finishedAt == finished)
        #expect(entry.pattern == Exercise.fourSevenEight.pattern)
        #expect(entry.customName == nil)
    }

    @Test func theEntryIsSavedAndReadBackByANewStore() {
        let backing = InMemoryDocumentStore()
        LogStore(store: backing, now: { finished })
            .recordCompleted(exercise: .box, length: .seconds(300), customName: nil)
        #expect(LogStore(store: backing).log.entries.count == 1)
    }

    @Test func aCustomExerciseKeepsACopyOfItsName() {
        let store = LogStore(store: InMemoryDocumentStore())
        store.recordCompleted(exercise: .box, length: .seconds(300), customName: "Evening calm")
        #expect(store.log.entries[0].customName == "Evening calm")
    }

    @Test func aFailingWriteKeepsTheEntryInMemory() {
        let backing = InMemoryDocumentStore()
        backing.failsSave = true
        let store = LogStore(store: backing)
        store.recordCompleted(exercise: .box, length: .seconds(300), customName: nil)
        #expect(store.log.entries.count == 1)
    }
}
