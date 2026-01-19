//
//  Parser.Map.Transform.swift
//  swift-standards
//
//  Pure output transformation.
//

extension Parser.Map {
    /// A parser that transforms the output of another parser.
    ///
    /// This is the functor `map` operation for parsers. It applies a pure
    /// transformation to successful parsing results.
    ///
    /// Created via `parser.map(_:)`.
    public struct Transform<Upstream: Parser.Parser, Output>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        internal let upstream: Upstream

        @usableFromInline
        internal let transform: @Sendable (Upstream.Output) -> Output

        @inlinable
        public init(
            upstream: Upstream,
            transform: @escaping @Sendable (Upstream.Output) -> Output
        ) {
            self.upstream = upstream
            self.transform = transform
        }
    }
}

extension Parser.Map.Transform: Parser.Parser {
    public typealias Input = Upstream.Input
    public typealias Failure = Upstream.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        transform(try upstream.parse(&input))
    }
}
