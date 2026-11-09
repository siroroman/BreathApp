import XCTest

/// Launches the app, optionally at a text size such as UICTContentSizeCategoryAccessibilityXXXL, in English with US
/// formats, so the tests read the same text on any simulator. The only
/// language with real text today is English (#34 adds the others).
@MainActor
func launchApp(contentSize: String? = nil, sessionSpeed: Int? = nil) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    if let contentSize {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", contentSize]
    }
    if let sessionSpeed {
        app.launchArguments += ["-SessionSpeed", "\(sessionSpeed)"]
    }
    app.launch()
    return app
}
