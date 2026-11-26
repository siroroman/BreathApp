import BreathnestKit
import Foundation
import Testing

@testable import Breathnest

@Suite struct FileDocumentStoreTests {
    private func makeStore() -> FileDocumentStore {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        return FileDocumentStore(url: directory.appending(path: "custom-exercises.json"), stamp: { "T" })
    }

    @Test func nothingSavedLoadsNil() throws {
        #expect(try makeStore().load() == nil)
    }

    @Test func savedBytesComeBack() throws {
        let store = makeStore()
        try store.save(Data("hello".utf8))
        #expect(try store.load() == Data("hello".utf8))
    }

    @Test func setAsideKeepsTheBytesUnderAnotherName() throws {
        let store = makeStore()
        try store.save(Data("junk".utf8))
        try store.setAside()
        #expect(try store.load() == nil)
        let kept = store.url.deletingLastPathComponent().appending(path: "custom-exercises.unreadable-T.json")
        #expect(try Data(contentsOf: kept) == Data("junk".utf8))
    }

    @Test func aCustomExerciseListSurvivesThroughTheFile() throws {
        let backing = makeStore()
        let record = try #require(CustomExerciseRecord(
            name: "Calm", icon: .wind, description: "", inhale: 4, holdAfterInhale: 0, exhale: 6, holdAfterExhale: 2
        ))
        CustomExerciseStore(backing: backing).save([record])
        #expect(CustomExerciseStore(backing: backing).load().records == [record])
    }
}
