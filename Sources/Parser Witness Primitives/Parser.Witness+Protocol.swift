//
//  Parser.Witness+Protocol.swift
//  swift-parser-primitives
//
//  Conformance of the closure-backed Parser.Witness to Parser.Protocol.
//
//  RELOCATION NOTE (Windows/Embedded SIL-verifier fix): this conformance —
//  and the `Parser.Witness` struct it conforms — live in the dedicated
//  `Parser Witness Primitives` target, NOT in `Parser Primitive` (the module
//  that defines ``Parser/Protocol``). `Parser.Witness` is the only
//  `Body == Never` leaf conformer in the package; keeping it out of the
//  defining module means the `@inlinable` leaf-default `var body: Never`
//  `read` accessor is never serialized into `Parser_Primitive` and thus never
//  re-emitted BODYLESS into consumer leaf modules (Trace, Lazy, Parse, …).
//  With an in-defining-module conformer present, that bodyless
//  `shared [serialized]` accessor crashes SIL verification on Windows
//  (+Asserts), Embedded, and any `-sil-verify-all` build with
//  "Must have a construct to emit for" / "function must have a body". Mirrors
//  the swift-serializer-primitives fix (a652cec). Dossier:
//  swift-institute/Issues/swift-issue-noncopyable-assoctype-never-bodyless-witness
//

extension Parser.Witness: Parser.`Protocol` where Input: ~Copyable & ~Escapable {
    public typealias Body = Never

    @inlinable
    public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
        try _parse(&input)
    }
}
