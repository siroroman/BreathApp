import BreathnestKit
import SwiftUI

/// The torus of dots that shows the Breath level (screen 13 of the design), drawn flat in a `Canvas`.
/// The geometry is `TorusShape`; this view maps the 200-unit board to its size and mixes the two dot colours.
struct TorusView: View {
    /// 0 through 1, from the engine's snapshot.
    let level: Double
    let reduceMotion: Bool

    @Environment(\.self) private var environment

    private static let boardSize: CGFloat = 200

    var body: some View {
        Canvas { context, size in
            let look = TorusShape.Look(level: level, reduceMotion: reduceMotion)
            let diameter = min(size.width, size.height)
            let unit = diameter / Self.boardSize
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let empty = Color(.dotEmpty).resolve(in: environment)
            let full = Color(.dotFull).resolve(in: environment)
            let base = Self.mix(empty, full, look.level)
            for dot in TorusShape.dots(for: look) {
                let radius = dot.radius * unit
                let rect = CGRect(
                    x: centre.x + dot.x * unit - radius, y: centre.y + dot.y * unit - radius,
                    width: radius * 2, height: radius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(Color(base).opacity(dot.opacity)))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        // The Phase is the title and the VoiceOver value; the shape is decoration.
        .accessibilityHidden(true)
    }

    /// Linear mix in sRGB, as the design does. The values are gamma-encoded sRGB, not the `linear*` ones,
    /// like the board.
    nonisolated static func mix(_ empty: Color.Resolved, _ full: Color.Resolved, _ level: Double) -> Color.Resolved {
        let t = Float(min(max(level, 0), 1))
        return Color.Resolved(
            red: empty.red * (1 - t) + full.red * t,
            green: empty.green * (1 - t) + full.green * t,
            blue: empty.blue * (1 - t) + full.blue * t,
            opacity: empty.opacity * (1 - t) + full.opacity * t
        )
    }
}
