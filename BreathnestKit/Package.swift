// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BreathnestKit",
    platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26)],
    products: [
        .library(name: "BreathnestKit", targets: ["BreathnestKit"]),
    ],
    targets: [
        .target(name: "BreathnestKit", swiftSettings: [.treatAllWarnings(as: .error)]),
        .testTarget(name: "BreathnestKitTests", dependencies: ["BreathnestKit"], swiftSettings: [.treatAllWarnings(as: .error)]),
    ]
)
