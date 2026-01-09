//
//  Parsing.Not.swift
//  swift-standards
//
//  Negative lookahead parser.
//

extension Parsing {
    /// A parser that succeeds if upstream fails.
    ///
    /// `Not` is the inverse of its upstream parser. It succeeds (with `Void`)
    /// when upstream fails, and fails when upstream succeeds.
    /// Neither case consumes input.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Match characters that are NOT quotes
    /// let notQuote = Not("\"")
    ///
    /// // Parse until we hit a reserved word
    /// let identifier = Take {
    ///     Not(reservedWord)
    ///     word
    /// }
    /// ```
    ///
    /// ## Behavior
    ///
    /// - Upstream succeeds → `Not` fails with `.unexpectedMatch`
    /// - Upstream fails → `Not` succeeds with `Void`
    /// - Input is **never** consumed
    public struct Not<Upstream: Parser>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        let upstream: Upstream

        /// Creates a negative lookahead parser.
        ///
        /// - Parameter upstream: The parser that should fail.
        @inlinable
        public init(_ upstream: Upstream) {
            self.upstream = upstream
        }
    }
}

// MARK: - Error

extension Parsing.Not {
    /// Error thrown when the upstream parser unexpectedly succeeds.
    public enum Error: Swift.Error, Sendable, Hashable {
        /// The upstream parser matched when it shouldn't have.
        case unexpectedMatch
    }
}

// MARK: - Parser Conformance

extension Parsing.Not: Parsing.Parser {
    public typealias Input = Upstream.Input
    public typealias Output = Void
    public typealias Failure = Parsing.Not<Upstream>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) {
        let saved = input
        if (try? upstream.parse(&input)) != nil {
            // Upstream succeeded - restore and fail
            input = saved
            throw .unexpectedMatch
        } else {
            // Upstream failed - restore and succeed
            input = saved
        }
    }
}

// MARK: - Parser Extension

extension Parsing.Parser where Self: Sendable {
    /// Creates a parser that succeeds when this parser fails.
    ///
    /// Useful for negative lookahead - ensuring input does NOT
    /// match a pattern before proceeding.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Parse word that isn't a keyword
    /// let identifier = Take {
    ///     keyword.not()
    ///     word
    /// }
    ///
    /// // Match anything except closing delimiter
    /// let content = Many {
    ///     "-->".not()
    ///     First.Element()
    /// }
    /// ```
    @inlinable
    public func not() -> Parsing.Not<Self> {
        Parsing.Not(self)
    }
}
