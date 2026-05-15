//
//  Parser.Witness+Protocol.swift
//  swift-parser-primitives
//
//  Conformance of the closure-backed Parser.Witness to Parser.Protocol.
//
//  The witness struct is declared in `Parser Namespace` so the bare
//  storage shape lives without any protocol dependency; the conformance and
//  witness methods are declared here, in the `Parser Primitives Core`
//  target where ``Parser/Protocol`` is defined.
//

extension Parser.Witness: Parser.`Protocol` where Input: ~Copyable & ~Escapable {
    public typealias Body = Never

    @inlinable
    public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
        try _parse(&input)
    }
}
