extension Parser.`Protocol` {
    /// Transforms the parser's output using the given function.
    ///
    /// This is the functor `map` operation for parsers.
    ///
    /// - Parameter transform: A function to apply to successful output.
    /// - Returns: A parser that transforms its output.
    @inlinable
    public func map<NewOutput>(
        _ transform: @escaping @Sendable (ParseOutput) -> NewOutput
    ) -> Parser.Map.Transform<Self, NewOutput> {
        .init(upstream: self, transform: transform)
    }

    /// Transforms the parser's output using a throwing function.
    ///
    /// If the transform throws, parsing fails with that error. The resulting
    /// parser's failure type composes both upstream and transform errors.
    ///
    /// - Parameter transform: A throwing function to apply to successful output.
    /// - Returns: A parser that transforms its output, potentially failing.
    @inlinable
    public func tryMap<NewOutput, E: Swift.Error & Sendable>(
        _ transform: @escaping @Sendable (ParseOutput) throws(E) -> NewOutput
    ) -> Parser.Map.Throwing<Self, NewOutput, E> {
        .init(upstream: self, transform: transform)
    }
}
