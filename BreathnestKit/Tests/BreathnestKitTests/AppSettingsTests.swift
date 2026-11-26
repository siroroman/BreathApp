import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@MainActor
@Suite struct AppSettingsTests {
    private func settings(from json: String) -> SavedDocument<AppSettings> {
        SavedDocument(store: InMemoryDocumentStore(Data(json.utf8)))
    }

    @Test func defaultsAreSoundOnTheFirstSoundAndHapticsOn() {
        let saved = SavedDocument<AppSettings>(store: InMemoryDocumentStore())
        #expect(saved.value == AppSettings(isSoundOn: true, soundID: .softBell, isHapticsOn: true))
        #expect(saved.value.soundID == SoundID.allCases.first)
        #expect(saved.outcome == .empty)
    }

    @Test func nothingIsWrittenUntilTheFirstChange() {
        let store = InMemoryDocumentStore()
        _ = SavedDocument<AppSettings>(store: store)
        #expect(store.saveCount == 0)
    }

    @Test func aValueWrittenIsReadBackByANewInstance() {
        let store = InMemoryDocumentStore()
        let first = SavedDocument<AppSettings>(store: store)
        first.update(AppSettings(isSoundOn: false, soundID: .chime, isHapticsOn: false))
        let second = SavedDocument<AppSettings>(store: store)
        #expect(second.value == AppSettings(isSoundOn: false, soundID: .chime, isHapticsOn: false))
        #expect(second.outcome == .loaded)
    }

    @Test func thereAreFiveSoundsAndTheIDsAreStable() {
        #expect(SoundID.allCases.map(\.rawValue) == ["soft-bell", "singing-bowl", "chime", "wood-block", "pulse"])
    }

    @Test func anUnknownSoundIDResolvesToTheFirstSound() {
        let saved = settings(from: #"{"version":1,"isSoundOn":false,"soundID":"gong","isHapticsOn":false}"#)
        #expect(saved.value == AppSettings(isSoundOn: false, soundID: .softBell, isHapticsOn: false))
        #expect(saved.outcome == .loaded)
    }

    @Test func aMissingOrMistypedFieldFallsBackAloneNotTheWholeValue() {
        let saved = settings(from: #"{"version":1,"isSoundOn":"yes","soundID":"pulse"}"#)
        #expect(saved.value == AppSettings(isSoundOn: true, soundID: .pulse, isHapticsOn: true))
    }

    @Test func savedBytesAreKeptWhenTheyAreNotJSONAndTheDefaultIsUsed() {
        let store = InMemoryDocumentStore(Data("not json".utf8))
        let saved = SavedDocument<AppSettings>(store: store)
        #expect(saved.value == .defaultValue)
        #expect(saved.outcome == .recovered)
        #expect(store.setAsideData == [Data("not json".utf8)])
    }

    @Test func aWrongShapeIsUnreadable() {
        let saved = settings(from: "[1, 2]")
        #expect(saved.value == .defaultValue)
        #expect(saved.outcome == .recovered)
    }

    @Test func aNewerVersionIsUnreadableAndItsBytesAreKept() {
        let json = #"{"version":2,"isSoundOn":false,"soundID":"pulse","isHapticsOn":false}"#
        let store = InMemoryDocumentStore(Data(json.utf8))
        let saved = SavedDocument<AppSettings>(store: store)
        #expect(saved.value == .defaultValue)
        #expect(saved.outcome == .recovered)
        #expect(store.setAsideData == [Data(json.utf8)])
    }

    @Test func nothingIsOverwrittenWhenTheBytesCouldNotBeSetAside() {
        let store = InMemoryDocumentStore(Data("junk".utf8))
        store.failsSetAside = true
        let saved = SavedDocument<AppSettings>(store: store)
        saved.update(AppSettings(isSoundOn: false, soundID: .softBell, isHapticsOn: true))
        #expect(saved.value.isSoundOn == false)
        #expect(store.saveCount == 0)
    }

    @Test func aLoadThatThrowsGivesTheDefaultUnavailableAndNeverSavesOverIt() {
        let store = InMemoryDocumentStore(Data(#"{"version":1,"isSoundOn":false}"#.utf8))
        store.failsLoad = true
        let saved = SavedDocument<AppSettings>(store: store)
        #expect(saved.outcome == .unavailable)
        #expect(saved.value == .defaultValue)
        #expect(store.setAsideData.isEmpty)
        saved.update(AppSettings(isSoundOn: true, soundID: .pulse, isHapticsOn: true))
        #expect(store.saveCount == 0)
        #expect(saved.value.soundID == .pulse)
    }

    @Test func aFailedWriteKeepsTheValueInMemory() {
        let store = InMemoryDocumentStore()
        store.failsSave = true
        let saved = SavedDocument<AppSettings>(store: store)
        saved.update(AppSettings(isSoundOn: true, soundID: .chime, isHapticsOn: false))
        #expect(saved.value.soundID == .chime)
    }

    @Test func theEncodingIsStable() throws {
        let store = InMemoryDocumentStore()
        SavedDocument<AppSettings>(store: store).update(AppSettings(isSoundOn: false, soundID: .woodBlock, isHapticsOn: true))
        let bytes = try #require(try store.load())
        #expect(String(decoding: bytes, as: UTF8.self) == #"{"isHapticsOn":true,"isSoundOn":false,"soundID":"wood-block","version":1}"#)
    }
}
