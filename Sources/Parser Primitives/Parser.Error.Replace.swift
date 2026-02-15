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
    public struct Replace<Upstream: Parser.`Protocol`>: Sendable
    where Upstream: Sendable, Upstream.ParseOutput: Sendable {
        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        let output: Upstream.ParseOutput

        @inlinable
        init(_ upstream: Upstream, output: Upstream.ParseOutput) {
            self.upstream = upstream
            self.output = output
        }
    }
}

extension Parser.Error.Replace: Parser.`Protocol` {
    public typealias Input = Upstream.Input
    public typealias ParseOutput = Upstream.ParseOutput
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> ParseOutput {
        do {
            return try upstream.parse(&input)
        } catch {
            return output
        }
    }
}

extension Parser.Error.Transform where Upstream.ParseOutput: Sendable {
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
    public func replace(with output: Upstream.ParseOutput) -> Parser.Error.Replace<Upstream> {
        Parser.Error.Replace(upstream, output: output)
    }
}
