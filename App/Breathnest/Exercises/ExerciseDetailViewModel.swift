import BreathnestKit
import Observation

/// The state of one Exercise detail sheet. A sheet makes a new one, so the Duration option starts at its default
/// every time it opens; Sound, the chosen sound and Haptics are the saved settings. Holds no text: the view builds it from the catalog.
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
        selectedDuration = exercise.defaultDuration
    }

    var isHapticsOn: Bool { settings.settings.isHapticsOn }
    var isSoundOn: Bool { settings.settings.isSoundOn }
    var soundID: SoundID { settings.settings.soundID }

    var durationOptions: [Duration] {
        exercise.durationOptions
    }

    /// The Cycles and the exact length of a Session at the selected option.
    var sessionLength: SessionLength {
        exercise.sessionLength(for: selectedDuration)
    }

    /// Whole-minute options read "5 min"; the others, such as 4-7-8, read "1:15" so no option is rounded.
    var optionsAreWholeMinutes: Bool {
        durationOptions.allSatisfy { $0.components.seconds % 60 == 0 && $0.components.attoseconds == 0 }
    }

    /// A duration that is not one of the Exercise's options is ignored.
    func select(duration: Duration) {
        guard durationOptions.contains(duration) else { return }
        selectedDuration = duration
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
