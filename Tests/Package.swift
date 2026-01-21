// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-parser-primitives-tests",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    dependencies: [
        // Parent package
        .package(path: "../"),
        // Testing framework
        .package(path: "../../../swift-foundations/swift-testing"),
        // Test primitives (for test utilities)
        .package(path: "../../swift-test-primitives"),
        // ASCII (for Parser Machine Tests)
        .package(path: "../../swift-ascii-primitives"),
    ],
    targets: [
        .testTarget(
            name: "Parser Primitives Tests",
            dependencies: [
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
            ],
            path: "Sources/Parser Primitives Tests"
        ),
        .testTarget(
            name: "Parser Machine Tests",
            dependencies: [
                .product(name: "Parser Machine", package: "swift-parser-primitives"),
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
            ],
            path: "Sources/Parser Machine Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
