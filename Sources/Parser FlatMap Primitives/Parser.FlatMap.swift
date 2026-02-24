//
//  Parser.FlatMap.swift
//  swift-standards
//
//  Dependent parser chaining.
//

extension Parser {
    /// A parser that chains two parsers where the second depends on the first's output.
    ///
    /// This is the monad `flatMap` (or `bind`) operation for parsers.
    ///
    /// Created via `parser.flatMap(_:)`.
    public struct FlatMap<Upstream: Parser.`Protocol`, Downstream: Parser.`Protocol`>: Sendable
    where Upstream: Sendable, Downstream: Sendable, Upstream.Input == Downstream.Input {
        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        let transform: @Sendable (Upstream.ParseOutput) -> Downstream

        @inlinable
        public init(
            upstream: Upstream,
            transform: @escaping @Sendable (Upstream.ParseOutput) -> Downstream
        ) {
            self.upstream = upstream
            self.transform = transform
        }
    }
}

extension Parser.FlatMap: Parser.`Protocol` {
    public typealias Input = Upstream.Input
    public typealias ParseOutput = Downstream.ParseOutput
    public typealias Failure = Parser.Error.Either<Upstream.Failure, Downstream.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        let upstreamOutput: Upstream.ParseOutput
        do {
            upstreamOutput = try upstream.parse(&input)
        } catch {
            throw .left(error)
        }
        let downstream = transform(upstreamOutput)
        do {
            return try downstream.parse(&input)
        } catch {
            throw .right(error)
        }
    }
}
