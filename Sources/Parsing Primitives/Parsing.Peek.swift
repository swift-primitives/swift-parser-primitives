//
//  Parsing.Peek.swift
//  swift-standards
//
//  Lookahead parser that doesn't consume input.
//

extension Parsing {
    /// A parser that runs upstream without consuming input.
    ///
    /// `Peek` tries to parse, and if successful, restores the input
    /// to its original state. Useful for lookahead decisions.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Check if next character is a digit without consuming
    /// let startsWithDigit = Peek(digit)
    ///
    /// // Or using extension
    /// let startsWithDigit = digit.peek()
    /// ```
    ///
    /// ## Behavior
    ///
    /// - On success: Returns upstream's output, input is **not** consumed
    /// - On failure: Throws upstream's error, input is **not** consumed
    public struct Peek<Upstream: Parser>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        let upstream: Upstream

        /// Creates a peek parser.
        ///
        /// - Parameter upstream: The parser to run without consuming.
        @inlinable
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }
    }
}

// MARK: - Parser Conformance

extension Parsing.Peek: Parsing.Parser {
    public typealias Input = Upstream.Input
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let saved = input
        let result = try upstream.parse(&input)
        input = saved  // Always restore
        return result
    }
}

// MARK: - Parser Extension

extension Parsing.Parser where Self: Sendable {
    /// Creates a parser that peeks ahead without consuming input.
    ///
    /// If this parser succeeds, returns the output but restores
    /// input to its original position. If it fails, the error
    /// is thrown and input is still restored.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Peek at next character
    /// let next = First.Element().peek()
    ///
    /// // Decide parsing strategy based on lookahead
    /// let parser = Take {
    ///     "<".peek()  // Check for tag start
    ///     tagParser   // Then actually parse it
    /// }
    /// ```
    @inlinable
    public func peek() -> Parsing.Peek<Self> {
        Parsing.Peek(self)
    }
}
