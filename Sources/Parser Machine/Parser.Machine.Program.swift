import Parser_Primitives
public import Machine_Primitives
public import Identity_Primitives

extension Parser.Machine {
    /// Program is a typealias to the core Machine.Program with Parsing's Leaf type.
    public typealias Program<Input: Parser_Primitives.Parser.Input, Failure: Error & Sendable> =
        Machine_Primitives.Machine.Program<Leaf<Input, Failure>, Failure, Machine_Primitives.Machine.Capture.Mode.Reference>
        where Input: Sendable
}
