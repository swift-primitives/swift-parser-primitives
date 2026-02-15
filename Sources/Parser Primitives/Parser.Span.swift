//
//  Parser.Span.swift
//  swift-standards
//
//  Span parser that wraps output with source location.
//

extension Parser {
    /// A parser that wraps output with its source span.
    ///
    /// Captures start and end offsets around the upstream parser,
    /// producing `Spanned<ParseOutput>`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var input = Parser.Tracked(source)
    /// let parser = Parser.Span(identifierParser)
    /// let result = try parser.parse(&input)
    /// print("Identifier '\(result.value)' at \(result.start)..<\(result.end)")
    /// ```
    public struct Span<Base: Input, Upstream: Parser.`Protocol`>: Sendable
    where Upstream: Sendable, Base: Sendable, Upstream.Input == Base, Upstream.ParseOutput: Sendable {
        @usableFromInline
        let upstream: Upstream

        @inlinable
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }
    }
}

extension Parser.Span: Parser.`Protocol` {
    public typealias Input = Parser.Tracked<Base>
    public typealias ParseOutput = Parser.Spanned<Upstream.ParseOutput>
    public typealias Failure = Parser.Error.Located<Upstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        let (value, start) = try input.parseTracked(upstream)
        return Parser.Spanned(value, start: start, end: input.currentOffset)
    }
}

// MARK: - Parser Extension

extension Parser.`Protocol` where Self: Sendable, Input: Parser.Input & Sendable, ParseOutput: Sendable {
    /// Wraps this parser to produce spanned output.
    ///
    /// The returned parser requires `Tracked<Input>` and produces
    /// `Spanned<ParseOutput>` with start/end offsets.
    @inlinable
    public func spanned() -> Parser.Span<Input, Self> {
        Parser.Span(self)
    }
}
