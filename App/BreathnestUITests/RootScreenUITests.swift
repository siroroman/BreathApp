import XCTest

/// Smoke test and accessibility audit of the root screen. Each new screen adds its own test and audit
/// (docs/agents/testing.md, UI tests). XCTest, not Swift Testing: XCUIApplication is an XCTest API.
@MainActor
final class RootScreenUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testRootScreenPassesAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["placeholder.greeting"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
    }
}
