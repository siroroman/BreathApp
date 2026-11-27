import BreathnestKit
import Foundation

/// A `HealthAccess` that records what it was asked to write. For tests and previews only.
@MainActor
public final class FakeHealthAccess: HealthAccess {
    public private(set) var state: HealthAccessState
    public private(set) var saved: [MindfulSession] = []
    public private(set) var requestCount = 0
    private let answer: HealthAccessState

    /// `answer` is what the system says when the person is asked.
    public init(state: HealthAccessState, answer: HealthAccessState = .allowed) {
        self.state = state
        self.answer = answer
    }

    public func requestAccess() async -> HealthAccessState {
        requestCount += 1
        if state == .notDetermined { state = answer }
        return state
    }

    public func saveMindfulSession(from start: Date, to end: Date) async {
        guard state == .allowed else { return }
        saved.append(MindfulSession(start: start, end: end))
    }
}
