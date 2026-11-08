import XCTest

/// Smoke test and accessibility audit of the Exercise detail sheet (docs/agents/testing.md, UI tests).
@MainActor
final class ExerciseDetailUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    private func openDetail(of id: String, in app: XCUIApplication) {
        let row = app.buttons["exercises.row.\(id)"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.staticTexts["detail.title"].waitForExistence(timeout: 5))
    }

    func testDetailOfBoxPassesAccessibilityAudit() throws {
        let app = launchApp()
        openDetail(of: "box", in: app)

        XCTAssertEqual(app.staticTexts["detail.title"].label, "Box breathing")
        XCTAssertEqual(app.staticTexts["detail.pattern"].label, "Inhale 4 · Hold 4 · Exhale 4 · Hold 4")
        XCTAssertTrue(app.buttons["detail.startButton"].exists)
        try app.performAccessibilityAudit()
    }

    func testChipsDifferPerExerciseAndTheDefaultIsSelected() {
        let app = launchApp()
        openDetail(of: "box", in: app)
        XCTAssertEqual(["60", "180", "300", "600"].map { app.buttons["detail.chip.\($0)"].exists }, [true, true, true, true])
        XCTAssertTrue(app.buttons["detail.chip.300"].isSelected)
        XCTAssertFalse(app.buttons["detail.chip.60"].isSelected)
        XCTAssertEqual(app.staticTexts["detail.result"].label, "19 Cycles · 5:04")
        app.buttons["detail.cancelButton"].tap()

        XCTAssertTrue(app.buttons["exercises.row.four-seven-eight"].waitForExistence(timeout: 5))
        openDetail(of: "four-seven-eight", in: app)
        XCTAssertEqual(["75", "120", "150"].map { app.buttons["detail.chip.\($0)"].exists }, [true, true, true])
        XCTAssertFalse(app.buttons["detail.chip.300"].exists)
        XCTAssertTrue(app.buttons["detail.chip.75"].isSelected)
        XCTAssertEqual(app.buttons["detail.chip.75"].label, "1 minute, 15 seconds")
    }

    func testChangingTheChipUpdatesTheResultLine() {
        let app = launchApp()
        openDetail(of: "box", in: app)

        app.buttons["detail.chip.60"].tap()

        XCTAssertTrue(app.buttons["detail.chip.60"].isSelected)
        XCTAssertFalse(app.buttons["detail.chip.300"].isSelected)
        XCTAssertEqual(app.staticTexts["detail.result"].label, "4 Cycles · 1:04")
    }

    func testChoicesResetToTheDefaultsEachTimeTheSheetOpens() {
        let app = launchApp()
        openDetail(of: "box", in: app)
        let haptics = app.switches["detail.hapticsToggle"]
        XCTAssertEqual(haptics.value as? String, "1")

        app.buttons["detail.chip.600"].tap()
        haptics.tap()
        XCTAssertEqual(haptics.value as? String, "0")
        app.buttons["detail.cancelButton"].tap()

        openDetail(of: "box", in: app)
        XCTAssertTrue(app.buttons["detail.chip.300"].isSelected)
        XCTAssertEqual(app.switches["detail.hapticsToggle"].value as? String, "1")
    }

    func testSafetyNoteShowsOnEveryExerciseWithTheHoldLineOnBoxAndFourSevenEight() {
        let app = launchApp()
        let holdLine = "If a hold feels too long"
        let expectations = [
            ("box", true), ("four-seven-eight", true), ("coherent", false), ("physiological-sigh", false),
        ]
        for (id, hasHoldLine) in expectations {
            XCTAssertTrue(app.buttons["exercises.row.\(id)"].waitForExistence(timeout: 5))
            openDetail(of: id, in: app)
            let note = app.staticTexts["detail.safetyNote"]
            XCTAssertTrue(note.exists, "\(id) shows the Safety note")
            XCTAssertTrue(note.label.contains("Stop and breathe normally if you feel dizzy"))
            XCTAssertEqual(note.label.contains(holdLine), hasHoldLine, id)
            app.buttons["detail.cancelButton"].tap()
        }
    }

    func testSafetyNoteComesBeforeStartInTheReadingOrder() {
        let app = launchApp()
        openDetail(of: "box", in: app)

        XCTAssertLessThan(app.staticTexts["detail.safetyNote"].frame.minY, app.buttons["detail.startButton"].frame.minY)
    }

    func testAtTheLargestTextSizeTheSheetPassesAccessibilityAuditAndScrollsToStart() throws {
        let app = launchApp(contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        openDetail(of: "four-seven-eight", in: app)

        // Audited before scrolling: a screenshot taken while the sheet still decelerates misreads the contrast.
        try app.performAccessibilityAudit()
        let start = app.buttons["detail.startButton"]
        for _ in 0 ..< 8 where !start.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(start.isHittable, "Start is reachable by scrolling")
        XCTAssertTrue(app.staticTexts["detail.safetyNote"].exists)
    }
}
