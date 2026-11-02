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

// Throwaway: passes on macOS (pre-push), fails on Linux, to show the Kit tests job turns red.
#if os(Linux)
    @Suite struct ThrowawayLinuxTests {
        @Test func failsOnLinux() {
            #expect(Bool(false))
        }
    }
#endif
