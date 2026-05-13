//
//  Parser.Error.Replace.swift
//  swift-parser-primitives
//
//  Error replacement with default value.
//

extension Parser.Error {
    /// A parser that replaces failures with a default output value.
    ///
    /// This makes the parser infallible (`Failure == Never`).
    public struct Replace<Upstream: Parser.`Protocol`> {
        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        let output: Upstream.Output

        @inlinable
        init(_ upstream: Upstream, output: Upstream.Output) {
            self.upstream = upstream
            self.output = output
        }
    }
}

extension Parser.Error.Replace: Parser.`Protocol` {
    public typealias Input = Upstream.Input
    public typealias Output = Upstream.Output
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> Output {
        do {
            return try upstream.parse(&input)
        } catch {
            return output
        }
    }
}

extension Parser.Error.Transform {
    /// Replaces any parse failure with a default output value.
    ///
    /// - Parameter output: The value to return when parsing fails.
    /// - Returns: An infallible parser that never throws.
    ///
    /// ## Example
    /// ```swift
    /// let parser = intParser.error.replace(with: 0)
    /// // Returns 0 if parsing fails
    /// ```
    @inlinable
    public func replace(with output: Upstream.Output) -> Parser.Error.Replace<Upstream> {
        Parser.Error.Replace(upstream, output: output)
    }
}
