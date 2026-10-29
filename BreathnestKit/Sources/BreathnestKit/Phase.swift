/// What the user does during a Phase.
public enum PhaseKind: Sendable, Hashable, CaseIterable {
    case inhale
    case hold
    case exhale
    case rest
}

/// One step of a Pattern: a kind and a duration, which may be fractional.
public struct Phase: Sendable, Hashable {
    public let kind: PhaseKind
    public let duration: Duration

    public init(kind: PhaseKind, duration: Duration) {
        self.kind = kind
        self.duration = duration
    }
}
