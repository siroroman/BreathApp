import Foundation

/// The geometry of the torus of dots that shows the Breath level.
///
/// Pure values on the board of `ShapesDark.dc.html`: a 200 by 200 square centred on (0, 0), the torus
/// seen straight on. The view maps the board to points, picks the colours and draws the dots in order.
public enum TorusShape {
    /// Dots in the ring of the shape. The board draws 620, the app about 1,700.
    public static let dotCount = 1700

    /// The size and brightness of the shape at one Breath level.
    public struct Look: Equatable, Sendable {
        /// Outer radius of the torus as a fraction of the half-width of the board.
        public let scale: Double
        /// Tube radius as a fraction of the ring radius.
        public let tubeRatio: Double
        /// Dot radius in board units, before the depth rule.
        public let dotRadius: Double
        /// Factor for the opacity of every dot (1 with motion).
        public let opacityFactor: Double
        /// The Breath level, clamped to 0 through 1. It is also the mix between the two dot colours.
        public let level: Double

        /// With `reduceMotion` the size is fixed and the level shows in the opacity and the colour.
        public init(level: Double, reduceMotion: Bool) {
            let level = min(max(level, 0), 1)
            self.level = level
            if reduceMotion {
                scale = 0.72
                tubeRatio = 0.53
                dotRadius = 1.7
                opacityFactor = Self.mix(0.75, 1, level)
            } else {
                scale = Self.mix(0.64, 0.80, level)
                tubeRatio = Self.mix(0.42, 0.64, level)
                dotRadius = Self.mix(1.15, 1.9, level)
                opacityFactor = 1
            }
        }

        private static func mix(_ empty: Double, _ full: Double, _ level: Double) -> Double {
            empty * (1 - level) + full * level
        }
    }

    /// One dot, ready to draw.
    public struct Dot: Equatable, Sendable {
        /// Centre in board units, (0, 0) at the middle.
        public let x: Double
        public let y: Double
        /// 0 at the back of the tube, 1 at the front.
        public let depth: Double
        /// Radius in board units, bigger at the front.
        public let radius: Double
        /// 0 through 1, fainter at the back.
        public let opacity: Double
    }

    /// The dots for `look`, back to front, so drawing them in order puts the front dots on top.
    public static func dots(for look: Look) -> [Dot] {
        let ringRadius = look.scale * 100 / (1 + look.tubeRatio)
        let tubeRadius = look.tubeRatio * ringRadius
        return sortedAngles.map { angles in
            let rho = ringRadius + tubeRadius * cos(angles.v)
            return Dot(
                x: rho * cos(angles.u),
                y: rho * sin(angles.u),
                depth: angles.depth,
                radius: look.dotRadius * (0.75 + 0.5 * angles.depth),
                opacity: (0.45 + 0.55 * angles.depth) * look.opacityFactor
            )
        }
    }

    private struct Angles {
        let u: Double
        let v: Double
        let depth: Double
    }

    /// The angles of every dot, back to front. The depth depends only on the angle round the tube,
    /// so the order is the same at every level and is worked out once.
    private static let sortedAngles: [Angles] = (1 ... dotCount)
        .map { index in
            let u = (Double(index) * 0.6180339887).truncatingRemainder(dividingBy: 1) * 2 * .pi
            let v = (Double(index) * 0.7548776662).truncatingRemainder(dividingBy: 1) * 2 * .pi
            return Angles(u: u, v: v, depth: (sin(v) + 1) / 2)
        }
        .sorted { $0.depth < $1.depth }
}
