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
            name: "Parser Primitive",
            targets: ["Parser Primitive"]
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
            name: "Parser Remaining Primitives",
            targets: ["Parser Remaining Primitives"]
        ),
        .library(
            name: "Parser Tagged Primitives",
            targets: ["Parser Tagged Primitives"]
        ),
        // MARK: - Witness (closure-backed leaf conformer)
        .library(
            name: "Parser Witness Primitives",
            targets: ["Parser Witness Primitives"]
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
            name: "Parser Pair Primitives",
            targets: ["Parser Pair Primitives"]
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
        .package(url: "https://github.com/swift-primitives/swift-either-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-pair-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-product-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-input-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-array-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-collection-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-text-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-iterator-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Namespace
        .target(
            name: "Parser Primitive",
            dependencies: []
        ),

        // MARK: - Core (DEPRECATED transitional shim — L1 core-dissolution sweep 2026-06-23)
        // Exports-only re-export of the dissolved Core surface (root + the
        // Remaining/Tagged sub-namespaces that received relocated decls + the
        // funneled Array / Collection / Input / Sequence modules). Removed in
        // the cleanup wave once consumers repoint to the umbrella / root.

        .target(
            name: "Parser Primitives Core",
            dependencies: [
                "Parser Primitive",
                "Parser Remaining Primitives",
                "Parser Tagged Primitives",
                "Parser Witness Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Array Primitives", package: "swift-array-primitives"),
            ]
        ),

        // MARK: - Relocated Core content (external-dep-bearing sub-namespaces)

        .target(
            name: "Parser Remaining Primitives",
            dependencies: [
                "Parser Primitive",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
            ]
        ),
        .target(
            name: "Parser Tagged Primitives",
            dependencies: [
                "Parser Primitive",
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),

        // MARK: - Witness (closure-backed leaf conformer)
        // Hosted in its OWN target (NOT in "Parser Primitive") so the module that
        // DEFINES Parser.Protocol contains no `Body == Never` conformer. With an
        // in-defining-module leaf conformer present, the `@inlinable` leaf-default
        // `var body: Never` `read` accessor is serialized into Parser_Primitive and
        // re-emitted BODYLESS into every consumer module conforming a `Body == Never`
        // type (Trace, Lazy, Parse, …) — a SIL-verification crash on Windows (+Asserts),
        // Embedded, and any `-sil-verify-all` build. Relocating the only such conformer
        // (Parser.Witness) out of the defining module is the verified fix; mirrors the
        // swift-serializer-primitives fix (a652cec). See:
        //   swift-institute/Issues/swift-issue-noncopyable-assoctype-never-bodyless-witness
        .target(
            name: "Parser Witness Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),

        // MARK: - Error & Match

        .target(
            name: "Parser Error Primitives",
            dependencies: [
                "Parser Primitive",
                .product(name: "Either Primitives", package: "swift-either-primitives"),
                .product(name: "Product Primitives", package: "swift-product-primitives"),
                .product(name: "Text Primitives", package: "swift-text-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),
        .target(
            name: "Parser Match Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Remaining Primitives",
                "Parser Error Primitives",
            ]
        ),

        // MARK: - Input Errors

        .target(
            name: "Parser EndOfInput Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),
        .target(
            name: "Parser Constraint Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),

        // MARK: - Combinators

        .target(
            name: "Parser OneOf Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),
        .target(
            name: "Parser Map Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser FlatMap Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Filter Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Constraint Primitives",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Conditional Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Optional Primitives",
            dependencies: [
                "Parser Primitive",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),
        .target(
            name: "Parser Skip Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
            ]
        ),
        .target(
            name: "Parser Many Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Take Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),
        .target(
            name: "Parser Take Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
                "Parser Skip Primitives",
                "Parser Conditional Primitives",
                "Parser Optional Primitives",
                "Parser Always Primitives",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),
        .target(
            name: "Parser Pair Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
                .product(name: "Pair Primitives", package: "swift-pair-primitives"),
            ]
        ),

        // MARK: - Consumption

        .target(
            name: "Parser Consume Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Constraint Primitives",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
            ]
        ),
        .target(
            name: "Parser Discard Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Constraint Primitives",
                "Parser Consume Primitives",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
            ]
        ),

        // MARK: - Prefix

        .target(
            name: "Parser Prefix Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Constraint Primitives",
                "Parser Match Primitives",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
            ]
        ),

        // MARK: - Element Access

        .target(
            name: "Parser First Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Match Primitives",
                "Parser EndOfInput Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Position Tracking

        .target(
            name: "Parser Tracked Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),
        .target(
            name: "Parser Spanned Primitives",
            dependencies: [
                "Parser Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),
        .target(
            name: "Parser Span Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
                "Parser Tracked Primitives",
                "Parser Spanned Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),
        .target(
            name: "Parser Locate Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Error Primitives",
                "Parser Tracked Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Lookahead

        .target(
            name: "Parser Peek Primitives",
            dependencies: [
                "Parser Primitive",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),
        .target(
            name: "Parser Not Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Match Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
            ]
        ),

        // MARK: - Terminals

        .target(
            name: "Parser Always Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),
        .target(
            name: "Parser Fail Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),
        .target(
            name: "Parser Rest Primitives",
            dependencies: [
                "Parser Primitive",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
            ]
        ),
        .target(
            name: "Parser End Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Remaining Primitives",
                "Parser Match Primitives",
            ]
        ),

        // MARK: - Utilities

        .target(
            name: "Parser Lazy Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),
        .target(
            name: "Parser Trace Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),
        .target(
            name: "Parser Parse Primitives",
            dependencies: [
                "Parser Primitive",
            ]
        ),

        // MARK: - Concrete Parsers

        .target(
            name: "Parser Conformance Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Match Primitives",
            ]
        ),
        // MARK: - Umbrella

        .target(
            name: "Parser Primitives",
            dependencies: [
                "Parser Primitive",
                "Parser Remaining Primitives",
                "Parser Tagged Primitives",
                "Parser Witness Primitives",
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
                "Parser Pair Primitives",
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
                "Parser Parse Primitives",
                "Parser Conformance Primitives",
            ]
        ),

        // MARK: - Tests

        .target(
            name: "Parser Primitives Test Support",
            dependencies: [
                "Parser Primitives",
                .product(name: "Input Primitives", package: "swift-input-primitives"),
                .product(name: "Input Primitives Test Support", package: "swift-input-primitives"),
                .product(name: "Array Primitives Test Support", package: "swift-array-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
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
            name: "Parser Pair Primitives Tests",
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
