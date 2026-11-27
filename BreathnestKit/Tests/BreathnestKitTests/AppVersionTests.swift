import BreathnestKit
import Testing

@Suite struct AppVersionTests {
    @Test func readsVersionAndBuildAsOneLine() {
        #expect(AppVersion(version: "1.0", build: "1").display == "1.0 (1)")
    }

    @Test func aMissingBuildShowsTheVersionAlone() {
        #expect(AppVersion(version: "1.2", build: nil).display == "1.2")
        #expect(AppVersion(version: "1.2", build: "").display == "1.2")
    }

    @Test func aMissingVersionShowsAPlaceholderDash() {
        #expect(AppVersion(version: nil, build: "7").display == "– (7)")
        #expect(AppVersion(version: nil, build: nil).display == "–")
    }
}
