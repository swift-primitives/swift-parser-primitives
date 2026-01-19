import Parsing_Primitives
public import Machine_Primitives
public import Identity_Primitives

extension Parsing.Machine {
    /// Program is a typealias to the core Machine.Program with Parsing's Leaf type.
    public typealias Program<Input: Parsing.Input, Failure: Error & Sendable> =
        Machine_Primitives.Machine.Program<Leaf<Input, Failure>, Failure>
        where Input: Sendable
}
