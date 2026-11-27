import BreathnestKit
import Foundation
import Observation

/// The Log as the screens see it: one entry per Session that completed (#58, #53). A stopped Session adds none.
/// Loads once and writes `log.json` on every new entry (ADR 0003); a failed write keeps the entry in memory.
@MainActor
@Observable
final class LogStore {
    private(set) var log: Log
    @ObservationIgnored private let document: SavedDocument<Log>
    @ObservationIgnored private let now: @MainActor () -> Date

    init(store: any DocumentStore, now: @escaping @MainActor () -> Date = { Date() }) {
        document = SavedDocument(store: store)
        log = document.value
        self.now = now
    }

    /// `customName` is the name of a custom Exercise, kept as a copy so a later edit or delete never changes the row.
    func recordCompleted(exercise: Exercise, length: Duration, customName: String?) {
        var updated = log
        updated.append(LogEntry(
            exerciseID: exercise.id, finishedAt: now(), length: length, pattern: exercise.pattern,
            customName: customName
        ))
        document.update(updated)
        log = document.value
    }
}
