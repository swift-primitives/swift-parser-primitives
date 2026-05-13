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
    /// producing `Spanned<Output>`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var input = Parser.Tracked(source)
    /// let parser = Parser.Span(identifierParser)
    /// let result = try parser.parse(&input)
    /// print("Identifier '\(result.value)' at \(result.start)..<\(result.end)")
    /// ```
    public struct Span<Base: Input.`Protocol`, Upstream: Parser.`Protocol`>
    where Upstream.Input == Base {
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
    public typealias Output = Parser.Spanned<Upstream.Output>
    public typealias Failure = Parser.Error.Located<Upstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let (value, start) = try input.parseTracked(upstream)
        return Parser.Spanned(value, start: start, end: input.currentOffset)
    }
}

// MARK: - Parser Extension

extension Parser.`Protocol` where Input: Parser.Input.`Protocol` & Copyable {
    /// Wraps this parser to produce spanned output.
    ///
    /// The returned parser requires `Tracked<Input>` and produces
    /// `Spanned<Output>` with start/end offsets.
    @inlinable
    public func spanned() -> Parser.Span<Input, Self> {
        Parser.Span(self)
    }
}
