// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-parser-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Parser Primitives",
            targets: ["Parser Primitives"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-input-primitives"),
        .package(path: "../swift-effect-primitives"),
        // SDG(wraps): parsers wrap parse errors
        // .package(path: "../swift-error-primitives"),

        // SDG(produces): parsers produce abstract syntax tree nodes
        // .package(path: "../swift-abstract-syntax-tree-primitives"),
    ],
    targets: [
        .target(
            name: "Parser Primitives",
            dependencies: [
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Effect Primitives", package: "swift-effect-primitives")
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
