//
//  Parser.Optionally.swift
//  swift-standards
//
//  Runtime optional parser (backtracks on failure).
//

extension Parser {
    /// A parser that tries to parse but succeeds with nil on failure.
    ///
    /// Unlike `Optional` (compile-time optional), this is runtime optional.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let optionalSign = Parser.Optionally { Sign() }
    /// ```
    public struct Optionally<Wrapped: Parser.`Protocol`>: Sendable
    where Wrapped: Sendable, Wrapped.Input: Parser.Input.`Protocol` {
        @usableFromInline
        internal let wrapped: Wrapped

        @inlinable
        public init(_ wrapped: Wrapped) {
            self.wrapped = wrapped
        }
    }
}

extension Parser.Optionally: Parser.`Protocol` {
    public typealias Input = Wrapped.Input
    public typealias Output = Wrapped.Output?
    public typealias Failure = Never

    // WORKAROUND: @_optimize(none) suppresses CopyPropagation false positive
    // on Property.View accessor chains (input.restore.to) in multiple control flow paths.
    // TRACKING: swift-buffer-primitives/Research/rawlayout-release-crash-investigation.md (Bug 2)
    @_optimize(none)
    @inlinable
    public func parse(_ input: inout Input) -> Output {
        let checkpoint = input.checkpoint
        do {
            return try wrapped.parse(&input)
        } catch {
            input.restore.to(__unchecked: (), checkpoint)
            return nil
        }
    }
}

// MARK: - Printer Conformance

extension Parser.Optionally: Parser.Printer
where Wrapped: Parser.Printer {
    @inlinable
    public func print(_ output: Wrapped.Output?, into input: inout Input) throws(Failure) {
        guard let output = output else { return }
        // WORKAROUND: Silently swallow printer errors
        // WHY: Optionally is infallible (Failure == Never) so we cannot propagate
        //   Wrapped.Failure. The type system prevents expressing partial failure here.
        // WHEN TO REMOVE: When Parser.Printer supports a separate Failure type from
        //   the parser's Failure, allowing the printer to throw independently.
        do {
            try wrapped.print(output, into: &input)
        } catch {}
    }
}
