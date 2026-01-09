//
//  Parsing.Lazy.swift
//  swift-standards
//
//  Lazy parser for recursive grammars.
//

extension Parsing {
    /// A parser that defers construction until parse time.
    ///
    /// `Lazy` enables recursive grammars by breaking the cycle in type
    /// definitions. The parser is built fresh on each `parse` call.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Recursive expression parser
    /// func makeExpr() -> some Parser<Substring, Expr, some Error> {
    ///     OneOf {
    ///         number
    ///         Take {
    ///             "("
    ///             Lazy { makeExpr() }  // Recursive reference
    ///             ")"
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## HTML/XML Parsing
    ///
    /// ```swift
    /// func makeElement() -> some Parser<Substring, Element, some Error> {
    ///     Take {
    ///         "<"
    ///         tagName
    ///         ">"
    ///         Many { Lazy { makeElement() } }  // Nested elements
    ///         "</"
    ///         tagName
    ///         ">"
    ///     }
    /// }
    /// ```
    ///
    /// ## Performance Note
    ///
    /// The closure is called on every `parse` invocation, creating a
    /// new parser instance each time. For hot paths, consider caching
    /// the parser externally if profiling shows this as a bottleneck.
    public struct Lazy<P: Parser>: Sendable
    where P: Sendable {
        @usableFromInline
        let build: @Sendable () -> P

        /// Creates a lazy parser from an autoclosure.
        ///
        /// - Parameter build: An expression that creates the parser.
        @inlinable
        public init(_ build: @escaping @Sendable @autoclosure () -> P) {
            self.build = build
        }

        /// Creates a lazy parser from a closure.
        ///
        /// - Parameter build: A closure that creates the parser.
        @inlinable
        public init(_ build: @escaping @Sendable () -> P) {
            self.build = build
        }
    }
}

// MARK: - Parser Conformance

extension Parsing.Lazy: Parsing.Parser {
    public typealias Input = P.Input
    public typealias Output = P.Output
    public typealias Failure = P.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try build().parse(&input)
    }
}
