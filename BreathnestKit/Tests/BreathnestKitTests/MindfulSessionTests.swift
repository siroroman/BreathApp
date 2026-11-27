import BreathnestKit
import BreathnestKitTesting
import Foundation
import Testing

@MainActor
@Suite struct MindfulSessionTests {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    @Test func aCompletedSessionIsWrittenWhenAccessIsAllowed() async {
        let health = FakeHealthAccess(state: .allowed)
        await health.saveMindfulSession(from: start, to: start.addingTimeInterval(300))
        #expect(health.saved == [MindfulSession(start: start, end: start.addingTimeInterval(300))])
    }

    @Test func nothingIsWrittenWhenAccessIsNotAllowed() async {
        for state in [HealthAccessState.notDetermined, .denied, .unavailable] {
            let health = FakeHealthAccess(state: state)
            await health.saveMindfulSession(from: start, to: start.addingTimeInterval(300))
            #expect(health.saved.isEmpty)
        }
    }

    @Test func requestingAccessMovesAnUndecidedStateToTheAnswer() async {
        let allowed = FakeHealthAccess(state: .notDetermined, answer: .allowed)
        #expect(await allowed.requestAccess() == .allowed)
        #expect(allowed.state == .allowed)
        let denied = FakeHealthAccess(state: .notDetermined, answer: .denied)
        #expect(await denied.requestAccess() == .denied)
    }

    @Test func requestingAccessAfterAnAnswerKeepsIt() async {
        let health = FakeHealthAccess(state: .denied, answer: .allowed)
        #expect(await health.requestAccess() == .denied)
    }
}
