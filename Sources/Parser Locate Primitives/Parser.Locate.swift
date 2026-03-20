//
//  Parser.Locate.swift
//  swift-standards
//
//  Parser that wraps errors with location information.
//

extension Parser {
    /// A parser that wraps errors with their location.
    ///
    /// Transforms `Failure` to `Located<Failure>` by capturing the
    /// byte offset when an error occurs.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var input = Parser.Tracked(source)
    /// let parser = Parser.Locate(myParser)
    /// // Errors now include offset information
    /// ```
    public struct Locate<Base: Input.`Protocol`, Upstream: Parser.`Protocol`>: Sendable
    where Upstream: Sendable, Base: Sendable, Upstream.Input == Base {
        @usableFromInline
        let upstream: Upstream

        @inlinable
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }
    }
}

extension Parser.Locate: Parser.`Protocol` {
    public typealias Input = Parser.Tracked<Base>
    public typealias Output = Upstream.Output
    public typealias Failure = Parser.Error.Located<Upstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try input.parseTracked(upstream).output
    }
}

// MARK: - Parser Extension

extension Parser.`Protocol` where Self: Sendable, Input: Parser.Input.`Protocol` & Sendable & Copyable {
    /// Wraps this parser to produce located errors.
    ///
    /// The returned parser requires `Tracked<Input>` and produces
    /// `Located<Failure>` errors with byte offsets.
    @inlinable
    public func located() -> Parser.Locate<Input, Self> {
        Parser.Locate(self)
    }
}
