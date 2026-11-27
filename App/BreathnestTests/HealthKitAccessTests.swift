import BreathnestKit
import Foundation
import HealthKit
import Testing

@testable import Breathnest

@Suite struct HealthKitAccessTests {
    @Test func onlyAnExplicitAuthorizationIsAllowed() {
        #expect(HealthKitAccess.state(isAvailable: true, status: .sharingAuthorized) == .allowed)
        #expect(HealthKitAccess.state(isAvailable: true, status: .sharingDenied) == .denied)
        #expect(HealthKitAccess.state(isAvailable: true, status: .notDetermined) == .notDetermined)
    }

    @Test func aDeviceWithoutHealthDataIsUnavailableWhateverTheStatus() {
        for status in [HKAuthorizationStatus.sharingAuthorized, .sharingDenied, .notDetermined] {
            #expect(HealthKitAccess.state(isAvailable: false, status: status) == .unavailable)
        }
    }

    @Test func aCompletedSessionBecomesOneMindfulMinutesSample() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let end = start.addingTimeInterval(300)
        let sample = HealthKitAccess.sample(from: start, to: end)
        #expect(sample.categoryType == HKCategoryType(.mindfulSession))
        #expect(sample.startDate == start)
        #expect(sample.endDate == end)
    }
}
