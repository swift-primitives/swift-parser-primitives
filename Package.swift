// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-parsing-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Parsing Primitives",
            targets: ["Parsing Primitives"]
        ),
        .library(
            name: "Parsing Machine",
            targets: ["Parsing Machine"]
        )
    ],
    dependencies: [
        .package(path: "../swift-container-primitives"),
        .package(path: "../swift-storage-primitives"),
        .package(path: "../swift-identity-primitives"),
        .package(path: "../swift-reference-primitives"),
        .package(path: "../swift-effect-primitives"),
        .package(path: "../swift-machine-primitives"),
        .package(path: "../../swift-foundations/swift-ascii")
    ],
    targets: [
        .target(
            name: "Parsing Primitives",
            dependencies: [
                .product(name: "Effect Primitives", package: "swift-effect-primitives")
            ]
        ),
        .target(
            name: "Parsing Machine",
            dependencies: [
                "Parsing Primitives",
                .product(name: "Container Primitives", package: "swift-container-primitives"),
                .product(name: "Storage Primitives", package: "swift-storage-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
                .product(name: "Reference Primitives", package: "swift-reference-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .strictMemorySafety()
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
