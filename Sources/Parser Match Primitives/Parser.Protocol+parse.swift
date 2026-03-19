extension Parser.`Protocol` {
    /// Parses a complete input, requiring all bytes to be consumed.
    ///
    /// Use this for top-level parsing where trailing input is an error.
    ///
    /// The return type is `Either<Failure, Match.Error>` because parsing can fail
    /// either from the parser itself (`Failure`) or from trailing input (`Match.Error`).
    ///
    /// - Parameter input: The complete input to parse.
    /// - Returns: The parsed value.
    /// - Throws: `Either<Failure, Match.Error>` if parsing fails or input remains.
    @inlinable
    public func parse(_ input: consuming Input) throws(Either<Failure, Parser.Match.Error>) -> Output
    where Input: Collection.Slice.`Protocol` & Copyable {
        var input = input
        let output: Output
        do {
            output = try parse(&input)
        } catch {
            throw .left(error)
        }
        guard input.isEmpty else {
            throw .right(.expectedEnd(remaining: input.remainingCount))
        }
        return output
    }
}

extension Parser.`Protocol` where Failure == Parser.Match.Error {
    /// Parses a complete input, requiring all bytes to be consumed.
    ///
    /// Specialized for parsers with `Match.Error` failure - returns unified error type.
    ///
    /// - Parameter input: The complete input to parse.
    /// - Returns: The parsed value.
    /// - Throws: `Match.Error` if parsing fails or input remains.
    @inlinable
    public func parse(_ input: consuming Input) throws(Parser.Match.Error) -> Output
    where Input: Collection.Slice.`Protocol` & Copyable {
        var input = input
        let output = try parse(&input)
        guard input.isEmpty else {
            throw .expectedEnd(remaining: input.remainingCount)
        }
        return output
    }
}
