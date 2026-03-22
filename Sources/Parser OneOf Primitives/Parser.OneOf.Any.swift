//
//  Parser.OneOf.Any.swift
//  swift-standards
//
//  Type-erased alternative parser.
//

extension Parser.OneOf {
    /// A parser that tries multiple alternatives in order.
    ///
    /// `Any` attempts each parser in sequence. The first parser that succeeds
    /// determines the result. If all parsers fail, it fails with an error
    /// aggregating all the individual failures.
    ///
    /// ## Backtracking
    ///
    /// By default, saves and restores input state between attempts.
    /// This enables clean backtracking when an alternative fails partway through.
    public struct `Any`<Input: Parser.Input.`Protocol`, Output>: Sendable {
        @usableFromInline
        let parsers: [@Sendable (inout Input) throws(Error) -> Output]

        @inlinable
        public init(_ parsers: [@Sendable (inout Input) throws(Error) -> Output]) {
            self.parsers = parsers
        }
    }
}

// MARK: - Error Type

extension Parser.OneOf.`Any` {
    /// Type-erased error for `OneOf.Any`.
    ///
    /// Since `Any` uses type-erased closures, it needs a common error type
    /// to aggregate failures from heterogeneous parsers.
    public struct Error: Swift.Error, Sendable, Equatable {
        /// Description of the failure.
        public let message: String

        /// Errors from each attempted alternative.
        public let underlying: [Error]

        @inlinable
        public init(_ message: String, underlying: [Error] = []) {
            self.message = message
            self.underlying = underlying
        }

        /// Creates an error for no matching alternative.
        @inlinable
        public static func noMatch(tried errors: [Error]) -> Self {
            Self("No matching alternative", underlying: errors)
        }
    }
}

// MARK: - Parser Conformance

extension Parser.OneOf.`Any`: Parser.`Protocol` {
    public typealias Failure = Error

    // WORKAROUND: @_optimize(none) suppresses CopyPropagation false positive.
    // TRACKING: swift-buffer-primitives/Research/rawlayout-release-crash-investigation.md (Bug 2)
    @_optimize(none)
    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        var errors: [Error] = []
        let checkpoint = input.checkpoint

        for parser in parsers {
            do {
                return try parser(&input)
            } catch {
                errors.append(error)
                input.restore.to(__unchecked: (), checkpoint)
            }
        }

        throw .noMatch(tried: errors)
    }
}
