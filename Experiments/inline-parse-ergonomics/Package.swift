// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "inline-parse-ergonomics",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(path: "../.."),
        .package(path: "../../../swift-ascii-parser-primitives"),
    ],
    targets: [
        .testTarget(
            name: "InlineParseErgonomicsTests",
            dependencies: [
                .product(name: "Parser Primitives", package: "swift-parser-primitives"),
                .product(name: "Parser Primitives Test Support", package: "swift-parser-primitives"),
                .product(name: "ASCII Decimal Parser Primitives", package: "swift-ascii-parser-primitives"),
            ],
            path: "Tests"
        ),
    ]
)
