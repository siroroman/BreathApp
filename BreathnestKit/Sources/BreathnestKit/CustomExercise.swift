import Foundation

/// The icon the user picks for a custom Exercise. The names come from the String Catalog by raw value.
public enum CustomExerciseIcon: String, Sendable, Hashable, Codable, CaseIterable {
    case ring, moon, sun, leaf, wave, wind
}

/// A custom Exercise as it is saved (ADR 0003): an ID, the text the user typed and the Pattern as four
/// whole seconds. A hold of 0 s leaves its Phase out. The Duration options are derived, not stored.
public struct CustomExerciseRecord: Sendable, Hashable, Codable, Identifiable {
    /// The longest a single Phase can be, in seconds.
    public static let maximumSeconds = 30

    public let id: String
    public let name: String
    public let icon: CustomExerciseIcon
    public let description: String
    public let inhale: Int
    public let holdAfterInhale: Int
    public let exhale: Int
    public let holdAfterExhale: Int

    /// Returns `nil` when Inhale or Exhale is under 1 s, a Hold is negative or any Phase is over
    /// `maximumSeconds`. A new record gets a new ID unless one is given (a record read back).
    public init?(
        id: String = UUID().uuidString, name: String, icon: CustomExerciseIcon, description: String,
        inhale: Int, holdAfterInhale: Int, exhale: Int, holdAfterExhale: Int
    ) {
        let limit = 0 ... Self.maximumSeconds
        guard inhale >= 1, exhale >= 1,
              [inhale, holdAfterInhale, exhale, holdAfterExhale].allSatisfy(limit.contains)
        else { return nil }
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.inhale = inhale
        self.holdAfterInhale = holdAfterInhale
        self.exhale = exhale
        self.holdAfterExhale = holdAfterExhale
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard let record = try CustomExerciseRecord(
            id: values.decode(String.self, forKey: .id),
            name: values.decode(String.self, forKey: .name),
            icon: values.decode(CustomExerciseIcon.self, forKey: .icon),
            description: values.decode(String.self, forKey: .description),
            inhale: values.decode(Int.self, forKey: .inhale),
            holdAfterInhale: values.decode(Int.self, forKey: .holdAfterInhale),
            exhale: values.decode(Int.self, forKey: .exhale),
            holdAfterExhale: values.decode(Int.self, forKey: .holdAfterExhale)
        ) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Pattern out of range"
            ))
        }
        self = record
    }

    /// The Exercise to show and start.
    public var exercise: Exercise {
        let phases = [
            (PhaseKind.inhale, inhale), (.hold, holdAfterInhale), (.exhale, exhale), (.hold, holdAfterExhale),
        ]
        .filter { $0.1 > 0 }
        .map { Phase(kind: $0.0, duration: .seconds($0.1)) }
        return Exercise(
            id: id, pattern: Pattern(validated: phases),
            durationOptions: [.seconds(60), .seconds(180), .seconds(300), .seconds(600)],
            defaultDuration: .seconds(300)
        )
    }
}
