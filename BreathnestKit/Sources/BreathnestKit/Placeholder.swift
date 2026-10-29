import Foundation

/// Proves the build, test and run loop works. Replaced by the real Kit types (#23 to #26).
public struct Placeholder: Equatable, Sendable {
    public let name: String

    public init(name: String = "Breathnest") {
        self.name = name
    }

    public var greeting: String {
        "Breathe with \(name)"
    }
}
