import Parsing_Primitives
import Identity_Primitives

extension Parsing.Machine {
    /// Creates a leaf expression that wraps an existing parser.
    @inlinable
    public static func leaf<Input, Output, Failure, P>(
        _ parser: P,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, Output>
    where P: Parsing.Parser & Sendable,
          P.Input == Input,
          P.Output == Output,
          P.Failure == Failure,
          Input: Parsing.Input & Sendable,
          Output: Sendable,
          Failure: Error & Sendable
    {
        let node = Node<Input, Failure>.leaf(Leaf { (input: inout Input) throws(Failure) -> Value in
            Value.make(try parser.parse(&input))
        })
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates a leaf expression that wraps an existing parser with error mapping.
    @inlinable
    public static func leaf<Input, Output, Failure, P>(
        _ parser: P,
        mapError: @Sendable @escaping (P.Failure) -> Failure,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, Output>
    where P: Parsing.Parser & Sendable,
          P.Input == Input,
          P.Output == Output,
          Input: Parsing.Input & Sendable,
          Output: Sendable,
          Failure: Error & Sendable
    {
        let node = Node<Input, Failure>.leaf(Leaf { (input: inout Input) throws(Failure) -> Value in
            do throws(P.Failure) {
                return Value.make(try parser.parse(&input))
            } catch {
                throw mapError(error)
            }
        })
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}
