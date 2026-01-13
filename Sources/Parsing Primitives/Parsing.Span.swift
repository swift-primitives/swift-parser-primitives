//
//  Parsing.Span.swift
//  swift-standards
//
//  Span parser that wraps output with source location.
//

extension Parsing {
    /// A parser that wraps output with its source span.
    ///
    /// Captures start and end offsets around the upstream parser,
    /// producing `Spanned<Output>`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var input = Parsing.Tracked(source)
    /// let parser = Parsing.Span(identifierParser)
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

extension Parsing.Span: Parsing.Parser {
    public typealias Input = Parsing.Tracked<Base>
    public typealias Output = Parsing.Spanned<Upstream.Output>
    public typealias Failure = Parsing.Error.Located<Upstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let start = input.currentOffset
        let countBefore = input.base.count
        let value: Upstream.Output
        do {
            value = try upstream.parse(&input.base)
        } catch {
            throw Parsing.Error.Located(error, at: start)
        }
        // Update offset based on consumed bytes
        input.offset += (countBefore - input.base.count)
        let end = input.currentOffset
        return Parsing.Spanned(value, start: start, end: end)
    }
}

// MARK: - Parser Extension

extension Parsing.Parser where Self: Sendable, Input: Parsing.Input & Sendable, Output: Sendable {
    /// Wraps this parser to produce spanned output.
    ///
    /// The returned parser requires `Tracked<Input>` and produces
    /// `Spanned<Output>` with start/end offsets.
    @inlinable
    public func spanned() -> Parsing.Span<Input, Self> {
        Parsing.Span(self)
    }
}
