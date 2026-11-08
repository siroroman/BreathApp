import XCTest

/// Launches the app in English with US formats, so the tests read the same text on any simulator. The only
/// language with real text today is English (#34 adds the others).
@MainActor
func launchApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    return app
}
