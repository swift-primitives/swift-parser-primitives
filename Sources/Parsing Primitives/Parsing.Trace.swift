//
//  Parsing.Trace.swift
//  swift-standards
//
//  Debug tracing combinator.
//

extension Parsing {
    /// A parser that logs entry, exit, and errors for debugging.
    ///
    /// `Trace` wraps any parser and outputs debug information
    /// without affecting parsing behavior.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let parser = myComplexParser.trace("complex")
    /// // Logs:
    /// // [complex] enter
    /// // [complex] success: <output>
    /// // or
    /// // [complex] failure: <error>
    /// ```
    ///
    /// ## Custom Logger
    ///
    /// ```swift
    /// var logs: [String] = []
    /// let parser = myParser.trace("test") { logs.append($0) }
    /// ```
    public struct Trace<Upstream: Parser>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        let label: String

        @usableFromInline
        let log: @Sendable (String) -> Void

        /// Creates a tracing parser.
        ///
        /// - Parameters:
        ///   - upstream: The parser to trace.
        ///   - label: Label to identify this parser in logs.
        ///   - log: Logging function. Defaults to `print`.
        @inlinable
        public init(
            _ upstream: Upstream,
            label: String,
            log: @escaping @Sendable (String) -> Void = { print($0) }
        ) {
            self.upstream = upstream
            self.label = label
            self.log = log
        }
    }
}

// MARK: - Parser Conformance

extension Parsing.Trace: Parsing.Parser {
    public typealias Input = Upstream.Input
    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        log("[\(label)] enter")
        do {
            let result = try upstream.parse(&input)
            log("[\(label)] success: \(result)")
            return result
        } catch {
            log("[\(label)] failure: \(error)")
            throw error
        }
    }
}

// MARK: - Parser Extension

extension Parsing.Parser where Self: Sendable {
    /// Wraps this parser with debug tracing.
    ///
    /// Logs entry, success, and failure events to help debug
    /// complex parser compositions.
    ///
    /// - Parameters:
    ///   - label: Identifier for this parser in logs.
    ///   - log: Optional custom logging function.
    /// - Returns: A tracing wrapper around this parser.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser = Take {
    ///     identifier.trace("id")
    ///     "=".trace("equals")
    ///     value.trace("value")
    /// }
    /// ```
    @inlinable
    public func trace(
        _ label: String,
        log: @escaping @Sendable (String) -> Void = { print($0) }
    ) -> Parsing.Trace<Self> {
        Parsing.Trace(self, label: label, log: log)
    }
}
