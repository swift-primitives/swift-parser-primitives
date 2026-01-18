// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-parsing-primitives-tests",
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
        // ASCII (for Parsing Machine Tests)
        .package(path: "../../../swift-foundations/swift-ascii"),
    ],
    targets: [
        .testTarget(
            name: "Parsing Primitives Tests",
            dependencies: [
                .product(name: "Parsing Primitives", package: "swift-parsing-primitives"),
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
            ],
            path: "Sources/Parsing Primitives Tests"
        ),
        .testTarget(
            name: "Parsing Machine Tests",
            dependencies: [
                .product(name: "Parsing Machine", package: "swift-parsing-primitives"),
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "ASCII", package: "swift-ascii"),
            ],
            path: "Sources/Parsing Machine Tests"
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
