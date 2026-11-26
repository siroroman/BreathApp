import XCTest

/// Smoke test and accessibility audit of the New exercise sheet.
@MainActor
final class NewExerciseUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func openSheet() -> XCUIApplication {
        let app = launchApp()
        let row = app.buttons["exercises.customRow"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.staticTexts["newExercise.title"].waitForExistence(timeout: 5))
        return app
    }

    func testSheetPassesAccessibilityAudit() throws {
        let app = openSheet()
        try app.performAccessibilityAudit()
    }

    func testAddIsDisabledWithoutANameAndTheSummaryFollowsThePattern() {
        let app = openSheet()
        XCTAssertFalse(app.buttons["newExercise.addButton"].isEnabled)
        XCTAssertTrue(app.staticTexts["newExercise.summary"].label.contains("8 s"))
        app.buttons["newExercise.increase.holdAfterInhale"].tap()
        XCTAssertTrue(app.staticTexts["newExercise.summary"].label.contains("9 s"))
        XCTAssertEqual(app.buttons["newExercise.increase.holdAfterInhale"].label, "Increase hold after inhale")
    }

    func testSavingAddsARowThatOpensItsDetail() {
        let app = openSheet()
        let field = app.textFields["newExercise.nameField"]
        field.tap()
        field.typeText("Evening calm")
        app.buttons["newExercise.addButton"].tap()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Evening calm'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.staticTexts["detail.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["detail.title"].label, "Evening calm")
    }
}
