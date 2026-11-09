import SwiftUI
import Testing

@testable import Breathnest

@Suite struct TorusViewTests {
    private let empty = Color.Resolved(red: 0.2, green: 0.4, blue: 0.6, opacity: 1)
    private let full = Color.Resolved(red: 1, green: 0.8, blue: 0, opacity: 1)

    @Test func levelZeroIsTheEmptyColourAndLevelOneTheFullColour() {
        #expect(TorusView.mix(empty, full, 0).red == empty.red)
        #expect(TorusView.mix(empty, full, 1).green == full.green)
    }

    @Test func theMiddleLevelIsTheMeanInSRGB() {
        let mid = TorusView.mix(empty, full, 0.5)
        #expect(abs(mid.red - 0.6) < 0.0001)
        #expect(abs(mid.green - 0.6) < 0.0001)
        #expect(abs(mid.blue - 0.3) < 0.0001)
    }

    @Test func aLevelOutsideZeroToOneIsClamped() {
        #expect(TorusView.mix(empty, full, 2).blue == full.blue)
        #expect(TorusView.mix(empty, full, -1).blue == empty.blue)
    }
}
