//
//  Collection.Slice+parse.swift
//  swift-parser-primitives
//
//  Inline parsing entry points on input types.
//

extension Collection.Slice.`Protocol` where Self: Parser.Input.Streaming & Sendable {
    /// Parses inline using a builder closure. Input type is inferred from `self`.
    ///
    /// The receiver provides the builder's `Input` generic parameter,
    /// enabling `<_, UInt16>` type placeholder inference for leaf parsers.
    ///
    /// ```swift
    /// var input = Parser.Input.Bytes(utf8: "80:443")
    /// let (host, port) = try input.parse {
    ///     ASCII.Decimal.Parser<_, UInt16>()
    ///     ":"
    ///     ASCII.Decimal.Parser<_, UInt16>()
    /// }
    /// // input is advanced past consumed portion
    /// ```
    @inlinable
    public mutating func parse<Body: Parser.`Protocol`>(
        @Parser.Take.Builder<Self> _ build: () -> Body
    ) throws(Body.Failure) -> Body.Output where Body.Input == Self {
        try build().parse(&self)
    }

    /// Parses inline, discarding remaining input. One-shot convenience.
    ///
    /// ```swift
    /// let (host, port) = try Parser.Input.Bytes(utf8: "80:443").parsing {
    ///     ASCII.Decimal.Parser<_, UInt16>()
    ///     ":"
    ///     ASCII.Decimal.Parser<_, UInt16>()
    /// }
    /// ```
    @inlinable
    public func parsing<Body: Parser.`Protocol`>(
        @Parser.Take.Builder<Self> _ build: () -> Body
    ) throws(Body.Failure) -> Body.Output where Body.Input == Self {
        var copy = self
        return try build().parse(&copy)
    }
}
