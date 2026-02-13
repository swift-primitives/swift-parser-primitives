extension Parser {
    // NOTE: No ~Escapable on Input — diagnostic experiment
    public protocol `Protocol`<Input, ParseOutput, Failure> {
        associatedtype Input
        associatedtype ParseOutput
        associatedtype Failure: Swift.Error & Sendable
        func parse(_ input: inout Input) throws(Failure) -> ParseOutput
    }
}
