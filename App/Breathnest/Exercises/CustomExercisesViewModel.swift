import BreathnestKit
import Observation

/// The custom Exercises the user saved, in the order they were saved (the Custom exercise row sits above them). Loads
/// once and
/// writes through `CustomExerciseStore` on each change; a failed write keeps the list in memory (ADR 0003, F6).
@MainActor
@Observable
final class CustomExercisesViewModel {
    private(set) var records: [CustomExerciseRecord]
    @ObservationIgnored private let store: CustomExerciseStore

    init(store: CustomExerciseStore) {
        self.store = store
        records = store.load().records
    }

    func add(_ record: CustomExerciseRecord) {
        records.append(record)
        store.save(records)
    }

    func record(withID id: String) -> CustomExerciseRecord? {
        records.first { $0.id == id }
    }

    var exercises: [Exercise] {
        records.map(\.exercise)
    }
}
