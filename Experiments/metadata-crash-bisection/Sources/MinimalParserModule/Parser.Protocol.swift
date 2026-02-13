extension Parser {
    public protocol `Protocol`<Input, ParseOutput, Failure> {
        associatedtype Input: ~Escapable
        associatedtype ParseOutput
        associatedtype Failure: Swift.Error & Sendable
        func parse(_ input: inout Input) throws(Failure) -> ParseOutput
    }
}
