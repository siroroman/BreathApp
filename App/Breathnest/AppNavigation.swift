import BreathnestKit
import Observation

/// The one navigation model of the iPhone app (ADR 0002): what is open, by Exercise ID, so a tap on a row and a
/// tap on a notification reach the same detail sheet. The tab and the open Session join it with their tickets.
@MainActor
@Observable
final class AppNavigation {
    /// The Exercise whose detail sheet is open.
    private(set) var openExercise: Exercise?
    @ObservationIgnored private let customExercises: CustomExercisesViewModel?

    init(customExercises: CustomExercisesViewModel? = nil) {
        self.customExercises = customExercises
    }

    /// An ID that is neither a built-in nor a saved custom Exercise opens nothing.
    func openDetail(of id: Exercise.ID) {
        openExercise = Exercise.builtIn.first { $0.id == id } ?? customExercises?.exercises.first { $0.id == id }
    }

    func closeDetail() {
        openExercise = nil
    }
}
