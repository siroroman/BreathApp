import BreathnestKit
import SwiftUI

/// The progress ring around the shape (screen 1 of the design): one Cycle clockwise from the top, a lit `ring`
/// over an unlit `track`. The Kit decides the arcs and what is lit; this draws them. It looks the same with
/// Reduce Motion on, and it is decoration: the Phase title and the VoiceOver value carry the Phase.
///
/// Lives in the app target until the `BreathnestUI` package exists; it moves there then (#29, #44).
struct ProgressRingView: View {
    let ring: ProgressRing
    let fills: [ProgressRing.ArcFill]

    /// The design draws the ring on a 300 box with radius 140 and stroke 8; every size scales with the box.
    private static let designBox = 300.0
    private static let designRadius = 140.0
    private static let designStroke = 8.0
    /// Degrees taken off each end of an arc, and off each end of a hold or rest segment.
    private static let arcTrim = 4.0
    private static let segmentTrim = 1.6

    var body: some View {
        Canvas { context, size in
            let scale = size.width / Self.designBox
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = Self.designRadius * scale
            let style = StrokeStyle(lineWidth: Self.designStroke * scale, lineCap: .round)
            func stroke(_ from: Double, _ to: Double, lit: Bool) {
                var path = Path()
                path.addArc(
                    center: center, radius: radius, startAngle: .degrees(from - 90), endAngle: .degrees(to - 90),
                    clockwise: false
                )
                context.stroke(path, with: .color(lit ? Color(.ring) : Color(.track)), style: style)
            }
            for (arc, fill) in zip(ring.arcs, fills) {
                let from = arc.start * 360 + Self.arcTrim
                let to = arc.end * 360 - Self.arcTrim
                switch fill {
                case let .fraction(share):
                    stroke(from, to, lit: false)
                    if share > 0.01 { stroke(from, from + (to - from) * share, lit: true) }
                case let .segments(litCount):
                    let width = (to - from) / Double(arc.segmentCount)
                    for index in 0 ..< arc.segmentCount {
                        stroke(
                            from + Double(index) * width + Self.segmentTrim,
                            from + Double(index + 1) * width - Self.segmentTrim,
                            lit: index < litCount
                        )
                    }
                }
            }
        }
        .accessibilityHidden(true)
        .accessibilityIdentifier("session.ring")
    }
}
