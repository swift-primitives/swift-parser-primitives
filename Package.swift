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
        .library(
            name: "Parser Primitives Test Support",
            targets: ["Parser Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-input-primitives"),
        .package(path: "../swift-effect-primitives"),
        .package(path: "../swift-array-primitives"),
        .package(path: "../swift-buffer-primitives"),
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
                .product(name: "Effect Primitives", package: "swift-effect-primitives"),
                .product(name: "Array Primitives", package: "swift-array-primitives"),
            ]
        ),
        .target(
            name: "Parser Primitives Test Support",
            dependencies: [
                "Parser Primitives",
                .product(name: "Input Primitives Test Support", package: "swift-input-primitives"),
                .product(name: "Array Primitives", package: "swift-array-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Parser Primitives Tests",
            dependencies: [
                "Parser Primitives",
                "Parser Primitives Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
