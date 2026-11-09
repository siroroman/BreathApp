import XCTest

/// Smoke test of a whole Session on the shortest Exercise (docs/agents/testing.md, UI tests). The DEBUG launch
/// argument speeds the Session up, so Lead-in, breathing and the end screen take seconds.
@MainActor
final class SessionUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testWholeSessionRunsFromStartToDone() {
        let app = launchApp(sessionSpeed: 20)
        app.buttons["exercises.row.box"].tap()
        let oneMinute = app.buttons["detail.chip.60"]
        XCTAssertTrue(oneMinute.waitForExistence(timeout: 5))
        oneMinute.tap()
        app.buttons["detail.startButton"].tap()

        XCTAssertTrue(app.buttons["session.pauseButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["session.stopButton"].exists)

        let done = app.buttons["session.doneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["session.completeTitle"].label, "Session complete")
        XCTAssertEqual(app.staticTexts["session.summary"].label, "Box breathing · 4 Cycles · 1:04")
        XCTAssertFalse(app.buttons["session.pauseButton"].exists)
        done.tap()

        XCTAssertTrue(app.staticTexts["detail.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["detail.chip.60"].isSelected)
    }

    func testStopReturnsToTheSheetWithNoEndScreen() {
        let app = launchApp()
        app.buttons["exercises.row.box"].tap()
        app.buttons["detail.startButton"].tap()
        XCTAssertEqual(app.staticTexts["session.title"].label, "Get ready")
        app.buttons["session.stopButton"].tap()

        XCTAssertTrue(app.staticTexts["detail.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["session.completeTitle"].exists)
        XCTAssertTrue(app.buttons["detail.chip.300"].isSelected)
    }
}
