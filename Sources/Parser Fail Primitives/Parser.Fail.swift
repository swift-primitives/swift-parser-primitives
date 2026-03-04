//
//  Parser.Fail.swift
//  swift-standards
//
//  Always-failing parser.
//

extension Parser {
    /// A parser that always fails with a specified error.
    ///
    /// `Fail` is useful as a fallback in error handling scenarios.
    /// The error type is specified as a generic parameter.
    public struct Fail<Input, Output, F: Swift.Error & Sendable>: Sendable {
        @usableFromInline
        let error: F

        @inlinable
        public init(_ error: F) {
            self.error = error
        }
    }
}

extension Parser.Fail: Parser.`Protocol` {
    public typealias Failure = F

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        throw error
    }
}
