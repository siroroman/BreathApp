import BreathnestKit
import Observation

/// The last Session that started, as the Quick Start card needs it.
@MainActor
@Observable
final class LastSessionStore {
    private(set) var quickStart: QuickStart
    @ObservationIgnored private let document: SavedDocument<LastSession>

    init(store: any DocumentStore) {
        document = SavedDocument(store: store)
        quickStart = document.value.quickStart
    }

    /// Called when a Session starts, whether or not it later completes.
    func record(exercise: Exercise, requested: Duration) {
        document.update(LastSession(exerciseID: exercise.id, requested: requested))
        quickStart = document.value.quickStart
    }
}
