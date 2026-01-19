import Parser_Primitives
public import Identity_Primitives
public import Machine_Primitives

extension Parser.Machine {
    /// Creates a parser for a recursive grammar.
    ///
    /// The build closure receives a `Reference` that can be used to create recursive references.
    /// The closure must return an `Expression` that will be the root of the grammar.
    ///
    /// Example:
    /// ```swift
    /// let parser = Parser.Machine.recursive { builder, selfRef in
    ///     // Build grammar using `selfRef` for recursive references
    ///     ...
    /// }
    /// ```
    @inlinable
    public static func recursive<Input, Output, Failure>(
        maxDepth: Int? = nil,
        _ build: (inout Builder<Input, Failure>, Reference<Input, Failure, Output>) -> Expression<Input, Failure, Output>
    ) -> Parser<Input, Output, Failure>
    where Input: Parser.Input & Sendable,
          Output: Sendable,
          Failure: Error & Sendable
    {
        var builder = Builder<Input, Failure>(maxDepth: maxDepth)

        // Allocate a hole for the recursive reference
        let holeID = builder.allocate(.hole)
        let ref = Reference<Input, Failure, Output>(node: holeID)

        // Build the grammar
        let root = build(&builder, ref)

        // Patch the hole to point to the actual root
        builder.program[holeID] = .ref(root.node)

        return Parser(program: builder.program, root: root.node)
    }

    /// Creates a non-recursive parser from a builder closure.
    @inlinable
    public static func build<Input, Output, Failure>(
        _ build: (inout Builder<Input, Failure>) -> Expression<Input, Failure, Output>
    ) -> Parser<Input, Output, Failure>
    where Input: Parser.Input & Sendable,
          Output: Sendable,
          Failure: Error & Sendable
    {
        var builder = Builder<Input, Failure>()
        let root = build(&builder)
        return Parser(program: builder.program, root: root.node)
    }
}
