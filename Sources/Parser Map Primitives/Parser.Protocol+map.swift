extension Parser.`Protocol` {
    /// Transforms the parser's output using the given function.
    ///
    /// This is the functor `map` operation for parsers.
    ///
    /// - Parameter transform: A function to apply to successful output.
    /// - Returns: A parser that transforms its output.
    @inlinable
    public func map<NewOutput>(
        _ transform: @escaping (Output) -> NewOutput
    ) -> Parser.Map<Self, NewOutput> {
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
    public func tryMap<NewOutput, E: Swift.Error>(
        _ transform: @escaping (Output) throws(E) -> NewOutput
    ) -> Parser.Map<Self, NewOutput>.Throwing<E> {
        .init(upstream: self, transform: transform)
    }
}
