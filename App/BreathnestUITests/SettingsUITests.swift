import XCTest

/// Smoke test and accessibility audit of the Settings sheet (#60).
@MainActor
final class SettingsUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func openSettings(in app: XCUIApplication) {
        let gear = app.buttons["exercises.settingsButton"]
        XCTAssertTrue(gear.waitForExistence(timeout: 5))
        gear.tap()
        XCTAssertTrue(app.staticTexts["settings.title"].waitForExistence(timeout: 5))
    }

    func testSheetShowsTheFourRowsAndPassesTheAccessibilityAudit() throws {
        let app = launchApp()
        openSettings(in: app)

        XCTAssertEqual(app.buttons["settings.appearanceRow"].label, "Appearance, Aurora")
        XCTAssertTrue(app.buttons["settings.healthRow"].exists)
        XCTAssertTrue(app.buttons["settings.shareRow"].exists)
        let version = app.staticTexts["settings.versionRow"]
        XCTAssertTrue(version.exists)
        XCTAssertTrue(version.label.hasPrefix("Version, "))
        XCTAssertFalse(app.buttons["settings.versionRow"].exists)
        try app.performAccessibilityAudit()
    }

    func testAppearanceOpensAListWithAuroraChosenAndGoesBack() {
        let app = launchApp()
        openSettings(in: app)

        app.buttons["settings.appearanceRow"].tap()
        XCTAssertTrue(app.staticTexts["settings.appearanceTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.appearance.aurora"].isSelected)
        app.buttons["settings.backButton"].tap()
        XCTAssertTrue(app.staticTexts["settings.title"].waitForExistence(timeout: 5))
    }

    func testDoneClosesTheSheet() {
        let app = launchApp()
        openSettings(in: app)
        app.buttons["settings.doneButton"].tap()
        XCTAssertTrue(app.staticTexts["exercises.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["settings.title"].exists)
    }

    func testSheetPassesTheAuditAtTheLargestTextSize() throws {
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        openSettings(in: app)
        try app.performAccessibilityAudit()
    }
}
