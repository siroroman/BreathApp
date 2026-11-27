import BreathnestKit
import Observation

/// The look of the app. Aurora is the only one today; the row and its list are drawn for more (#60).
enum Appearance: Hashable, CaseIterable {
    case aurora
}

/// The Settings sheet (design screen 9): the version line, the Appearance choice and the Health access row.
/// Holds no text (ADR 0002): the view builds it from the catalog.
@MainActor
@Observable
final class SettingsViewModel {
    /// What a tap on the Health access row asks the view to do.
    enum HealthOutcome: Equatable {
        /// The system's permission sheet was shown; the row now holds the answer.
        case requested
        /// Allowed or denied: only the iOS Settings app changes it.
        case opensSystemSettings
        case nothing
    }

    @ObservationIgnored private let health: any HealthAccess
    private(set) var healthState: HealthAccessState
    let versionText: String
    let appearances = Appearance.allCases
    private(set) var appearance = Appearance.aurora

    init(health: any HealthAccess, version: AppVersion) {
        self.health = health
        healthState = health.state
        versionText = version.display
    }

    /// Reads the state again, for when the person comes back from the iOS Settings app.
    func refreshHealth() {
        healthState = health.state
    }

    func healthTapped() async -> HealthOutcome {
        switch healthState {
        case .notDetermined:
            healthState = await health.requestAccess()
            return .requested
        case .allowed, .denied:
            return .opensSystemSettings
        case .unavailable:
            return .nothing
        }
    }

    func choose(_ appearance: Appearance) {
        self.appearance = appearance
    }
}
