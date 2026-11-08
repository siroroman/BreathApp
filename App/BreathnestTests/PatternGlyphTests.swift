import BreathnestKit
import Testing

@testable import Breathnest

@MainActor
@Suite struct PatternGlyphTests {
    @Test func boxIsFourEqualArcsAlternatingMovingAndHold() {
        let arcs = PatternGlyph.arcs(for: Exercise.box.pattern)
        #expect(arcs == [
            GlyphArc(startDegrees: 8, endDegrees: 82, isMoving: true),
            GlyphArc(startDegrees: 98, endDegrees: 172, isMoving: false),
            GlyphArc(startDegrees: 188, endDegrees: 262, isMoving: true),
            GlyphArc(startDegrees: 278, endDegrees: 352, isMoving: false),
        ])
    }

    @Test func arcsAreAsLongAsTheirPhase() {
        let arcs = PatternGlyph.arcs(for: Exercise.fourSevenEight.pattern)
        let spans = arcs.map { $0.endDegrees - $0.startDegrees + 16 }
        #expect(spans.count == 3)
        #expect(abs(spans[0] - 360 * 4 / 19) < 0.0001)
        #expect(abs(spans[1] - 360 * 7 / 19) < 0.0001)
        #expect(abs(spans[2] - 360 * 8 / 19) < 0.0001)
        #expect(arcs.map(\.isMoving) == [true, false, true])
    }

    @Test func everyPhaseOfTheSighAndCoherentMoves() {
        #expect(PatternGlyph.arcs(for: Exercise.physiologicalSigh.pattern).allSatisfy { $0.isMoving })
        #expect(PatternGlyph.arcs(for: Exercise.coherent.pattern).allSatisfy { $0.isMoving })
    }
}
