/// The progress ring around the shape: one Cycle of a Pattern laid out clockwise from the top.
///
/// Each Phase takes the share of the ring that its seconds take of the Cycle. The Kit decides the shares and
/// which parts are lit; the screen turns them into angles, strokes and colours.
public struct ProgressRing: Sendable, Hashable {
    /// The part of the ring one Phase takes.
    public struct Arc: Sendable, Hashable {
        public let kind: PhaseKind
        /// Where the arc starts and ends, as a fraction of the Cycle from the top, clockwise: 0 to 1.
        public let start: Double
        public let end: Double
        /// The one-second segments a hold or rest is drawn in, so it can be counted without a number.
        /// 0 for an inhale or exhale, which fill smoothly.
        public let segmentCount: Int
    }

    /// One arc per Phase of the Pattern, in order. The Phase at index `n` of the Pattern is `arcs[n]`.
    public let arcs: [Arc]

    public init(pattern: Pattern) {
        let cycle = pattern.phases.reduce(0.0) { $0 + $1.duration.seconds }
        var elapsed = 0.0
        arcs = pattern.phases.map { phase in
            let seconds = phase.duration.seconds
            let start = elapsed / cycle
            elapsed += seconds
            let isCounted = phase.kind == .hold || phase.kind == .rest
            return Arc(
                kind: phase.kind, start: start, end: elapsed / cycle,
                segmentCount: isCounted ? Int(seconds.rounded(.up)) : 0
            )
        }
    }
}

private extension Duration {
    var seconds: Double {
        Double(components.seconds) + Double(components.attoseconds) / 1e18
    }
}
