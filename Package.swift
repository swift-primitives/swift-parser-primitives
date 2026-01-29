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
            name: "Parser Machine",
            targets: ["Parser Machine"]
        ),
        .library(
            name: "Binary Parser Primitives",
            targets: ["Binary Parser Primitives"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-input-primitives"),
        .package(path: "../swift-stack-primitives"),
        .package(path: "../swift-slab-primitives"),
        .package(path: "../swift-identity-primitives"),
        .package(path: "../swift-ownership-primitives"),
        .package(path: "../swift-effect-primitives"),
        .package(path: "../swift-machine-primitives"),
        .package(path: "../swift-ascii-primitives"),
        .package(path: "../swift-binary-primitives"),
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
        .target(
            name: "Parser Machine",
            dependencies: [
                "Parser Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Slab Primitives", package: "swift-slab-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives")
            ]
        ),
        .target(
            name: "Binary Parser Primitives",
            dependencies: [
                "Parser Primitives",
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Machine Primitives", package: "swift-machine-primitives"),
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
