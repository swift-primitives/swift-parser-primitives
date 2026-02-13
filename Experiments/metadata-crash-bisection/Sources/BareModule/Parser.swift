public enum Parser {}

extension Parser {
    // No ~Escapable, no Failure constraint — absolute minimum protocol
    public protocol `Protocol` {
        associatedtype Input
        associatedtype ParseOutput
        func parse(_ input: inout Input) -> ParseOutput
    }
}

extension Parser {
    public struct Always<Input, ParseOutput>: Sendable where ParseOutput: Sendable {
        public let output: ParseOutput

        @inlinable
        public init(_ output: ParseOutput) {
            self.output = output
        }
    }
}

extension Parser.Always: Parser.`Protocol` {
    @inlinable
    public func parse(_ input: inout Input) -> ParseOutput {
        output
    }
}
