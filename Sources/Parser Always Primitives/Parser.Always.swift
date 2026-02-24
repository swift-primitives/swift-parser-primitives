//
//  Parser.Always.swift
//  swift-standards
//
//  Always-succeeding parser.
//

extension Parser {
    /// A parser that always succeeds without consuming input.
    ///
    /// `Always` is useful as an identity element and for injecting values.
    public struct Always<Input, ParseOutput>: Sendable where ParseOutput: Sendable {
        public let output: ParseOutput

        @inlinable
        public init(_ output: ParseOutput) {
            self.output = output
        }
    }
}

extension Parser.Always: Parser.`Protocol` {
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> ParseOutput {
        output
    }
}

// MARK: - Printer Conformance (Void only)

extension Parser.Always: Parser.Printer where ParseOutput == Void {
    @inlinable
    public func print(_ output: Void, into input: inout Input) {
        // Always produces value without consuming/producing input
    }
}
