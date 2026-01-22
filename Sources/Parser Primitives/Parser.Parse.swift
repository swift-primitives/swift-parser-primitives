//
//  Parser.Parse.swift
//  swift-parser-primitives
//
//  Nested accessor for parse operation variants.
//

extension Parser {
    /// Accessor providing parse operation variants.
    ///
    /// The `Parse` struct encapsulates execution strategies for a parser,
    /// enabling discoverability via autocomplete:
    ///
    /// ```swift
    /// parser.parse.
    ///            ├── compiled()   // lazy Machine compilation
    ///            ├── prepared()   // eager Machine compilation
    ///            └── (future)     // incremental, traced, etc.
    /// ```
    ///
    /// Direct execution remains available via the protocol method:
    /// ```swift
    /// try parser.parse(&input)
    /// ```
    public struct Parse<P: Parser.`Protocol`> {
        @usableFromInline
        package let parser: P

        @usableFromInline
        package init(parser: P) {
            self.parser = parser
        }
    }
}

// MARK: - Parser Extension

extension Parser.`Protocol` {
    /// Accessor for parse operation variants.
    ///
    /// Use this to discover and access different execution strategies:
    /// - `parse.compiled()` — lazy Machine compilation (non-Sendable)
    /// - `parse.prepared()` — eager Machine compilation (Sendable)
    ///
    /// For direct execution, use the protocol method: `parse(&input)`
    @inlinable
    public var parse: Parser.Parse<Self> {
        Parser.Parse(parser: self)
    }
}
