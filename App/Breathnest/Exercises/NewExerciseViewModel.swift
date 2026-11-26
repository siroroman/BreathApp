import BreathnestKit
import Observation

/// The state of the New exercise sheet. Holds no text the app writes: `name` and `details` are what the user typed.
@MainActor
@Observable
final class NewExerciseViewModel {
    enum Field: CaseIterable {
        case inhale, holdAfterInhale, exhale, holdAfterExhale

        /// Inhale and Exhale need a second; a Hold may be 0 s, which leaves its Phase out.
        fileprivate var minimum: Int {
            switch self {
            case .inhale, .exhale: 1
            case .holdAfterInhale, .holdAfterExhale: 0
            }
        }
    }

    var name = ""
    var icon: CustomExerciseIcon = .ring
    /// The description. Not `description`, which every object already has.
    var details = ""
    private(set) var inhale = 4
    private(set) var holdAfterInhale = 0
    private(set) var exhale = 4
    private(set) var holdAfterExhale = 0

    func seconds(_ field: Field) -> Int {
        switch field {
        case .inhale: inhale
        case .holdAfterInhale: holdAfterInhale
        case .exhale: exhale
        case .holdAfterExhale: holdAfterExhale
        }
    }

    func canDecrease(_ field: Field) -> Bool {
        seconds(field) > field.minimum
    }

    func canIncrease(_ field: Field) -> Bool {
        seconds(field) < CustomExerciseRecord.maximumSeconds
    }

    func decrease(_ field: Field) {
        if canDecrease(field) { set(field, seconds(field) - 1) }
    }

    func increase(_ field: Field) {
        if canIncrease(field) { set(field, seconds(field) + 1) }
    }

    /// The live summary: `12 s per cycle`.
    var secondsPerCycle: Int {
        inhale + holdAfterInhale + exhale + holdAfterExhale
    }

    var canSave: Bool {
        makeRecord() != nil
    }

    /// `nil` without a name. A new ID each time.
    func makeRecord() -> CustomExerciseRecord? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return CustomExerciseRecord(
            name: trimmed, icon: icon, description: details.trimmingCharacters(in: .whitespacesAndNewlines),
            inhale: inhale, holdAfterInhale: holdAfterInhale, exhale: exhale, holdAfterExhale: holdAfterExhale
        )
    }

    private func set(_ field: Field, _ value: Int) {
        switch field {
        case .inhale: inhale = value
        case .holdAfterInhale: holdAfterInhale = value
        case .exhale: exhale = value
        case .holdAfterExhale: holdAfterExhale = value
        }
    }
}
