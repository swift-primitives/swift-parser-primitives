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
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> ParseOutput {
        output
    }
}
