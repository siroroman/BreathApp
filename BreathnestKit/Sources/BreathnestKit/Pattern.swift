/// The ordered, non-empty list of Phases that make up one Cycle of an Exercise.
public struct Pattern: Sendable, Hashable {
    public let phases: [Phase]

    /// Returns `nil` for an empty list or for any Phase whose duration is zero or less.
    public init?(phases: [Phase]) {
        guard !phases.isEmpty, phases.allSatisfy({ $0.duration > .zero }) else { return nil }
        self.init(validated: phases)
    }

    /// For data that is valid by construction, such as the built-in Exercises, which
    /// `ExerciseTests.patternIsValid` checks. Anything built at runtime uses `init?(phases:)`.
    init(validated phases: [Phase]) {
        self.phases = phases
    }

    /// The length of one Cycle: the sum of its Phase durations.
    public var cycleLength: Duration {
        phases.reduce(.zero) { $0 + $1.duration }
    }
}
