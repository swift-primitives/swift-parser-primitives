// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-parsing-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Parsing Primitives",
            targets: ["Parsing Primitives"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-test-primitives.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: "Parsing Primitives"
        ),
        .testTarget(
            name: "Parsing Primitives Tests",
            dependencies: [
                "Parsing Primitives",
                .product(name: "Test Primitives", package: "swift-test-primitives"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
