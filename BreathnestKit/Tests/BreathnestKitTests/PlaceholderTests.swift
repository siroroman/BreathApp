import Testing

@testable import BreathnestKit

@Suite struct PlaceholderTests {
    @Test func greetsByName() {
        #expect(Placeholder(name: "Box").greeting == "Breathe with Box")
    }

    @Test func defaultsToProductName() {
        #expect(Placeholder().name == "Breathnest")
    }
}
