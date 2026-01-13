//
//  Parsing.Locate.swift
//  swift-standards
//
//  Parser that wraps errors with location information.
//

extension Parsing {
    /// A parser that wraps errors with their location.
    ///
    /// Transforms `Failure` to `Located<Failure>` by capturing the
    /// byte offset when an error occurs.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var input = Parsing.Tracked(source)
    /// let parser = Parsing.Locate(myParser)
    /// // Errors now include offset information
    /// ```
    public struct Locate<Base: Input, Upstream: Parser>: Sendable
    where Upstream: Sendable, Base: Sendable, Upstream.Input == Base {
        @usableFromInline
        let upstream: Upstream

        @inlinable
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }
    }
}

extension Parsing.Locate: Parsing.Parser {
    public typealias Input = Parsing.Tracked<Base>
    public typealias Output = Upstream.Output
    public typealias Failure = Parsing.Error.Located<Upstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let errorOffset = input.currentOffset
        let countBefore = input.base.count
        let value: Output
        do {
            value = try upstream.parse(&input.base)
        } catch {
            throw Parsing.Error.Located(error, at: errorOffset)
        }
        // Update offset based on consumed bytes
        input.offset += (countBefore - input.base.count)
        return value
    }
}

// MARK: - Parser Extension

extension Parsing.Parser where Self: Sendable, Input: Parsing.Input & Sendable {
    /// Wraps this parser to produce located errors.
    ///
    /// The returned parser requires `Tracked<Input>` and produces
    /// `Located<Failure>` errors with byte offsets.
    @inlinable
    public func located() -> Parsing.Locate<Input, Self> {
        Parsing.Locate(self)
    }
}
