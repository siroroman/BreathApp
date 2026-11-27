import Foundation

/// Whether the app may write Mindful Minutes to Apple Health, as the Settings row shows it.
public enum HealthAccessState: Sendable, Equatable {
    /// The system has not asked yet.
    case notDetermined
    case allowed
    /// The person said no; only the iOS Settings app can change it.
    case denied
    /// This device has no Health data (an iPad, some simulators).
    case unavailable
}

/// A completed Session as Apple Health records it: a start and an end.
public struct MindfulSession: Sendable, Equatable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

/// The seam to Apple Health (ADR 0002). The app's adapter is HealthKit and writes the Mindful Minutes category;
/// the Kit only knows the states. `requestAccess` asks the system once and answers with the state after it.
/// `saveMindfulSession` writes only when access is allowed and never fails the caller.
@MainActor
public protocol HealthAccess {
    var state: HealthAccessState { get }
    func requestAccess() async -> HealthAccessState
    func saveMindfulSession(from start: Date, to end: Date) async
}
