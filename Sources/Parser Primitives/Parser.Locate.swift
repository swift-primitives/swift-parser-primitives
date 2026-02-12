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
    public struct Locate<Base: Input, Upstream: Parser.`Protocol`>: Sendable
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
    public typealias ParseOutput = Upstream.ParseOutput
    public typealias Failure = Parser.Error.Located<Upstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        let errorOffset = input.currentOffset
        let countBefore = input.base.count
        let value: ParseOutput
        do {
            value = try upstream.parse(&input.base)
        } catch {
            throw Parser.Error.Located(error, at: Int(bitPattern: errorOffset))
        }
        // Update offset based on consumed elements
        let consumed = countBefore.subtract.saturating(input.base.count)
        input.offset += consumed
        return value
    }
}

// MARK: - Parser Extension

extension Parser.`Protocol` where Self: Sendable, Input: Parser.Input & Sendable {
    /// Wraps this parser to produce located errors.
    ///
    /// The returned parser requires `Tracked<Input>` and produces
    /// `Located<Failure>` errors with byte offsets.
    @inlinable
    public func located() -> Parser.Locate<Input, Self> {
        Parser.Locate(self)
    }
}
