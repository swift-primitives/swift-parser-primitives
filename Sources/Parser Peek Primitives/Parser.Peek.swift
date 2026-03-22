//
//  Parser.Peek.swift
//  swift-standards
//
//  Lookahead parser that doesn't consume input.
//

extension Parser {
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
    public struct Peek<Upstream: Parser.`Protocol`>: Sendable
    where Upstream: Sendable, Upstream.Input: Parser.Input.`Protocol` {
        @usableFromInline
        internal let upstream: Upstream

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

extension Parser.Peek: Parser.`Protocol` {
    public typealias Input = Upstream.Input
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    // on Property.View accessor chains (input.restore.to) in multiple control flow paths.
    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let checkpoint = input.checkpoint
        do {
            let result = try upstream.parse(&input)
            input.restore.to(__unchecked: (), checkpoint)
            return result
        } catch {
            input.restore.to(__unchecked: (), checkpoint)
            throw error
        }
    }
}

// MARK: - Parser Extension

extension Parser.`Protocol` where Self: Sendable, Input: Parser.Input.`Protocol` {
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
    public func peek() -> Parser.Peek<Self> {
        Parser.Peek(self)
    }
}
