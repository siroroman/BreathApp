import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@MainActor
@Suite struct LastSessionTests {
    private func saved(_ json: String) -> SavedDocument<LastSession> {
        SavedDocument(store: InMemoryDocumentStore(Data(json.utf8)))
    }

    @Test func quickStartIsBoxBreathingAtFiveMinutesBeforeAnySession() {
        let saved = SavedDocument<LastSession>(store: InMemoryDocumentStore())
        let choice = saved.value.quickStart
        #expect(choice.exercise == .box)
        #expect(choice.requested == .seconds(300))
    }

    @Test func theLastSessionIsReadBackByANewInstance() {
        let store = InMemoryDocumentStore()
        SavedDocument<LastSession>(store: store).update(LastSession(exerciseID: "coherent", requested: .seconds(600)))
        let choice = SavedDocument<LastSession>(store: store).value.quickStart
        #expect(choice.exercise == .coherent)
        #expect(choice.requested == .seconds(600))
    }

    @Test func anUnknownExerciseIDShowsBoxBreathingAtFiveMinutes() {
        let choice = saved(#"{"version":1,"exerciseID":"gone","seconds":75}"#).value.quickStart
        #expect(choice.exercise == .box)
        #expect(choice.requested == .seconds(300))
    }

    @Test func aBadLengthFallsBackToTheDefaultLengthAlone() {
        for json in [#"{"version":1,"exerciseID":"coherent","seconds":-5}"#,
                     #"{"version":1,"exerciseID":"coherent","seconds":"long"}"#,
                     #"{"version":1,"exerciseID":"coherent"}"#]
        {
            let choice = saved(json).value.quickStart
            #expect(choice.exercise == .coherent)
            #expect(choice.requested == .seconds(300))
        }
    }

    @Test func corruptBytesFallBackWithoutACrash() {
        let loaded = saved("{{{")
        #expect(loaded.outcome == .recovered)
        #expect(loaded.value.quickStart.exercise == .box)
    }

    @Test func theEncodingIsStable() throws {
        let store = InMemoryDocumentStore()
        SavedDocument<LastSession>(store: store).update(LastSession(exerciseID: "box", requested: .seconds(180)))
        let saved = try store.load()
        let bytes = try #require(saved)
        #expect(String(decoding: bytes, as: UTF8.self) == #"{"exerciseID":"box","seconds":180,"version":1}"#)
    }
}
