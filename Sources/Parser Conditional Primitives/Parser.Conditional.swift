//
//  Parser.Conditional.swift
//  swift-standards
//
//  Conditional branch parser (for result builders).
//

extension Parser {
    /// A parser that represents a conditional branch.
    ///
    /// Used by `Take.Builder` for `if-else` statements.
    public enum Conditional<First: Parser.`Protocol`, Second: Parser.`Protocol`>: Sendable
    where
        First: Sendable,
        Second: Sendable,
        First.Input == Second.Input,
        First.Output == Second.Output
    {
        case first(First)
        case second(Second)
    }
}

extension Parser.Conditional: Parser.`Protocol` {
    public typealias Input = First.Input
    public typealias Output = First.Output
    public typealias Failure = Either<First.Failure, Second.Failure>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        switch self {
        case .first(let parser):
            do {
                return try parser.parse(&input)
            } catch {
                throw .left(error)
            }
        case .second(let parser):
            do {
                return try parser.parse(&input)
            } catch {
                throw .right(error)
            }
        }
    }
}

// MARK: - Printer Conformance

extension Parser.Conditional: Parser.Printer
where First: Parser.Printer, Second: Parser.Printer {
    @inlinable
    public func print(_ output: Output, into input: inout Input) throws(Failure) {
        switch self {
        case .first(let printer):
            do {
                try printer.print(output, into: &input)
            } catch {
                throw .left(error)
            }
        case .second(let printer):
            do {
                try printer.print(output, into: &input)
            } catch {
                throw .right(error)
            }
        }
    }
}
