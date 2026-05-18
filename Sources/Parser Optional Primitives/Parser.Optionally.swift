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
    public struct Optionally<Wrapped: Parser.`Protocol`>
    where Wrapped.Input: Input_Primitives.Input.`Protocol` {
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

    // on Property.Inout accessor chains (input.restore.to) in multiple control flow paths.
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
        guard let output else { return }
        // Four-part template complete (WORKAROUND / WHY / WHEN TO REMOVE / TRACKING)
        // below; the SwiftLint regex is a manual-check prompt that fires on every
        // WORKAROUND marker (`//\s*WORKAROUND:`), not a four-part-template validator.
        // The full template check is deferred to a future AST swift-linter F-rule
        // per the institute config's Wave 2b decision 1.
        // swiftlint:disable:next workaround_marker_present
        // WORKAROUND: Silently swallow printer errors
        // WHY: Optionally is infallible (Failure == Never) so we cannot propagate
        //   Wrapped.Failure. The type system prevents expressing partial failure here.
        // WHEN TO REMOVE: When Parser.Printer supports a separate Failure type from
        //   the parser's Failure, allowing the printer to throw independently.
        // TRACKING: Parser.Printer ABI — no upstream Swift Evolution proposal yet.
        do {
            try wrapped.print(output, into: &input)
        } catch {}
    }
}
