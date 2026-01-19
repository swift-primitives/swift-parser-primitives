//
//  Machine.Prepared.swift
//  swift-parsing-primitives
//
//  Immutable compiled parser wrapper for cross-task sharing.
//

public import Machine_Primitives

extension Parsing.Machine {
    /// An immutable, pre-compiled parser wrapper.
    ///
    /// `Prepared` holds a fully compiled Machine program with no lazy state.
    /// It is conditionally `Sendable` and safe for cross-task sharing.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // From lazy Compiled
    /// let prepared = myParser.compiled(using: .leaf).prepared()
    ///
    /// // Direct preparation
    /// let prepared = myParser.prepared(using: .leaf)
    ///
    /// // Safe to share across tasks
    /// await withTaskGroup(of: Output.self) { group in
    ///     for input in inputs {
    ///         group.addTask {
    ///             var input = input
    ///             return try prepared.parse(&input)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Thread Safety
    ///
    /// `Prepared` is conditionally `Sendable` when `P` is `Sendable`.
    /// It contains no mutable state and is safe for concurrent use.
    public struct Prepared<P: Parsing.Parser>
    where P.Input: Parsing.Input & Sendable,
          P.Output: Sendable,
          P.Failure: Sendable
    {
        @usableFromInline
        let program: Program<P.Input, P.Failure>

        @usableFromInline
        let root: Node<P.Input, P.Failure>.ID

        /// Creates a prepared parser from a compiled program.
        ///
        /// - Parameters:
        ///   - program: The compiled Machine program.
        ///   - root: The root node ID for execution.
        @inlinable
        init(
            program: Program<P.Input, P.Failure>,
            root: Node<P.Input, P.Failure>.ID
        ) {
            self.program = program
            self.root = root
        }

        /// Creates a prepared parser by compiling the source parser.
        ///
        /// - Parameters:
        ///   - source: The parser to compile.
        ///   - witness: The compilation witness.
        @inlinable
        public init(source: P, witness: Compile.Witness<P>) {
            var builder = Builder<P.Input, P.Failure>()
            let expression = witness.compile(source, into: &builder)
            self.program = builder.program
            self.root = expression.node
        }
    }
}

// MARK: - Parser Conformance

extension Parsing.Machine.Prepared: Parsing.Parser {
    public typealias Input = P.Input
    public typealias Output = P.Output
    public typealias Failure = P.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try Parsing.Machine.run(program: program, root: root, input: &input, as: Output.self)
    }
}

// MARK: - Sendable Conformance
//
// Note: Prepared does NOT conform to Sendable because the underlying Machine.Program
// contains closures that may not be Sendable. For cross-task sharing, wrap in an
// explicit Sendable container with documented invariants, or use actors.
