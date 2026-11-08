/// How many whole Cycles a Session runs and how long they take together.
public struct SessionLength: Sendable, Hashable {
    public let cycleCount: Int
    /// The exact length of `cycleCount` Cycles, not the requested duration.
    public let totalLength: Duration
}

public extension Exercise {
    /// The Session length for a requested duration: the whole number of Cycles nearest to it,
    /// at least one, with a tie rounding up.
    func sessionLength(for requested: Duration) -> SessionLength {
        let cycleLength = pattern.cycleLength
        let nearest = (requested / cycleLength).rounded(.toNearestOrAwayFromZero)
        let cycleCount = max(1, Int(nearest))
        return SessionLength(cycleCount: cycleCount, totalLength: cycleLength * cycleCount)
    }
}
