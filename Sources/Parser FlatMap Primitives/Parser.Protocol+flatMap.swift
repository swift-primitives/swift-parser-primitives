extension Parser.`Protocol` {
    /// Chains this parser with another that depends on its output.
    ///
    /// This is the monad `flatMap` operation for parsers.
    ///
    /// - Parameter transform: A function that produces a parser from this parser's output.
    /// - Returns: A parser that runs both parsers in sequence.
    @inlinable
    public func flatMap<P: Parser.`Protocol`>(
        _ transform: @escaping (Output) -> P
    ) -> Parser.FlatMap<Self, P>
    where P.Input == Input {
        .init(upstream: self, transform: transform)
    }
}
