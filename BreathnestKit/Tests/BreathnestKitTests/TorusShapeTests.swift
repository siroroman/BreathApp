import Testing

@testable import BreathnestKit

@Suite struct TorusShapeTests {
    @Test func motionGrowsScaleTubeAndDotsWithTheBreathLevel() {
        let empty = TorusShape.Look(level: 0, reduceMotion: false)
        let half = TorusShape.Look(level: 0.5, reduceMotion: false)
        let full = TorusShape.Look(level: 1, reduceMotion: false)
        #expect(empty.scale == 0.64 && full.scale == 0.80)
        #expect(empty.tubeRatio == 0.42 && full.tubeRatio == 0.64)
        #expect(empty.dotRadius == 1.15 && full.dotRadius == 1.9)
        #expect(abs(half.scale - 0.72) < 1e-9)
        #expect(empty.opacityFactor == 1 && full.opacityFactor == 1)
    }

    @Test func reduceMotionKeepsTheSizeFixedAndLetsOpacityCarryTheLevel() {
        let empty = TorusShape.Look(level: 0, reduceMotion: true)
        let full = TorusShape.Look(level: 1, reduceMotion: true)
        #expect(empty.scale == 0.72 && full.scale == 0.72)
        #expect(empty.tubeRatio == 0.53 && full.tubeRatio == 0.53)
        #expect(empty.dotRadius == 1.7 && full.dotRadius == 1.7)
        #expect(empty.opacityFactor == 0.75 && full.opacityFactor == 1)
    }

    @Test func levelOutsideZeroToOneIsClamped() {
        #expect(TorusShape.Look(level: -1, reduceMotion: false) == TorusShape.Look(level: 0, reduceMotion: false))
        #expect(TorusShape.Look(level: 2, reduceMotion: true) == TorusShape.Look(level: 1, reduceMotion: true))
    }

    @Test func drawsAbout1700DotsBackToFront() {
        let dots = TorusShape.dots(for: TorusShape.Look(level: 0.5, reduceMotion: false))
        #expect(dots.count == TorusShape.dotCount)
        #expect((1600 ... 1800).contains(dots.count))
        #expect(zip(dots, dots.dropFirst()).allSatisfy { $0.depth <= $1.depth })
    }

    @Test func frontDotsAreLargerAndMoreOpaqueThanBackDots() throws {
        let dots = TorusShape.dots(for: TorusShape.Look(level: 0, reduceMotion: false))
        let back = try #require(dots.first)
        let front = try #require(dots.last)
        #expect(front.radius > back.radius)
        #expect(front.opacity > back.opacity)
        #expect(front.opacity <= 1 && back.opacity >= 0.45)
    }

    @Test func dotsStayInsideTheOuterRadiusOfTheBoard() {
        for level in [0.0, 0.5, 1] {
            let look = TorusShape.Look(level: level, reduceMotion: false)
            let outer = look.scale * 100
            let dots = TorusShape.dots(for: look)
            #expect(dots.allSatisfy { ($0.x * $0.x + $0.y * $0.y).squareRoot() <= outer + 1e-9 })
        }
    }

    @Test func tubeDepthFollowsTheBoardRule() throws {
        // Board: t = (sin v + 1) / 2, radius × (0.75 + 0.5 t), opacity 0.45 + 0.55 t.
        let look = TorusShape.Look(level: 0, reduceMotion: false)
        for dot in TorusShape.dots(for: look) {
            #expect(abs(dot.radius - look.dotRadius * (0.75 + 0.5 * dot.depth)) < 1e-9)
            #expect(abs(dot.opacity - (0.45 + 0.55 * dot.depth)) < 1e-9)
        }
    }

    @Test func reduceMotionScalesOpacityByTheLevel() throws {
        let dim = TorusShape.dots(for: TorusShape.Look(level: 0, reduceMotion: true))
        let bright = TorusShape.dots(for: TorusShape.Look(level: 1, reduceMotion: true))
        let front = try #require(bright.last)
        let dimFront = try #require(dim.last)
        #expect(abs(dimFront.opacity - front.opacity * 0.75) < 1e-9)
    }
}
