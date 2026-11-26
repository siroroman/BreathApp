import BreathnestKit
import Foundation
import Synchronization

/// A `DocumentStore` in memory that can fail on demand. For tests and previews only.
public final class InMemoryDocumentStore: DocumentStore {
    private struct State {
        var data: Data?
        var saveCount = 0
        var setAsideData: [Data] = []
        var failsLoad = false
        var failsSave = false
        var failsSetAside = false
    }

    private struct Failure: Error {}

    private let state: Mutex<State>

    public init(_ data: Data? = nil) {
        state = Mutex(State(data: data))
    }

    public var saveCount: Int { state.withLock { $0.saveCount } }
    /// The bytes `setAside()` kept, oldest first.
    public var setAsideData: [Data] { state.withLock { $0.setAsideData } }
    public var failsLoad: Bool {
        get { state.withLock { $0.failsLoad } }
        set { state.withLock { $0.failsLoad = newValue } }
    }

    public var failsSave: Bool {
        get { state.withLock { $0.failsSave } }
        set { state.withLock { $0.failsSave = newValue } }
    }

    public var failsSetAside: Bool {
        get { state.withLock { $0.failsSetAside } }
        set { state.withLock { $0.failsSetAside = newValue } }
    }

    public func load() throws -> Data? {
        try state.withLock { state in
            if state.failsLoad { throw Failure() }
            return state.data
        }
    }

    public func save(_ data: Data) throws {
        try state.withLock { state in
            if state.failsSave { throw Failure() }
            state.data = data
            state.saveCount += 1
        }
    }

    public func setAside() throws {
        try state.withLock { state in
            if state.failsSetAside { throw Failure() }
            if let data = state.data { state.setAsideData.append(data) }
        }
    }
}
