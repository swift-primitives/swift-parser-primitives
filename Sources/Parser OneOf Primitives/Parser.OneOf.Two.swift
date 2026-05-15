//
//  Parser.OneOf.Two.swift
//  swift-standards
//
//  Two-parser alternative combinator.
//

extension Parser.OneOf {
    /// A parser that tries two alternatives.
    ///
    /// Type-safe variant for exactly two parsers. Used by result builders.
    public struct Two<P0: Parser.`Protocol`, P1: Parser.`Protocol`>
    where
        P0.Input == P1.Input,
        P0.Output == P1.Output,
        P0.Input: Input_Primitives.Input.`Protocol`
    {
        @usableFromInline
        let p0: P0

        @usableFromInline
        let p1: P1

        @inlinable
        public init(_ p0: P0, _ p1: P1) {
            self.p0 = p0
            self.p1 = p1
        }
    }
}

extension Parser.OneOf.Two: Parser.`Protocol` {
    public typealias Input = P0.Input
    public typealias Output = P0.Output
    public typealias Failure = Product<P0.Failure, P1.Failure>

    // on Property.Inout accessor chains (input.restore.to) in multiple control flow paths.
    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let checkpoint = input.checkpoint

        do {
            return try p0.parse(&input)
        } catch let error0 {
            input.restore.to(__unchecked: (), checkpoint)
            do {
                return try p1.parse(&input)
            } catch let error1 {
                throw Failure(error0, error1)
            }
        }
    }
}

// MARK: - Printer Conformance

extension Parser.OneOf.Two: Parser.Printer
where P0: Parser.Printer, P1: Parser.Printer {
    @inlinable
    public func print(_ output: Output, into input: inout Input) throws(Failure) {
        // Try first printer, fall back to second
        let checkpoint = input.checkpoint
        do {
            try p0.print(output, into: &input)
            return
        } catch let error0 {
            input.restore.to(__unchecked: (), checkpoint)
            do {
                try p1.print(output, into: &input)
            } catch let error1 {
                throw Failure(error0, error1)
            }
        }
    }
}
