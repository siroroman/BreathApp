import Foundation
import Testing

@testable import BreathnestKit

private final class MemoryStore: DocumentStore, @unchecked Sendable {
    var data: Data?
    var loadError: (any Error)?
    var setAsideCount = 0
    var saveCount = 0
    func load() throws -> Data? {
        if let loadError { throw loadError }
        return data
    }

    func save(_ data: Data) throws {
        saveCount += 1
        self.data = data
    }

    func setAside() throws {
        setAsideCount += 1
    }
}

private struct Failure: Error {}

@Suite struct CustomExerciseStoreTests {
    private func record(_ name: String = "Calm") -> CustomExerciseRecord {
        CustomExerciseRecord(
            name: name, icon: .leaf, description: "", inhale: 4, holdAfterInhale: 0, exhale: 6, holdAfterExhale: 0
        )!
    }

    @Test func nothingSavedLoadsEmptyWithoutAWrite() {
        let backing = MemoryStore()
        let store = CustomExerciseStore(backing: backing)
        #expect(store.load() == CustomExerciseLoad(records: [], outcome: .empty))
        #expect(backing.saveCount == 0)
    }

    @Test func savedRecordsComeBackInOrder() {
        let backing = MemoryStore()
        let store = CustomExerciseStore(backing: backing)
        let records = [record("A"), record("B")]
        store.save(records)
        let loaded = CustomExerciseStore(backing: backing).load()
        #expect(loaded == CustomExerciseLoad(records: records, outcome: .loaded))
    }

    @Test func theDocumentIsVersionOneWithItems() throws {
        let backing = MemoryStore()
        CustomExerciseStore(backing: backing).save([record()])
        let bytes = try #require(backing.data)
        let json = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        #expect(json["version"] as? Int == 1)
        #expect((json["items"] as? [Any])?.count == 1)
    }

    @Test func unreadableBytesAreSetAsideAndTheListIsEmpty() {
        let backing = MemoryStore()
        backing.data = Data("not json".utf8)
        let store = CustomExerciseStore(backing: backing)
        #expect(store.load() == CustomExerciseLoad(records: [], outcome: .recovered))
        #expect(backing.setAsideCount == 1)
    }

    @Test func aNewerVersionIsUnreadable() {
        let backing = MemoryStore()
        backing.data = Data(#"{"version":2,"items":[]}"#.utf8)
        #expect(CustomExerciseStore(backing: backing).load().outcome == .recovered)
    }

    @Test func aFailedLoadIsUnavailableAndNeverOverwritesTheFile() {
        let backing = MemoryStore()
        backing.loadError = Failure()
        let store = CustomExerciseStore(backing: backing)
        #expect(store.load() == CustomExerciseLoad(records: [], outcome: .unavailable))
        store.save([record()])
        #expect(backing.saveCount == 0)
        #expect(backing.setAsideCount == 0)
    }

    @Test func nothingIsWrittenOverBytesThatCouldNotBeKept() {
        final class Refusing: DocumentStore, @unchecked Sendable {
            var saved = false
            func load() throws -> Data? { Data("junk".utf8) }
            func save(_: Data) throws { saved = true }
            func setAside() throws { throw Failure() }
        }
        let backing = Refusing()
        let store = CustomExerciseStore(backing: backing)
        #expect(store.load().outcome == .recovered)
        store.save([record()])
        #expect(!backing.saved)
    }

    @Test func aFailedWriteDoesNotThrow() {
        final class Failing: DocumentStore, @unchecked Sendable {
            func load() throws -> Data? { nil }
            func save(_: Data) throws { throw Failure() }
            func setAside() throws {}
        }
        CustomExerciseStore(backing: Failing()).save([record()])
    }
}
