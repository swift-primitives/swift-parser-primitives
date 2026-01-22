import Parser_Primitives
public import Machine_Primitives
public import Identity_Primitives

extension Parser.Machine {
    /// Node is a typealias to the core Machine.Node with Parsing's Leaf type.
    public typealias Node<Input: Parser_Primitives.Parser.Input, Failure: Error & Sendable> =
        Machine_Primitives.Machine.Node<Leaf<Input, Failure>, Failure, Machine_Primitives.Machine.Capture.Mode.Reference>
        where Input: Sendable

    /// Parsing-specific leaf: a closure-based parser operation.
    @safe
    public struct Leaf<Input: Parser_Primitives.Parser.Input, Failure: Error & Sendable>: @unchecked Sendable
    where Input: Sendable {
        @usableFromInline
        let run: @Sendable (inout Input) throws(Failure) -> Value

        @usableFromInline
        init(_ run: @Sendable @escaping (inout Input) throws(Failure) -> Value) {
            self.run = run
        }
    }
}
