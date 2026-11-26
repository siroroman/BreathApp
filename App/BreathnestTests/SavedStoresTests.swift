import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@testable import Breathnest

@MainActor
@Suite struct SavedStoresTests {
    @Test func settingsStartAtTheirDefaults() {
        let settings = AppSettingsStore(store: InMemoryDocumentStore())
        #expect(settings.settings == .defaultValue)
    }

    @Test func eachSettingChangeIsSavedAndReadBackByANewStore() {
        let bytes = InMemoryDocumentStore()
        let settings = AppSettingsStore(store: bytes)
        settings.setSound(isOn: false)
        settings.setSound(.chime)
        settings.setHaptics(isOn: false)
        let reread = AppSettingsStore(store: bytes)
        #expect(reread.settings == AppSettings(isSoundOn: false, soundID: .chime, isHapticsOn: false))
    }

    @Test func quickStartIsBoxAtFiveMinutesBeforeAnySession() {
        let store = LastSessionStore(store: InMemoryDocumentStore())
        #expect(store.quickStart == QuickStart(exercise: .box, requested: .seconds(300)))
    }

    @Test func recordingASessionIsReadBackByANewStore() {
        let bytes = InMemoryDocumentStore()
        LastSessionStore(store: bytes).record(exercise: .fourSevenEight, requested: .seconds(120))
        let quickStart = LastSessionStore(store: bytes).quickStart
        #expect(quickStart == QuickStart(exercise: .fourSevenEight, requested: .seconds(120)))
    }

    @Test func userDefaultsHoldsTheBytesUnderItsKey() throws {
        let defaults = try #require(UserDefaults(suiteName: "SavedStoresTests.\(UUID().uuidString)"))
        let store = UserDefaultsDocumentStore(defaults: defaults, key: "breathnest.settings")
        let empty = try store.load()
        #expect(empty == nil)
        try store.save(Data("abc".utf8))
        let kept = try store.load()
        #expect(kept == Data("abc".utf8))
        #expect(defaults.data(forKey: "breathnest.settings") == Data("abc".utf8))
    }

    @Test func settingsSurviveANewUserDefaultsStoreOverTheSameKey() throws {
        let defaults = try #require(UserDefaults(suiteName: "SavedStoresTests.\(UUID().uuidString)"))
        AppSettingsStore(store: UserDefaultsDocumentStore(defaults: defaults, key: "breathnest.settings"))
            .setHaptics(isOn: false)
        let reread = AppSettingsStore(store: UserDefaultsDocumentStore(defaults: defaults, key: "breathnest.settings"))
        #expect(reread.settings.isHapticsOn == false)
    }

    @Test func aValueOfTheWrongTypeIsKeptAndTheDefaultIsUsed() throws {
        let defaults = try #require(UserDefaults(suiteName: "SavedStoresTests.\(UUID().uuidString)"))
        defaults.set("not data", forKey: "breathnest.settings")
        let settings = AppSettingsStore(store: UserDefaultsDocumentStore(
            defaults: defaults,
            key: "breathnest.settings"
        ))
        #expect(settings.settings == .defaultValue)
        #expect(defaults.string(forKey: "breathnest.settings.unreadable") == "not data")
    }

    @Test func corruptBytesAreKeptUnderTheUnreadableKey() throws {
        let defaults = try #require(UserDefaults(suiteName: "SavedStoresTests.\(UUID().uuidString)"))
        defaults.set(Data("{{{".utf8), forKey: "breathnest.lastSession")
        let store = LastSessionStore(store: UserDefaultsDocumentStore(
            defaults: defaults,
            key: "breathnest.lastSession"
        ))
        #expect(store.quickStart.exercise == .box)
        #expect(defaults.data(forKey: "breathnest.lastSession.unreadable") == Data("{{{".utf8))
    }
}
