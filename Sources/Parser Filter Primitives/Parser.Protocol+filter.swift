extension Parser.`Protocol` {
    /// Filters the parser's output using a predicate.
    ///
    /// If the predicate returns false, parsing fails.
    ///
    /// - Parameter predicate: A function that validates the output.
    /// - Returns: A parser that fails if the predicate is false.
    @inlinable
    public func filter(
        _ predicate: @escaping (Output) -> Bool
    ) -> Parser.Filter<Self> {
        .init(upstream: self, predicate: predicate)
    }
}
