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
    public struct Span<Base: Input, Upstream: Parser>: Sendable
    where Upstream: Sendable, Base: Sendable, Upstream.Input == Base, Upstream.Output: Sendable {
        @usableFromInline
        let upstream: Upstream

        @inlinable
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }
    }
}

extension Parser.Span: Parser.Parser {
    public typealias Input = Parser.Tracked<Base>
    public typealias Output = Parser.Spanned<Upstream.Output>
    public typealias Failure = Parser.Error.Located<Upstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let start = input.currentOffset
        let countBefore = input.base.count
        let value: Upstream.Output
        do {
            value = try upstream.parse(&input.base)
        } catch {
            throw Parser.Error.Located(error, at: start)
        }
        // Update offset based on consumed bytes
        input.offset += (countBefore - input.base.count)
        let end = input.currentOffset
        return Parser.Spanned(value, start: start, end: end)
    }
}

// MARK: - Parser Extension

extension Parser.Parser where Self: Sendable, Input: Parser.Input & Sendable, Output: Sendable {
    /// Wraps this parser to produce spanned output.
    ///
    /// The returned parser requires `Tracked<Input>` and produces
    /// `Spanned<Output>` with start/end offsets.
    @inlinable
    public func spanned() -> Parser.Span<Input, Self> {
        Parser.Span(self)
    }
}
