import XCTest

/// The Stats tab: the empty Log, then a completed Session adding one row and a stopped one adding none (#58).
@MainActor
final class StatsUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testStatsTabShowsAnEmptyWeekAndLogOnANewInstall() {
        let app = launchApp()
        app.buttons["tab.stats"].tap()
        XCTAssertTrue(app.staticTexts["stats.total"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["stats.total"].label, "0 min")
        XCTAssertTrue(app.staticTexts["stats.log.empty"].exists)
        // VoiceOver reads the two sections as one segmented control.
        XCTAssertTrue(app.segmentedControls.firstMatch.exists)
        XCTAssertEqual(app.otherElements.matching(identifier: "stats.log.row").count, 0)
        attach(app, "stats-empty")
    }

    func testACompletedSessionAddsOneRowAndAStoppedOneNone() {
        let app = launchApp(sessionSpeed: 20)
        app.buttons["exercises.row.box"].tap()
        app.buttons["detail.durationValue"].tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "1 min")
        app.buttons["detail.startButton"].tap()
        XCTAssertTrue(app.buttons["session.doneButton"].waitForExistence(timeout: 15))
        app.buttons["session.doneButton"].tap()
        XCTAssertTrue(app.staticTexts["detail.title"].waitForExistence(timeout: 5))

        app.buttons["detail.startButton"].tap()
        app.buttons["session.stopButton"].tap()
        XCTAssertTrue(app.staticTexts["detail.title"].waitForExistence(timeout: 5))
        app.buttons["detail.cancelButton"].tap()

        app.buttons["tab.stats"].tap()
        XCTAssertTrue(app.staticTexts["stats.total"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["stats.total"].label, "1 min")
        XCTAssertEqual(app.otherElements.matching(identifier: "stats.log.row").count, 1)
        XCTAssertFalse(app.staticTexts["stats.log.empty"].exists)
        attach(app, "stats-one-session")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
