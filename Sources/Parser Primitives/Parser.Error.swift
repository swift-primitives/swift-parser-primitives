//
//  Parser.Error.swift
//  swift-parser-primitives
//
//  Error namespace and transformation accessor.
//

extension Parser {
    /// Namespace for error transformation types.
    public enum Error {}
}

// MARK: - Transform Wrapper

extension Parser.Error {
    /// Wrapper providing error transformation methods.
    ///
    /// Access via the `.error` property on any parser:
    /// ```swift
    /// let parser = myParser.error.map { error in
    ///     MyCustomError(from: error)
    /// }
    /// ```
    public struct Transform<Upstream: Parser.`Protocol`>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        let upstream: Upstream

        @inlinable
        init(_ upstream: Upstream) {
            self.upstream = upstream
        }
    }
}

// MARK: - Parser.error Property

extension Parser.`Protocol` where Self: Sendable {
    /// Access error transformation methods.
    ///
    /// ## Transform Error Type
    /// ```swift
    /// let parser = intParser.error.map { _ in
    ///     MyError.invalidNumber
    /// }
    /// ```
    ///
    /// ## Replace Error with Default
    /// ```swift
    /// let parser = intParser.error.replace(with: 0)
    /// // Now infallible - returns 0 on parse failure
    /// ```
    @inlinable
    public var error: Parser.Error.Transform<Self> {
        Parser.Error.Transform(self)
    }
}
