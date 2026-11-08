import XCTest

/// Smoke test and accessibility audit of the Exercises list (docs/agents/testing.md, UI tests).
@MainActor
final class ExercisesScreenUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testExercisesListShowsTheFourExercisesInOrderAndPassesAccessibilityAudit() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["exercises.title"].waitForExistence(timeout: 5))
        let ids = ["box", "four-seven-eight", "coherent", "physiological-sigh"]
        let rows = ids.map { app.buttons["exercises.row.\($0)"] }
        for row in rows {
            XCTAssertTrue(row.exists)
        }
        let tops = rows.map(\.frame.minY)
        XCTAssertEqual(tops, tops.sorted(), "the rows are in the order of the list")
        try app.performAccessibilityAudit()
    }

    func testRowIsReadAsOneElementWithItsPhases() {
        let app = launchApp()
        let row = app.buttons["exercises.row.box"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertEqual(row.label, "Box breathing, inhale 4 seconds, hold 4 seconds, exhale 4 seconds, hold 4 seconds")
        // XCUITest cannot read a hint: its text is checked in ExerciseTextTests.
    }

    func testAppStaysInPortrait() {
        let app = launchApp()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        XCTAssertTrue(app.staticTexts["exercises.title"].waitForExistence(timeout: 5))
        let frame = app.windows.firstMatch.frame
        XCTAssertGreaterThan(frame.height, frame.width)
    }
}
