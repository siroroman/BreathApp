import BreathnestKit
import Observation

/// The Quick Start card: the Exercise and length of the last Session that started, and the Haptics setting now.
/// Holds no text (ADR 0002): the view builds it from the catalog.
@MainActor
@Observable
final class QuickStartViewModel {
    @ObservationIgnored private let settings: AppSettingsStore
    @ObservationIgnored private let lastSession: LastSessionStore

    init(settings: AppSettingsStore, lastSession: LastSessionStore) {
        self.settings = settings
        self.lastSession = lastSession
    }

    var exercise: Exercise { lastSession.quickStart.exercise }
    var requested: Duration { lastSession.quickStart.requested }
    var isHapticsOn: Bool { settings.settings.isHapticsOn }

    /// Start begins the Session with this choice, so it counts as the last Session again.
    func started() {
        lastSession.record(exercise: exercise, requested: requested)
    }
}
