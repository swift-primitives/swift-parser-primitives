//
//  Pair+Parser.Printer.swift
//  swift-parser-primitives
//
//  Pair<First, Second> as a sequential parser printer (round-trip
//  symmetry for the Pair-as-Parser combinator).
//

extension Pair: Parser.Printer
where First: Parser.`Protocol` & Parser.Printer,
      Second: Parser.`Protocol` & Parser.Printer,
      First.Input == Second.Input
{
    @inlinable
    public borrowing func print(
        _ output: (First.Output, Second.Output),
        into input: inout First.Input
    ) throws(Either<First.Failure, Second.Failure>) {
        // Print in reverse order to build input correctly (last printer's
        // output appears latest in the input buffer; first printer's output
        // appears earliest).
        do {
            try second.print(output.1, into: &input)
        } catch {
            throw .right(error)
        }
        do {
            try first.print(output.0, into: &input)
        } catch {
            throw .left(error)
        }
    }
}
