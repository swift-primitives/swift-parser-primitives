//
//  Parser.Optional.swift
//  swift-standards
//
//  Compile-time optional parser (for result builders).
//

extension Parser {
    /// A parser that optionally parses if its wrapped parser is present.
    ///
    /// Used by `Take.Builder` for `if` statements without `else`.
    public struct Optional<Wrapped: Parser.`Protocol`> {
        @usableFromInline
        let wrapped: Wrapped?

        @inlinable
        public init(_ wrapped: Wrapped?) {
            self.wrapped = wrapped
        }
    }
}

extension Parser.Optional: Parser.`Protocol` {
    public typealias Input = Wrapped.Input
    public typealias Output = Wrapped.Output?
    public typealias Failure = Wrapped.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard let wrapped = wrapped else {
            return nil
        }
        return try wrapped.parse(&input)
    }
}

// MARK: - Printer Conformance

extension Parser.Optional: Parser.Printer
where Wrapped: Parser.Printer {
    @inlinable
    public func print(_ output: Wrapped.Output?, into input: inout Input) throws(Failure) {
        guard let wrapped = wrapped, let output = output else { return }
        try wrapped.print(output, into: &input)
    }
}
