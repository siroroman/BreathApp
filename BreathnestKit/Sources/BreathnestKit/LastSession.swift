/// The Exercise and length of the last Session that started. Saved in `UserDefaults` under
/// `breathnest.lastSession` (ADR 0003). The Haptics state is not part of it: the card shows the current setting.
public struct LastSession: StoredDocument {
    public var exerciseID: Exercise.ID
    /// The Duration option or length the user chose, not the rounded length of the Session.
    public var requested: Duration

    public init(exerciseID: Exercise.ID, requested: Duration) {
        self.exerciseID = exerciseID
        self.requested = requested
    }

    public static let defaultValue = LastSession(exerciseID: Exercise.box.id, requested: Exercise.box.defaultDuration)
    public static let currentVersion = 1

    private enum CodingKeys: String, CodingKey {
        case version, exerciseID, seconds
    }

    /// A missing or mistyped field takes its own default (rule F4); a length that is not a positive number too.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.defaultValue
        exerciseID = (try? container.decode(String.self, forKey: .exerciseID)) ?? defaults.exerciseID
        let seconds = (try? container.decode(Double.self, forKey: .seconds)).flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        requested = seconds.map { .seconds($0) } ?? defaults.requested
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentVersion, forKey: .version)
        try container.encode(exerciseID, forKey: .exerciseID)
        try container.encode(requested / .seconds(1), forKey: .seconds)
    }
}

/// What the Quick Start card offers and its Start button begins.
public struct QuickStart: Sendable, Hashable {
    public let exercise: Exercise
    public let requested: Duration
}

public extension LastSession {
    /// An Exercise ID that is not a built-in Exercise gives Box breathing at 5 min (rule F5).
    var quickStart: QuickStart {
        guard let exercise = Exercise.builtIn.first(where: { $0.id == exerciseID }) else {
            return QuickStart(exercise: .box, requested: Exercise.box.defaultDuration)
        }
        return QuickStart(exercise: exercise, requested: requested)
    }
}
