import Foundation

/// Where one saved document's bytes live (ADR 0003). The app's adapters are a `UserDefaults` key and a file.
/// Synchronous on purpose: a document is a few kilobytes and has one writer.
public protocol DocumentStore: Sendable {
    /// `nil` means nothing is saved yet.
    func load() throws -> Data?
    /// Replaces the whole document.
    func save(_ data: Data) throws
    /// Keeps the current bytes under another name, so they are never overwritten.
    func setAside() throws
}

/// A small value that is saved as one JSON object with a `version` (ADR 0003, rule M1).
public protocol StoredDocument: Codable, Equatable, Sendable {
    static var defaultValue: Self { get }
    /// The version `encode(to:)` writes. A saved document with a newer one is unreadable (rule M4).
    static var currentVersion: Int { get }
}

/// What a load found (ADR 0003, rule F1).
public enum LoadOutcome: Sendable, Hashable {
    case loaded
    /// Nothing was saved yet.
    case empty
    /// The saved bytes were unreadable and were kept with `setAside()`.
    case recovered
    /// The store could not be read at all.
    case unavailable
}

/// One document and its store: reads it once, never fails, and writes on every `update` (ADR 0003, rules F1 to F8).
/// A write that fails keeps the value in memory. After an unreadable or unavailable load nothing is written until
/// the next launch, so bytes that could not be kept are never replaced.
@MainActor
public final class SavedDocument<Value: StoredDocument> {
    public private(set) var value: Value
    public let outcome: LoadOutcome
    private let store: any DocumentStore
    private var mayWrite: Bool

    public init(store: any DocumentStore) {
        self.store = store
        let data: Data?
        do {
            data = try store.load()
        } catch {
            value = Value.defaultValue
            outcome = .unavailable
            mayWrite = false
            return
        }
        guard let data else {
            value = Value.defaultValue
            outcome = .empty
            mayWrite = true
            return
        }
        if let decoded = Self.decode(data) {
            value = decoded
            outcome = .loaded
            mayWrite = true
        } else {
            value = Value.defaultValue
            outcome = .recovered
            mayWrite = (try? store.setAside()) != nil
        }
    }

    public func update(_ newValue: Value) {
        value = newValue
        guard mayWrite, let data = try? Self.encoder.encode(newValue) else { return }
        try? store.save(data)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static func decode(_ data: Data) -> Value? {
        let decoder = JSONDecoder()
        guard let header = try? decoder.decode(Header.self, from: data) else { return nil }
        if let version = header.version, version > Value.currentVersion { return nil }
        return try? decoder.decode(Value.self, from: data)
    }

    private struct Header: Decodable {
        let version: Int?

        enum CodingKeys: String, CodingKey { case version }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            version = try? container.decode(Int.self, forKey: .version)
        }
    }
}
