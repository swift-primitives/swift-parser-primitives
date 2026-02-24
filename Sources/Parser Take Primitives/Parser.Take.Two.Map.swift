//
//  Parser.Take.Two.Map.swift
//  swift-standards
//
//  Map transformation for Take.Two output.
//

extension Parser.Take.Two {
    /// A parser that transforms the output of a `Take.Two` parser.
    ///
    /// Used internally for tuple flattening with parameter packs.
    public struct Map<NewOutput>: Sendable
    where P0: Sendable, P1: Sendable {
        @usableFromInline
        let upstream: Parser.Take.Two<P0, P1>

        @usableFromInline
        let transform: @Sendable (P0.ParseOutput, P1.ParseOutput) -> NewOutput

        @inlinable
        init(
            upstream: Parser.Take.Two<P0, P1>,
            transform: @escaping @Sendable (P0.ParseOutput, P1.ParseOutput) -> NewOutput
        ) {
            self.upstream = upstream
            self.transform = transform
        }
    }
}

extension Parser.Take.Two.Map: Parser.`Protocol` {
    public typealias Input = P0.Input
    public typealias ParseOutput = NewOutput
    public typealias Failure = Parser.Take.Two<P0, P1>.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        let (o0, o1) = try upstream.parse(&input)
        return transform(o0, o1)
    }
}
