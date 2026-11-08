import BreathnestKit
import Observation

/// The state of one Exercise detail sheet. A sheet makes a new one, so the Duration option and the Haptics
/// switch start at their defaults every time it opens. Holds no text: the view builds it from the catalog.
@MainActor
@Observable
final class ExerciseDetailViewModel {
    let exercise: Exercise
    private(set) var selectedDuration: Duration
    /// On by default. Not saved until #54.
    private(set) var isHapticsOn = true

    init(exercise: Exercise) {
        self.exercise = exercise
        selectedDuration = exercise.defaultDuration
    }

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
        isHapticsOn = isOn
    }
}
