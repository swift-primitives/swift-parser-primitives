# Parser Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Parser combinator primitives for Swift — 37 narrow modules spanning byte parsers, combinators (always, backtrack, conditional, constraint, filter, first, lazy, many, not, oneOf, optional, peek, prefix, rest, skip, span, take), and tracing/locating utilities. Each module ships as its own product so consumers depend on exactly the surface they need.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-parser-primitives.git", from: "0.1.0")
]
```

Add the umbrella product to your target (re-exports every module):

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Parser Primitives", package: "swift-parser-primitives")
    ]
)
```

For narrower compile-time surface, depend on individual variant products such as `Parser Match Primitives`, `Parser Span Primitives`, or `Parser Constraint Primitives`. The full product list is in [Package.swift](Package.swift).

Requires Swift 6.2+.

## License

Apache 2.0. See [LICENSE](LICENSE).
