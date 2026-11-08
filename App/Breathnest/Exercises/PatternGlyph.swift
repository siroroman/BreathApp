import BreathnestKit
import SwiftUI

/// One arc of the row glyph, in degrees clockwise from the top.
struct GlyphArc: Equatable {
    let startDegrees: Double
    let endDegrees: Double
    /// Inhale and exhale move (`ring`); a hold or a rest does not (`outline`).
    let isMoving: Bool
}

/// The 44 × 44 glyph of a Pattern in an Exercise row: a ring of arcs, one per Phase, as long as the Phase and
/// separated by 16° gaps. Decorative, so VoiceOver skips it.
struct PatternGlyph: View {
    let pattern: Pattern

    static let side: CGFloat = 44
    private static let radius: CGFloat = 17
    private static let lineWidth: CGFloat = 4
    private static let gapDegrees = 16.0

    static func arcs(for pattern: Pattern) -> [GlyphArc] {
        let total = pattern.cycleLength / .seconds(1)
        var start = 0.0
        return pattern.phases.map { phase in
            let span = 360 * (phase.duration / .seconds(1)) / total
            defer { start += span }
            return GlyphArc(
                startDegrees: start + gapDegrees / 2,
                endDegrees: start + span - gapDegrees / 2,
                isMoving: phase.kind == .inhale || phase.kind == .exhale
            )
        }
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for arc in Self.arcs(for: pattern) {
                var path = Path()
                path.addArc(
                    center: center,
                    radius: Self.radius,
                    startAngle: .degrees(arc.startDegrees - 90),
                    endAngle: .degrees(arc.endDegrees - 90),
                    clockwise: false
                )
                context.stroke(
                    path,
                    with: .color(arc.isMoving ? Color(.ring) : Color(.outline)),
                    style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round)
                )
            }
        }
        .frame(width: Self.side, height: Self.side)
        .accessibilityHidden(true)
    }
}
