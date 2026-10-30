import Synchronization

/// A clock the test advances by hand, so a 10 minute Session runs in microseconds (see docs/agents/testing.md).
final class ManualClock: Clock, Sendable {
    struct Instant: InstantProtocol {
        var offset: Duration

        func advanced(by duration: Duration) -> Instant {
            Instant(offset: offset + duration)
        }

        func duration(to other: Instant) -> Duration {
            other.offset - offset
        }

        static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    private struct Sleeper {
        let deadline: Instant
        let continuation: CheckedContinuation<Void, Never>
    }

    private struct State {
        var now = Instant(offset: .zero)
        var sleepers: [Sleeper] = []
    }

    private let state = Mutex(State())

    var now: Instant {
        state.withLock { $0.now }
    }

    var minimumResolution: Duration {
        .zero
    }

    var sleeperCount: Int {
        state.withLock { $0.sleepers.count }
    }

    func sleep(until deadline: Instant, tolerance _: Duration? = nil) async throws {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let alreadyDue = state.withLock { state -> Bool in
                if deadline <= state.now { return true }
                state.sleepers.append(Sleeper(deadline: deadline, continuation: continuation))
                return false
            }
            if alreadyDue { continuation.resume() }
        }
    }

    /// Moves time forward and wakes every sleeper whose deadline has passed.
    func advance(by duration: Duration) {
        let due = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.now = state.now.advanced(by: duration)
            let now = state.now
            let due = state.sleepers.filter { $0.deadline <= now }
            state.sleepers.removeAll { $0.deadline <= now }
            return due.map(\.continuation)
        }
        for continuation in due {
            continuation.resume()
        }
    }

    /// Lets a test wait until its task is really asleep, so `advance` cannot run before the deadline is set.
    func waitForSleepers(_ count: Int) async {
        while sleeperCount < count {
            await Task.yield()
        }
    }
}
