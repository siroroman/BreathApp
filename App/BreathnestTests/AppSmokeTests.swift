import BreathnestKit
import Testing

@testable import Breathnest

@Suite struct AppSmokeTests {
    @Test func appLinksTheKit() {
        #expect(Placeholder().greeting.isEmpty == false)
    }
}
