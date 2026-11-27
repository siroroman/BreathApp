import BreathnestKit
import HealthKit

/// Writes Mindful Minutes to Apple Health. The app only writes, it never reads Health data, so the one type it
/// asks to share is the mindful session category.
@MainActor
final class HealthKitAccess: HealthAccess {
    private let store = HKHealthStore()
    private let type = HKCategoryType(.mindfulSession)

    var state: HealthAccessState {
        Self.state(isAvailable: HKHealthStore.isHealthDataAvailable(), status: store.authorizationStatus(for: type))
    }

    /// The Settings row's state for what HealthKit reports. Only an explicit authorization is `allowed`.
    nonisolated static func state(isAvailable: Bool, status: HKAuthorizationStatus) -> HealthAccessState {
        guard isAvailable else { return .unavailable }
        switch status {
        case .sharingAuthorized: return .allowed
        case .sharingDenied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    /// The Mindful Minutes sample of one completed Session.
    nonisolated static func sample(from start: Date, to end: Date) -> HKCategorySample {
        HKCategorySample(
            type: HKCategoryType(.mindfulSession), value: HKCategoryValue.notApplicable.rawValue, start: start, end: end
        )
    }

    func requestAccess() async -> HealthAccessState {
        guard state == .notDetermined else { return state }
        try? await store.requestAuthorization(toShare: [type], read: [])
        return state
    }

    func saveMindfulSession(from start: Date, to end: Date) async {
        guard state == .allowed else { return }
        try? await store.save(Self.sample(from: start, to: end))
    }
}
