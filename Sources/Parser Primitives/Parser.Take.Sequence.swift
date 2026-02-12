//
//  Parser.Take.Sequence.swift
//  swift-standards
//
//  Entry point for building sequential parsers.
//

extension Parser.Take {
    /// Entry point for building parsers with result builder syntax.
    ///
    /// `Sequence` provides a convenient way to compose parsers using Swift's
    /// result builder syntax. The resulting parser type is inferred from
    /// the builder contents.
    ///
    /// ## Basic Usage
    ///
    /// ```swift
    /// let keyValue = Parser.Take.Sequence {
    ///     Parser.Prefix.While { $0 != UInt8(ascii: "=") }  // key
    ///     "="                                                // delimiter (discarded)
    ///     Parser.Rest()                                     // value
    /// }
    /// // Type: Parser with ParseOutput = (Substring, Substring) or similar
    /// ```
    public struct Sequence<Input, ParseOutput, Body: Parser.`Protocol`>: Sendable
    where Body: Sendable, Body.Input == Input, Body.ParseOutput == ParseOutput {
        @usableFromInline
        let body: Body

        @inlinable
        public init(
            @Parser.Take.Builder<Input> _ build: () -> Body
        ) {
            self.body = build()
        }
    }
}

extension Parser.Take.Sequence: Parser.`Protocol` {
    public typealias Failure = Body.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        try body.parse(&input)
    }
}
