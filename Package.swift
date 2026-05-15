// swift-tools-version: 6.3.1

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
        // MARK: - Namespace
        .library(
            name: "Parser Namespace",
            targets: ["Parser Namespace"]
        ),
        .library(
            name: "Parser Primitives",
            targets: ["Parser Primitives"]
        ),
        .library(
            name: "Parser Primitives Core",
            targets: ["Parser Primitives Core"]
        ),
        .library(
            name: "Parser Error Primitives",
            targets: ["Parser Error Primitives"]
        ),
        .library(
            name: "Parser Match Primitives",
            targets: ["Parser Match Primitives"]
        ),
        .library(
            name: "Parser EndOfInput Primitives",
            targets: ["Parser EndOfInput Primitives"]
        ),
        .library(
            name: "Parser Constraint Primitives",
            targets: ["Parser Constraint Primitives"]
        ),
        .library(
            name: "Parser OneOf Primitives",
            targets: ["Parser OneOf Primitives"]
        ),
        .library(
            name: "Parser Map Primitives",
            targets: ["Parser Map Primitives"]
        ),
        .library(
            name: "Parser FlatMap Primitives",
            targets: ["Parser FlatMap Primitives"]
        ),
        .library(
            name: "Parser Filter Primitives",
            targets: ["Parser Filter Primitives"]
        ),
        .library(
            name: "Parser Conditional Primitives",
            targets: ["Parser Conditional Primitives"]
        ),
        .library(
            name: "Parser Optional Primitives",
            targets: ["Parser Optional Primitives"]
        ),
        .library(
            name: "Parser Skip Primitives",
            targets: ["Parser Skip Primitives"]
        ),
        .library(
            name: "Parser Many Primitives",
            targets: ["Parser Many Primitives"]
        ),
        .library(
            name: "Parser Take Primitives",
            targets: ["Parser Take Primitives"]
        ),
        .library(
            name: "Parser Consume Primitives",
            targets: ["Parser Consume Primitives"]
        ),
        .library(
            name: "Parser Discard Primitives",
            targets: ["Parser Discard Primitives"]
        ),
        .library(
            name: "Parser Prefix Primitives",
            targets: ["Parser Prefix Primitives"]
        ),
        .library(
            name: "Parser First Primitives",
            targets: ["Parser First Primitives"]
        ),
        .library(
            name: "Parser Tracked Primitives",
            targets: ["Parser Tracked Primitives"]
        ),
        .library(
            name: "Parser Spanned Primitives",
            targets: ["Parser Spanned Primitives"]
        ),
        .library(
            name: "Parser Span Primitives",
            targets: ["Parser Span Primitives"]
        ),
        .library(
            name: "Parser Locate Primitives",
            targets: ["Parser Locate Primitives"]
        ),
        .library(
            name: "Parser Peek Primitives",
            targets: ["Parser Peek Primitives"]
        ),
        .library(
            name: "Parser Not Primitives",
            targets: ["Parser Not Primitives"]
        ),
        .library(
            name: "Parser Always Primitives",
            targets: ["Parser Always Primitives"]
        ),
        .library(
            name: "Parser Fail Primitives",
            targets: ["Parser Fail Primitives"]
        ),
        .library(
            name: "Parser Rest Primitives",
            targets: ["Parser Rest Primitives"]
        ),
        .library(
            name: "Parser End Primitives",
            targets: ["Parser End Primitives"]
        ),
        .library(
            name: "Parser Lazy Primitives",
            targets: ["Parser Lazy Primitives"]
        ),
        .library(
            name: "Parser Trace Primitives",
            targets: ["Parser Trace Primitives"]
        ),
        .library(
            name: "Parser Backtrack Primitives",
            targets: ["Parser Backtrack Primitives"]
        ),
        .library(
            name: "Parser Parse Primitives",
            targets: ["Parser Parse Primitives"]
        ),
        .library(
            name: "Parser Conformance Primitives",
            targets: ["Parser Conformance Primitives"]
        ),
        .library(
            name: "Parser Primitives Test Support",
            targets: ["Parser Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-either-primitives"),
        .package(url: "https://github.com/swift-primitives/swift-product-primitives.git", branch: "main"),
        .package(path: "../swift-input-primitives"),
        .package(path: "../swift-effect-primitives"),
        .package(path: "../swift-array-primitives"),
        .package(path: "../swift-text-primitives"),
    ],
    targets: [
        // MARK: - Namespace
        .target(
            name: "Parser Namespace",
            dependencies: []
        ),

        // MARK: - Core

        .target(
            name: "Parser Primitives Core",
            dependencies: [
                "Parser Namespace",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Array Primitives Core", package: "swift-array-primitives"),
                .product(name: "Array Dynamic Primitives", package: "swift-array-primitives"),
            ]
        ),

        // MARK: - Error & Match

        .target(
            name: "Parser Error Primitives",
            dependencies: [
                "Parser Primitives Core",
                .product(name: "Either Primitives", package: "swift-either-primitives"),
                .product(name: "Product Primitives", package: "swift-product-primitives"),
                .product(name: "Text Primitives", package: "swift-text-primitives"),
            ]
        ),
        .target(
            name: "Parser Match Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
            ]
        ),

        // MARK: - Input Errors

        .target(
            name: "Parser EndOfInput Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Constraint Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),

        // MARK: - Combinators

        .target(
            name: "Parser OneOf Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Map Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser FlatMap Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Filter Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Constraint Primitives",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Conditional Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Optional Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Skip Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Many Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Take Primitives",
            ]
        ),
        .target(
            name: "Parser Take Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
                "Parser Skip Primitives",
                "Parser Conditional Primitives",
                "Parser Optional Primitives",
                "Parser Always Primitives",
            ]
        ),

        // MARK: - Consumption

        .target(
            name: "Parser Consume Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Constraint Primitives",
            ]
        ),
        .target(
            name: "Parser Discard Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Constraint Primitives",
                "Parser Consume Primitives",
            ]
        ),

        // MARK: - Prefix

        .target(
            name: "Parser Prefix Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Constraint Primitives",
                "Parser Match Primitives",
            ]
        ),

        // MARK: - Element Access

        .target(
            name: "Parser First Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Match Primitives",
                "Parser EndOfInput Primitives",
            ]
        ),

        // MARK: - Position Tracking

        .target(
            name: "Parser Tracked Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Spanned Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Span Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
                "Parser Tracked Primitives",
                "Parser Spanned Primitives",
            ]
        ),
        .target(
            name: "Parser Locate Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Error Primitives",
                "Parser Tracked Primitives",
            ]
        ),

        // MARK: - Lookahead

        .target(
            name: "Parser Peek Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Not Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Match Primitives",
            ]
        ),

        // MARK: - Terminals

        .target(
            name: "Parser Always Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Fail Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Rest Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser End Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Match Primitives",
            ]
        ),

        // MARK: - Utilities

        .target(
            name: "Parser Lazy Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Trace Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),
        .target(
            name: "Parser Backtrack Primitives",
            dependencies: [
                "Parser Primitives Core",
                .product(name: "Effect Primitives", package: "swift-effect-primitives"),
            ]
        ),
        .target(
            name: "Parser Parse Primitives",
            dependencies: [
                "Parser Primitives Core",
            ]
        ),

        // MARK: - Concrete Parsers

        .target(
            name: "Parser Conformance Primitives",
            dependencies: [
                "Parser Primitives Core",
                "Parser Match Primitives",
            ]
        ),
        // MARK: - Umbrella

        .target(
            name: "Parser Primitives",
            dependencies: [
                "Parser Namespace",
                "Parser Primitives Core",
                "Parser Error Primitives",
                "Parser Match Primitives",
                "Parser EndOfInput Primitives",
                "Parser Constraint Primitives",
                "Parser OneOf Primitives",
                "Parser Map Primitives",
                "Parser FlatMap Primitives",
                "Parser Filter Primitives",
                "Parser Conditional Primitives",
                "Parser Optional Primitives",
                "Parser Skip Primitives",
                "Parser Many Primitives",
                "Parser Take Primitives",
                "Parser Consume Primitives",
                "Parser Discard Primitives",
                "Parser Prefix Primitives",
                "Parser First Primitives",
                "Parser Tracked Primitives",
                "Parser Spanned Primitives",
                "Parser Span Primitives",
                "Parser Locate Primitives",
                "Parser Peek Primitives",
                "Parser Not Primitives",
                "Parser Always Primitives",
                "Parser Fail Primitives",
                "Parser Rest Primitives",
                "Parser End Primitives",
                "Parser Lazy Primitives",
                "Parser Trace Primitives",
                "Parser Backtrack Primitives",
                "Parser Parse Primitives",
                "Parser Conformance Primitives",
            ]
        ),

        // MARK: - Tests

        .target(
            name: "Parser Primitives Test Support",
            dependencies: [
                "Parser Primitives",
                .product(name: "Input Primitives Test Support", package: "swift-input-primitives"),
                .product(name: "Array Primitives Test Support", package: "swift-array-primitives"),
            ],
            path: "Tests/Support"
        ),

        .testTarget(
            name: "Parser Always Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Consume Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser End Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Error Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Fail Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Filter Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser First Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser FlatMap Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Many Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Map Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Not Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser OneOf Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Optional Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Peek Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Prefix Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Rest Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Spanned Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Take Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
        ),
        .testTarget(
            name: "Parser Invariant Primitives Tests",
            dependencies: ["Parser Primitives Test Support"]
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
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
