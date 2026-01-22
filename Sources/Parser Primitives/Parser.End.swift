//
//  Parser.End.swift
//  swift-standards
//
//  End-of-input parser.
//

extension Parser {
    /// A parser that succeeds only at end of input.
    ///
    /// Consumes nothing and produces Void. Fails if input remains.
    public struct End<Input: Collection>: Sendable
    where Input: Sendable {
        @inlinable
        public init() {}
    }
}

extension Parser.End: Parser.`Protocol` {
    public typealias Output = Void
    public typealias Failure = Parser.Match.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) {
        guard input.isEmpty else {
            throw .expectedEnd(remaining: input.count)
        }
    }
}

// MARK: - Printer Conformance

extension Parser.End: Parser.Printer {
    @inlinable
    public func print(_ output: Void, into input: inout Input) {
        // End produces nothing - it's a marker
    }
}
