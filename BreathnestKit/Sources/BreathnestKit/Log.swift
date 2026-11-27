import Foundation

/// One Session in the Log (ADR 0003): written when a Session completes. Keeps a copy of what its row needs, so
/// editing or deleting a custom Exercise never changes an old row.
public struct LogEntry: Sendable, Hashable, Codable, Identifiable {
    public let id: String
    public let exerciseID: Exercise.ID
    /// An instant. The day it falls on is worked out with the device's calendar when it is shown.
    public let finishedAt: Date
    /// The exact length of the Session, not the requested duration.
    public let length: Duration
    public let pattern: Pattern
    /// The name the user typed, only for a custom Exercise. A built-in Exercise is named from its ID.
    public let customName: String?

    public init(
        id: String = UUID().uuidString, exerciseID: Exercise.ID, finishedAt: Date, length: Duration,
        pattern: Pattern, customName: String?
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.finishedAt = finishedAt
        self.length = length
        self.pattern = pattern
        self.customName = customName
    }

    private struct PhaseRecord: Codable {
        let kind: String
        let seconds: Double
    }

    private enum CodingKeys: String, CodingKey {
        case id, exerciseID, finishedAt, length, pattern, customName
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        exerciseID = try values.decode(String.self, forKey: .exerciseID)
        finishedAt = try values.decode(Date.self, forKey: .finishedAt)
        length = try .seconds(values.decode(Double.self, forKey: .length))
        let records = try values.decode([PhaseRecord].self, forKey: .pattern)
        let phases = try records.map { record -> Phase in
            guard let kind = Self.kinds[record.kind] else {
                throw DecodingError.dataCorruptedError(
                    forKey: .pattern, in: values, debugDescription: "Unknown Phase kind"
                )
            }
            return Phase(kind: kind, duration: .seconds(record.seconds))
        }
        guard let pattern = Pattern(phases: phases) else {
            throw DecodingError.dataCorruptedError(forKey: .pattern, in: values, debugDescription: "Empty Pattern")
        }
        self.pattern = pattern
        customName = try values.decodeIfPresent(String.self, forKey: .customName)
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(exerciseID, forKey: .exerciseID)
        try values.encode(finishedAt, forKey: .finishedAt)
        try values.encode(length / .seconds(1), forKey: .length)
        try values.encode(
            pattern.phases.map { PhaseRecord(kind: Self.name(of: $0.kind), seconds: $0.duration / .seconds(1)) },
            forKey: .pattern
        )
        try values.encodeIfPresent(customName, forKey: .customName)
    }

    private static let kinds: [String: PhaseKind] = Dictionary(
        uniqueKeysWithValues: PhaseKind.allCases.map { (name(of: $0), $0) }
    )

    private static func name(of kind: PhaseKind) -> String {
        switch kind {
        case .inhale: "inhale"
        case .hold: "hold"
        case .exhale: "exhale"
        case .rest: "rest"
        }
    }
}

/// The Log as one saved document, `log.json` (ADR 0003): `{"version": 1, "items": [...]}`.
public struct Log: StoredDocument {
    public private(set) var entries: [LogEntry]

    public init(entries: [LogEntry]) {
        self.entries = entries
    }

    public static let defaultValue = Log(entries: [])
    public static let currentVersion = 1

    public mutating func append(_ entry: LogEntry) {
        entries.append(entry)
    }

    /// The rows of the Log, newest first. Ties keep the later written entry first.
    public var newestFirst: [LogEntry] {
        entries.enumerated()
            .sorted { ($0.element.finishedAt, $0.offset) > ($1.element.finishedAt, $1.offset) }
            .map(\.element)
    }

    private enum CodingKeys: String, CodingKey {
        case version, items
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        entries = try values.decode([LogEntry].self, forKey: .items)
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(Self.currentVersion, forKey: .version)
        try values.encode(entries, forKey: .items)
    }
}
