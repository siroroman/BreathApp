import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@MainActor
@Suite struct LogTests {
    private let finished = ISO8601DateFormatter().date(from: "2026-11-24T07:30:00Z")!

    private func make(id: String = "id-1", at date: Date? = nil, exercise: Exercise = .box,
                      custom: String? = nil) -> LogEntry
    {
        LogEntry(
            id: id, exerciseID: exercise.id, finishedAt: date ?? finished, length: .seconds(300),
            pattern: exercise.pattern, customName: custom
        )
    }

    @Test func aNewLogIsEmpty() {
        let saved = SavedDocument<Log>(store: InMemoryDocumentStore())
        #expect(saved.value.entries.isEmpty)
        #expect(saved.outcome == .empty)
    }

    @Test func anEntryRoundTrips() {
        let store = InMemoryDocumentStore()
        let entry = make(custom: "Evening calm")
        SavedDocument<Log>(store: store).update(Log(entries: [entry]))
        let back = SavedDocument<Log>(store: store)
        #expect(back.value.entries == [entry])
        #expect(back.outcome == .loaded)
    }

    @Test func theDocumentIsAVersionedListOfItems() throws {
        let store = InMemoryDocumentStore()
        SavedDocument<Log>(store: store).update(Log(entries: [make()]))
        let data = try #require(try store.load())
        let json = try #require(String(data: data, encoding: .utf8))
        #expect(json.contains(#""version":1"#))
        #expect(json.contains(#""items":["#))
        #expect(json.contains(#""exerciseID":"box""#))
    }

    @Test func unreadableBytesAreSetAsideAndTheLogStartsEmpty() {
        let store = InMemoryDocumentStore(Data("{nope".utf8))
        let saved = SavedDocument<Log>(store: store)
        #expect(saved.value.entries.isEmpty)
        #expect(saved.outcome == .recovered)
    }

    @Test func aNewerVersionIsUnreadable() {
        let store = InMemoryDocumentStore(Data(#"{"version":2,"items":[]}"#.utf8))
        #expect(SavedDocument<Log>(store: store).outcome == .recovered)
    }

    @Test func entriesAreListedNewestFirst() {
        let older = make(id: "a", at: finished)
        let newer = make(id: "b", at: finished.addingTimeInterval(3600))
        let log = Log(entries: [older, newer])
        #expect(log.newestFirst.map(\.id) == ["b", "a"])
    }

    @Test func addingAnEntryKeepsTheOthers() {
        var log = Log(entries: [make(id: "a")])
        log.append(make(id: "b"))
        #expect(log.entries.map(\.id) == ["a", "b"])
    }

    @Test func aBuiltInEntryKeepsThePatternCopy() throws {
        let store = InMemoryDocumentStore()
        SavedDocument<Log>(store: store).update(Log(entries: [make(exercise: .fourSevenEight)]))
        let back = SavedDocument<Log>(store: store).value.entries[0]
        #expect(back.pattern == Exercise.fourSevenEight.pattern)
        #expect(back.length == .seconds(300))
    }
}
