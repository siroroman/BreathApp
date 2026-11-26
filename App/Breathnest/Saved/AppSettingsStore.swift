import BreathnestKit
import Observation

/// The saved settings as the screens see them: Sound, the chosen sound and Haptics. The detail, the Session menu
/// and the Quick Start card read this one object, so a change shows everywhere at once. Holds no text.
@MainActor
@Observable
final class AppSettingsStore {
    private(set) var settings: AppSettings
    @ObservationIgnored private let document: SavedDocument<AppSettings>

    init(store: any DocumentStore) {
        document = SavedDocument(store: store)
        settings = document.value
    }

    func setSound(isOn: Bool) {
        change { $0.isSoundOn = isOn }
    }

    func setSound(_ id: SoundID) {
        change { $0.soundID = id }
    }

    func setHaptics(isOn: Bool) {
        change { $0.isHapticsOn = isOn }
    }

    private func change(_ edit: (inout AppSettings) -> Void) {
        var updated = settings
        edit(&updated)
        document.update(updated)
        settings = updated
    }
}
