//
//  Parser.Take.Transform.swift
//  swift-standards
//
//  Entry point for building transforming parsers.
//

extension Parser.Take {
    /// A parser that transforms its body's output.
    ///
    /// Enables constructing domain types from parsed tuples:
    ///
    /// ```swift
    /// let point = Parser.Take.Transform(Point.init) {
    ///     IntParser()
    ///     ","
    ///     IntParser()
    /// }
    /// ```
    public struct Transform<Input, BodyOutput, ParseOutput, Body: Parser.`Protocol`>: Sendable
    where Body: Sendable, Body.Input == Input, Body.ParseOutput == BodyOutput {
        @usableFromInline
        let body: Body

        @usableFromInline
        let transform: @Sendable (BodyOutput) -> ParseOutput

        @inlinable
        public init(
            _ transform: @escaping @Sendable (BodyOutput) -> ParseOutput,
            @Parser.Take.Builder<Input> _ build: () -> Body
        ) {
            self.body = build()
            self.transform = transform
        }
    }
}

extension Parser.Take.Transform: Parser.`Protocol` {
    public typealias Failure = Body.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        transform(try body.parse(&input))
    }
}
