import BreathnestKit
import Observation

/// The state of one Exercise detail sheet. A sheet makes a new one, so the Duration starts at its default
/// every time it opens; Sound, the chosen sound and Haptics are the saved settings. Holds no text: the view builds it
/// from the catalog.
@MainActor
@Observable
final class ExerciseDetailViewModel {
    let exercise: Exercise
    private(set) var selectedDuration: Duration
    @ObservationIgnored private let settings: AppSettingsStore
    @ObservationIgnored private let lastSession: LastSessionStore

    init(exercise: Exercise, settings: AppSettingsStore, lastSession: LastSessionStore) {
        self.exercise = exercise
        self.settings = settings
        self.lastSession = lastSession
        selectedDuration = exercise.defaultPickerDuration
    }

    var isHapticsOn: Bool { settings.settings.isHapticsOn }
    var isSoundOn: Bool { settings.settings.isSoundOn }
    var soundID: SoundID { settings.settings.soundID }

    /// The whole minutes the Duration picker offers, 1 to 30, for every Exercise.
    var pickerMinutes: [Int] {
        Array(1 ... 30)
    }

    /// The Cycles and the exact length of a Session at the selected duration.
    var sessionLength: SessionLength {
        exercise.sessionLength(for: selectedDuration)
    }

    /// The selected duration in whole minutes: the picker only offers whole minutes.
    var selectedMinutes: Int {
        Int((selectedDuration / .seconds(60)).rounded())
    }

    /// A duration that is not one of the picker's values is ignored.
    func select(duration: Duration) {
        guard exercise.pickerDurations.contains(duration) else { return }
        selectedDuration = duration
    }

    /// A minute outside the picker's 1 to 30 is ignored.
    func select(minutes: Int) {
        guard pickerMinutes.contains(minutes) else { return }
        selectedDuration = .seconds(minutes * 60)
    }

    func setHaptics(isOn: Bool) {
        settings.setHaptics(isOn: isOn)
    }

    func setSound(isOn: Bool) {
        settings.setSound(isOn: isOn)
    }

    func select(sound: SoundID) {
        settings.setSound(sound)
    }

    /// Start was tapped: this Exercise and length become the Quick Start choice.
    func sessionStarted() {
        lastSession.record(exercise: exercise, requested: selectedDuration)
    }
}
