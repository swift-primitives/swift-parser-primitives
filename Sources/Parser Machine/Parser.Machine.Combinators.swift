import Parser_Primitives
public import Machine_Primitives
public import Identity_Primitives

// MARK: - Pure

extension Parser.Machine {
    /// Creates a pure expression that always succeeds with the given value.
    @inlinable
    public static func pure<Input, Output, Failure>(
        _ value: Output,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, Output>
    where Input: Parser.Input & Sendable,
          Output: Sendable,
          Failure: Error & Sendable
    {
        let node = Node<Input, Failure>.pure(Value.make(value))
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Map

extension Parser.Machine.Expression {
    /// Transforms the output of this expression.
    @inlinable
    public func map<T: Sendable>(
        _ transform: @Sendable @escaping (Output) -> T,
        in builder: inout Parser.Machine.Builder<Input, Failure>
    ) -> Parser.Machine.Expression<Input, Failure, T> {
        let node = Parser.Machine.Node<Input, Failure>.map(
            child: self.node,
            transform: Parser.Machine.Transform.Erased(transform)
        )
        let nodeID = builder.allocate(node)
        return Parser.Machine.Expression(node: nodeID)
    }
}

// MARK: - TryMap

extension Parser.Machine.Expression {
    /// Transforms the output of this expression with a throwing function.
    @inlinable
    public func tryMap<T: Sendable>(
        _ transform: @Sendable @escaping (Output) throws(Failure) -> T,
        in builder: inout Parser.Machine.Builder<Input, Failure>
    ) -> Parser.Machine.Expression<Input, Failure, T> {
        Parser.Machine.tryMap(self, transform, in: &builder)
    }
}

extension Parser.Machine {
    /// Creates an expression that transforms its child's output with a throwing function.
    @inlinable
    public static func tryMap<Input, Output, Failure, NewOutput: Sendable>(
        _ expr: Expression<Input, Failure, Output>,
        _ transform: @Sendable @escaping (Output) throws(Failure) -> NewOutput,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, NewOutput>
    where Input: Parser.Input & Sendable,
          Failure: Error & Sendable
    {
        let node = Node<Input, Failure>.tryMap(
            child: expr.node,
            transform: Transform.Throwing(transform)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - FlatMap

extension Parser.Machine.Expression {
    /// Chains this expression with another that depends on its output.
    @inlinable
    public func flatMap<T>(
        _ next: @Sendable @escaping (Output) -> Parser.Machine.Expression<Input, Failure, T>,
        in builder: inout Parser.Machine.Builder<Input, Failure>
    ) -> Parser.Machine.Expression<Input, Failure, T> {
        typealias NodeID = Parser.Machine.Node<Input, Failure>.ID
        let node = Parser.Machine.Node<Input, Failure>.flatMap(
            child: self.node,
            next: Parser.Machine.Next.Erased { (output: Output) -> NodeID in
                NodeID(next(output).node.rawValue)
            }
        )
        let nodeID = builder.allocate(node)
        return Parser.Machine.Expression(node: nodeID)
    }
}

// MARK: - Sequence

extension Parser.Machine {
    /// Sequences two expressions and combines their outputs.
    @inlinable
    public static func sequence<Input, Failure, A, B, C: Sendable>(
        _ a: Expression<Input, Failure, A>,
        _ b: Expression<Input, Failure, B>,
        combine: @Sendable @escaping (A, B) -> C,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, C>
    where Input: Parser.Input & Sendable,
          Failure: Error & Sendable
    {
        let node = Node<Input, Failure>.sequence(
            a: a.node,
            b: b.node,
            combine: Combine.Erased(combine)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - OneOf

extension Parser.Machine {
    /// Creates an expression that tries alternatives in order until one succeeds.
    @inlinable
    public static func oneOf<Input, Failure, Output>(
        _ alternatives: [Expression<Input, Failure, Output>],
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, Output>
    where Input: Parser.Input & Sendable,
          Failure: Error & Sendable
    {
        let nodeIDs = alternatives.map { $0.node }
        let node = Node<Input, Failure>.oneOf(nodeIDs)
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Many

extension Parser.Machine {
    /// Creates an expression that parses zero or more occurrences.
    @inlinable
    public static func many<Input, Failure, T: Sendable>(
        _ expr: Expression<Input, Failure, T>,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, [T]>
    where Input: Parser.Input & Sendable,
          Failure: Error & Sendable
    {
        let node = Node<Input, Failure>.many(
            child: expr.node,
            finalize: Finalize.Array(T.self)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Optional

extension Parser.Machine {
    /// Creates an expression that optionally parses its child.
    @inlinable
    public static func optional<Input, Failure, T: Sendable>(
        _ expr: Expression<Input, Failure, T>,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, T?>
    where Input: Parser.Input & Sendable,
          Failure: Error & Sendable
    {
        let node = Node<Input, Failure>.optional(
            child: expr.node,
            wrapSome: Transform.Erased { (value: T) in Optional.some(value) },
            noneValue: Value.make(T?.none)
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}

// MARK: - Reference

extension Parser.Machine.Reference {
    /// Creates an expression from this reference, for use in recursive definitions.
    @inlinable
    public func expression(
        in builder: inout Parser.Machine.Builder<Input, Failure>
    ) -> Parser.Machine.Expression<Input, Failure, Output> {
        let node = Parser.Machine.Node<Input, Failure>.ref(self.node)
        let nodeID = builder.allocate(node)
        return Parser.Machine.Expression(node: nodeID)
    }
}
