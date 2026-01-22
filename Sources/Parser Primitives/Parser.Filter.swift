//
//  Parser.Filter.swift
//  swift-standards
//
//  Output validation combinator.
//

extension Parser {
    /// A parser that filters output using a predicate.
    ///
    /// If the upstream parser succeeds but the predicate returns false,
    /// parsing fails.
    ///
    /// Created via `parser.filter(_:)`.
    public struct Filter<Upstream: Parser.`Protocol`>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        internal let upstream: Upstream

        @usableFromInline
        internal let predicate: @Sendable (Upstream.Output) -> Bool

        @inlinable
        public init(
            upstream: Upstream,
            predicate: @escaping @Sendable (Upstream.Output) -> Bool
        ) {
            self.upstream = upstream
            self.predicate = predicate
        }
    }
}

extension Parser.Filter: Parser.`Protocol` {
    public typealias Input = Upstream.Input
    public typealias Output = Upstream.Output
    public typealias Failure = Parser.Error.Either<Upstream.Failure, Parser.Constraint.Error>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let output: Upstream.Output
        do {
            output = try upstream.parse(&input)
        } catch {
            throw .left(error)
        }
        guard predicate(output) else {
            throw .right(.validationFailed(value: "\(output)", reason: "filter predicate"))
        }
        return output
    }
}
