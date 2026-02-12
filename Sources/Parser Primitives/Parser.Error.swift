//
//  Parser.Error.swift
//  swift-standards
//
//  Error transformation namespace and combinators.
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

// MARK: - Map

extension Parser.Error {
    /// A parser that transforms the failure type of an upstream parser.
    public struct Map<Upstream: Parser.`Protocol`, NewFailure: Swift.Error & Sendable>: Sendable
    where Upstream: Sendable {
        @usableFromInline
        let upstream: Upstream

        @usableFromInline
        let transform: @Sendable (Upstream.Failure) -> NewFailure

        @inlinable
        init(
            _ upstream: Upstream,
            transform: @escaping @Sendable (Upstream.Failure) -> NewFailure
        ) {
            self.upstream = upstream
            self.transform = transform
        }
    }
}

extension Parser.Error.Map: Parser.`Protocol` {
    public typealias Input = Upstream.Input
    public typealias ParseOutput = Upstream.ParseOutput
    public typealias Failure = NewFailure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        do {
            return try upstream.parse(&input)
        } catch {
            throw transform(error)
        }
    }
}

extension Parser.Error.Transform {
    /// Transforms errors from the upstream parser.
    ///
    /// - Parameter transform: Closure converting upstream errors to new type.
    /// - Returns: A parser with the transformed failure type.
    ///
    /// ## Example
    /// ```swift
    /// enum MyError: Error { case invalid }
    ///
    /// let parser = intParser.error.map { _ in MyError.invalid }
    /// ```
    @inlinable
    public func map<NewFailure: Swift.Error & Sendable>(
        _ transform: @escaping @Sendable (Upstream.Failure) -> NewFailure
    ) -> Parser.Error.Map<Upstream, NewFailure> {
        Parser.Error.Map(upstream, transform: transform)
    }
}

// MARK: - Replace

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
