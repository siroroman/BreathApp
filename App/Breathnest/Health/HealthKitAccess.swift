import BreathnestKit
import HealthKit

/// Writes Mindful Minutes to Apple Health. The app only writes, it never reads Health data, so the one type it
/// asks to share is the mindful session category.
@MainActor
final class HealthKitAccess: HealthAccess {
    private let store = HKHealthStore()
    private let type = HKCategoryType(.mindfulSession)

    var state: HealthAccessState {
        guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }
        switch store.authorizationStatus(for: type) {
        case .notDetermined: return .notDetermined
        case .sharingAuthorized: return .allowed
        case .sharingDenied: return .denied
        @unknown default: return .notDetermined
        }
    }

    func requestAccess() async -> HealthAccessState {
        guard state == .notDetermined else { return state }
        try? await store.requestAuthorization(toShare: [type], read: [])
        return state
    }

    func saveMindfulSession(from start: Date, to end: Date) async {
        guard state == .allowed else { return }
        let sample = HKCategorySample(
            type: type, value: HKCategoryValue.notApplicable.rawValue, start: start, end: end
        )
        try? await store.save(sample)
    }
}
