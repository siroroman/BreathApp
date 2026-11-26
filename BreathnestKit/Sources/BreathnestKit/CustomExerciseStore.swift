import Foundation

/// One saved document behind bytes (ADR 0003). The apps provide the adapter, a file or a `UserDefaults` key.
public protocol DocumentStore: Sendable {
    /// `nil`: nothing is saved yet.
    func load() throws -> Data?
    /// Replaces the whole document.
    func save(_ data: Data) throws
    /// Keeps the current bytes under another name.
    func setAside() throws
}

/// What happened when a document was read (ADR 0003, F1).
public enum LoadOutcome: Sendable, Hashable {
    case loaded, empty, recovered, unavailable
}

public struct CustomExerciseLoad: Sendable, Hashable {
    public let records: [CustomExerciseRecord]
    public let outcome: LoadOutcome
}

/// Reads and writes the list of custom Exercises as `{"version": 1, "items": [...]}`. Never throws: an unreadable
/// document is set aside (F3), a store that cannot be read is left alone (F8), a failed write is dropped (F6).
public final class CustomExerciseStore: @unchecked Sendable {
    public static let currentVersion = 1

    private struct Document: Codable {
        let version: Int
        let items: [CustomExerciseRecord]
    }

    private let backing: any DocumentStore
    private var isWritable = true

    public init(backing: any DocumentStore) {
        self.backing = backing
    }

    public func load() -> CustomExerciseLoad {
        let bytes: Data?
        do {
            bytes = try backing.load()
        } catch {
            isWritable = false
            return CustomExerciseLoad(records: [], outcome: .unavailable)
        }
        guard let bytes else { return CustomExerciseLoad(records: [], outcome: .empty) }
        if let document = try? JSONDecoder().decode(Document.self, from: bytes),
           document.version == Self.currentVersion
        {
            return CustomExerciseLoad(records: document.items, outcome: .loaded)
        }
        do {
            try backing.setAside()
        } catch {
            isWritable = false
        }
        return CustomExerciseLoad(records: [], outcome: .recovered)
    }

    public func save(_ records: [CustomExerciseRecord]) {
        guard isWritable else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(Document(version: Self.currentVersion, items: records)) else { return }
        try? backing.save(data)
    }
}
