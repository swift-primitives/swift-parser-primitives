// swift-tools-version: 6.2

import PackageDescription

let settings: [SwiftSetting] = [
    .strictMemorySafety(),
]

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
        .library(
            name: "Parsing Machine",
            targets: ["Parsing Machine"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-test-primitives"),
        .package(path: "../swift-container-primitives"),
        .package(path: "../swift-storage-primitives"),
        .package(path: "../swift-identity-primitives"),
        .package(path: "../../swift-foundations/swift-ascii"),
    ],
    targets: [
        .target(
            name: "Parsing Primitives"
        ),
        .target(
            name: "Parsing Machine",
            dependencies: [
                "Parsing Primitives",
                .product(name: "Container Primitives", package: "swift-container-primitives"),
                .product(name: "Storage Primitives", package: "swift-storage-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
            ]
        ),
        .testTarget(
            name: "Parsing Primitives Tests",
            dependencies: [
                "Parsing Primitives",
                .product(name: "Test Primitives", package: "swift-test-primitives"),
            ]
        ),
        .testTarget(
            name: "Parsing Machine Tests",
            dependencies: [
                "Parsing Machine",
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "ASCII", package: "swift-ascii"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
