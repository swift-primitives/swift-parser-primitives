//
//  Parser.Error.Map.swift
//  swift-parser-primitives
//
//  Error type transformation.
//

extension Parser.Error {
    /// A parser that transforms the failure type of an upstream parser.
    public struct Map<Upstream: Parser.`Protocol`, NewFailure: Swift.Error & Sendable>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        let transform: @Sendable (Upstream.Failure) -> NewFailure

        @inlinable
        init(
            _ upstream: Upstream,
            transform: @escaping @Sendable (Upstream.Failure) -> NewFailure
        ) {
            self.upstream = upstream
            self.transform = transform
        }
    }
}

extension Parser.Error.Map: Parser.`Protocol` {
    public typealias Input = Upstream.Input
    public typealias ParseOutput = Upstream.ParseOutput
    public typealias Failure = NewFailure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        do {
            return try upstream.parse(&input)
        } catch {
            throw transform(error)
        }
    }
}

extension Parser.Error.Transform {
    /// Transforms errors from the upstream parser.
    ///
    /// - Parameter transform: Closure converting upstream errors to new type.
    /// - Returns: A parser with the transformed failure type.
    ///
    /// ## Example
    /// ```swift
    /// enum MyError: Error { case invalid }
    ///
    /// let parser = intParser.error.map { _ in MyError.invalid }
    /// ```
    @inlinable
    public func map<NewFailure: Swift.Error & Sendable>(
        _ transform: @escaping @Sendable (Upstream.Failure) -> NewFailure
    ) -> Parser.Error.Map<Upstream, NewFailure> {
        Parser.Error.Map(upstream, transform: transform)
    }
}
