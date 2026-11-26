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

    private func durationValue(in app: XCUIApplication) -> XCUIElement {
        app.buttons["detail.durationValue"]
    }

    func testDurationShowsOnlyTheNumberAndNoChipsSliderOrResultLine() {
        let app = launchApp()
        openDetail(of: "box", in: app)
        XCTAssertEqual(durationValue(in: app).value as? String, "5 minutes")
        XCTAssertFalse(app.buttons["detail.chip.300"].exists)
        XCTAssertFalse(app.sliders["detail.slider"].exists)
        XCTAssertFalse(app.staticTexts["detail.result"].exists)
        XCTAssertFalse(app.pickerWheels.firstMatch.exists)
    }

    func testTappingTheValueOpensThePickerAndPickingChangesIt() {
        let app = launchApp()
        openDetail(of: "box", in: app)

        durationValue(in: app).tap()
        let wheel = app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: 5))
        wheel.adjust(toPickerWheelValue: "12 min")

        XCTAssertEqual(durationValue(in: app).value as? String, "12 minutes")
        durationValue(in: app).tap()
        XCTAssertFalse(app.pickerWheels.firstMatch.waitForExistence(timeout: 1))
    }

    func testFourSevenEightCanPickTheSameRange() {
        let app = launchApp()
        openDetail(of: "four-seven-eight", in: app)
        XCTAssertEqual(durationValue(in: app).value as? String, "1 minute")
        durationValue(in: app).tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "30 min")
        XCTAssertEqual(durationValue(in: app).value as? String, "30 minutes")
    }

    func testDurationResetsAndHapticsAreKeptWhenTheSheetOpensAgain() {
        let app = launchApp()
        openDetail(of: "box", in: app)
        let haptics = app.switches["detail.hapticsToggle"]
        XCTAssertEqual(haptics.value as? String, "1")

        durationValue(in: app).tap()
        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "10 min")
        haptics.tap()
        XCTAssertEqual(haptics.value as? String, "0")
        app.buttons["detail.cancelButton"].tap()

        openDetail(of: "box", in: app)
        XCTAssertEqual(durationValue(in: app).value as? String, "5 minutes")
        // Haptics is a saved setting (ADR 0003), so it keeps the last choice.
        XCTAssertEqual(app.switches["detail.hapticsToggle"].value as? String, "0")
    }

    func testTheDetailSheetShowsNoSafetyNoteOnAnyExercise() {
        let app = launchApp()
        for id in ["box", "four-seven-eight", "coherent", "physiological-sigh"] {
            XCTAssertTrue(app.buttons["exercises.row.\(id)"].waitForExistence(timeout: 5))
            openDetail(of: id, in: app)
            XCTAssertTrue(app.buttons["detail.startButton"].waitForExistence(timeout: 5), id)
            XCTAssertFalse(app.staticTexts["detail.safetyNote"].exists, "\(id) shows no Safety note")
            app.buttons["detail.cancelButton"].tap()
        }
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
    }
}
