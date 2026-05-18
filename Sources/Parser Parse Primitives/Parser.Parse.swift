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
    ///
    /// ## Copyability
    ///
    /// `Parse` is structurally `~Copyable` and gains `Copyable`
    /// conditionally when `P: Copyable` (matches `Parser.Machine.Compiled`'s
    /// Phase 4 shape). The wrapper can hold `~Copyable` parsers, allowing
    /// the type to be used uniformly across the Copyable/~Copyable split.
    ///
    /// The discoverable accessor `parser.parse.compiled()` remains
    /// `Copyable`-only — Swift 6.3.2 rejects `consuming get` on protocol
    /// extensions returning a generic wrapper that captures `Self`
    /// (compile error: "'self' is borrowed and cannot be consumed"). For
    /// `~Copyable` parsers, construct `Parse` manually or use the direct
    /// Machine constructor:
    ///
    /// ```swift
    /// // Copyable parser — discoverable accessor:
    /// let compiled = parser.parse.compiled()
    ///
    /// // ~Copyable parser — manual Parse, then .compiled():
    /// let parse = Parser.Parse(parser: nonCopyableParser)  // consumes parser
    /// let compiled = parse.compiled()
    ///
    /// // ~Copyable parser — direct Machine constructor:
    /// let compiled = Parser.Machine.Compiled(source: nonCopyableParser, witness: .leaf)
    /// ```
    ///
    /// Track upstream Swift compiler support for `consuming get` on
    /// protocol extensions to lift the accessor-side limitation
    /// (HANDOFF.md Wave 1 Item 3c).
    @frozen
    public struct Parse<P: Parser.`Protocol` & ~Copyable>: ~Copyable {
        public let parser: P

        @inlinable
        public init(parser: consuming P) {
            self.parser = parser
        }
    }
}

extension Parser.Parse: Copyable where P: Copyable {}

// MARK: - Parser Extension

extension Parser.`Protocol` {
    /// Accessor for parse operation variants.
    ///
    /// Use this to discover and access different execution strategies:
    /// - `parse.compiled()` — lazy Machine compilation (non-Sendable)
    /// - `parse.prepared()` — eager Machine compilation (Sendable)
    ///
    /// For direct execution, use the protocol method: `parse(&input)`
    ///
    /// The property accessor is `Copyable`-only by Swift 6.3.2 compiler
    /// limitation; `~Copyable` parsers use manual construction
    /// `Parser.Parse(parser: ...)` or the direct Machine constructor.
    /// See `Parser.Parse` doc for full pattern.
    @inlinable
    public var parse: Parser.Parse<Self> {
        Parser.Parse(parser: self)
    }
}
