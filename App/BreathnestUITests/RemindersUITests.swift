import XCTest

/// Smoke test and accessibility audit of the Reminder section and the New reminder sheet. The section opens on its
/// own with `-ShowReminders` until the Stats tab hosts it (#58).
@MainActor
final class RemindersUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func launchReminders(contentSize: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ResetSavedData", "-ShowReminders"]
        if let contentSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize] }
        app.launch()
        XCTAssertTrue(app.buttons["reminders.addRow"].waitForExistence(timeout: 5))
        return app
    }

    func testSectionPassesAccessibilityAudit() throws {
        let app = launchReminders()
        XCTAssertTrue(app.staticTexts["reminders.footnote"].exists)
        try app.performAccessibilityAudit()
    }

    func testSheetPassesAccessibilityAuditAndTheRepeatSummaryFollowsTheDays() throws {
        let app = launchReminders()
        app.buttons["reminders.addRow"].tap()
        XCTAssertTrue(app.staticTexts["newReminder.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["newReminder.repeatSummary"].label, "Weekdays")
        app.buttons["newReminder.day.7"].tap()
        app.buttons["newReminder.day.1"].tap()
        app.buttons["newReminder.day.2"].tap()
        XCTAssertEqual(app.staticTexts["newReminder.repeatSummary"].label, "Tue, Wed, Thu, Fri, Sat, Sun")
        try app.performAccessibilityAudit()
    }
}
