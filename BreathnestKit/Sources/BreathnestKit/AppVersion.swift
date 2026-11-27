/// The version line of the Settings sheet: "1.0 (1)", the marketing version and the build number.
public struct AppVersion: Equatable, Sendable {
    public let version: String?
    public let build: String?

    public init(version: String?, build: String?) {
        self.version = version
        self.build = build
    }

    public var display: String {
        let shown = version.flatMap { $0.isEmpty ? nil : $0 } ?? "–"
        guard let build, !build.isEmpty else { return shown }
        return "\(shown) (\(build))"
    }
}
