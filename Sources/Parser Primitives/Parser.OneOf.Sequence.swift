//
//  Parser.OneOf.Sequence.swift
//  swift-standards
//
//  Entry point for building alternative parsers.
//

extension Parser.OneOf {
    /// Entry point for building alternative parsers.
    ///
    /// `Sequence` tries each parser in order until one succeeds.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let boolean = Parser.OneOf.Sequence {
    ///     "true".map { true }
    ///     "false".map { false }
    /// }
    /// ```
    public struct Sequence<Input, Output, Body: Parser.`Protocol`>: Sendable
    where Body: Sendable, Body.Input == Input, Body.Output == Output {
        @usableFromInline
        let body: Body

        @inlinable
        public init(
            @Parser.OneOf.Builder<Input, Output> _ build: () -> Body
        ) {
            self.body = build()
        }
    }
}

extension Parser.OneOf.Sequence: Parser.`Protocol` {
    public typealias Failure = Body.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try body.parse(&input)
    }
}
