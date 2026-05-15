//
//  Parser.OneOf.Three.swift
//  swift-standards
//
//  Three-parser alternative combinator.
//

extension Parser.OneOf {
    /// A parser that tries three alternatives.
    public struct Three<P0: Parser.`Protocol`, P1: Parser.`Protocol`, P2: Parser.`Protocol`>
    where
        P0.Input == P1.Input,
        P1.Input == P2.Input,
        P0.Output == P1.Output,
        P1.Output == P2.Output,
        P0.Input: Input_Primitives.Input.`Protocol`
    {
        @usableFromInline
        let p0: P0

        @usableFromInline
        let p1: P1

        @usableFromInline
        let p2: P2

        @inlinable
        public init(_ p0: P0, _ p1: P1, _ p2: P2) {
            self.p0 = p0
            self.p1 = p1
            self.p2 = p2
        }
    }
}

extension Parser.OneOf.Three: Parser.`Protocol` {
    public typealias Input = P0.Input
    public typealias Output = P0.Output
    public typealias Failure = Product<P0.Failure, P1.Failure, P2.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let checkpoint = input.checkpoint

        do { return try p0.parse(&input) } catch let error0 {
            input.restore.to(__unchecked: (), checkpoint)
            do { return try p1.parse(&input) } catch let error1 {
                input.restore.to(__unchecked: (), checkpoint)
                do { return try p2.parse(&input) } catch let error2 {
                    throw Failure(error0, error1, error2)
                }
            }
        }
    }
}

// MARK: - Printer Conformance

extension Parser.OneOf.Three: Parser.Printer
where P0: Parser.Printer, P1: Parser.Printer, P2: Parser.Printer {
    @inlinable
    public func print(_ output: Output, into input: inout Input) throws(Failure) {
        // Try each printer in order, use first that succeeds
        let checkpoint = input.checkpoint

        do {
            try p0.print(output, into: &input)
            return
        } catch let error0 {
            input.restore.to(__unchecked: (), checkpoint)
            do {
                try p1.print(output, into: &input)
                return
            } catch let error1 {
                input.restore.to(__unchecked: (), checkpoint)
                do {
                    try p2.print(output, into: &input)
                } catch let error2 {
                    throw Failure(error0, error1, error2)
                }
            }
        }
    }
}
