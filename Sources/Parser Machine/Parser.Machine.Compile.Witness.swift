//
//  Machine.Compile.Witness.swift
//  swift-parser-primitives
//
//  Witness struct for parser compilation.
//

extension Parser.Machine {
    /// Namespace for compilation-related types.
    public enum Compile {}
}

extension Parser.Machine.Compile {
    /// A witness that knows how to compile a parser into a Machine expression.
    ///
    /// This is a value-based alternative to protocol conformance. Each parser
    /// type can have its own witness instance that provides compilation logic.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Create a witness for a specific parser
    /// let witness = Compile.Witness<MyParser> { parser, builder in
    ///     Machine.leaf(parser, in: &builder)
    /// }
    ///
    /// // Use it to compile
    /// let compiled = myParser.compiled(using: witness)
    /// ```
    public struct Witness<P: Parser.Parser>
    where P.Input: Parser.Input & Sendable,
          P.Output: Sendable,
          P.Failure: Sendable
    {
        @usableFromInline
        let _compile: (P, inout Parser.Machine.Builder<P.Input, P.Failure>) -> Parser.Machine.Expression<P.Input, P.Failure, P.Output>

        /// Creates a compilation witness.
        ///
        /// - Parameter compile: A closure that compiles a parser into a Machine expression.
        @inlinable
        public init(
            compile: @escaping (P, inout Parser.Machine.Builder<P.Input, P.Failure>) -> Parser.Machine.Expression<P.Input, P.Failure, P.Output>
        ) {
            self._compile = compile
        }

        /// Compiles the given parser using this witness.
        @inlinable
        public func compile(
            _ parser: P,
            into builder: inout Parser.Machine.Builder<P.Input, P.Failure>
        ) -> Parser.Machine.Expression<P.Input, P.Failure, P.Output> {
            _compile(parser, &builder)
        }
    }
}

// MARK: - Leaf Witness

extension Parser.Machine.Compile.Witness where P: Sendable {
    /// Creates a witness that compiles the parser as a leaf node.
    ///
    /// This wraps the parser's `parse` method directly, treating it as
    /// an opaque operation in the Machine program.
    @inlinable
    public static var leaf: Self {
        Self { parser, builder in
            Parser.Machine.leaf(parser, in: &builder)
        }
    }
}
