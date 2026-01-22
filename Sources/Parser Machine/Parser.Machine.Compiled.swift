//
//  Machine.Compiled.swift
//  swift-parser-primitives
//
//  Lazy-compiling parser wrapper with cached program.
//

public import Machine_Primitives

extension Parser.Machine {
    /// A parser wrapper that lazily compiles to a Machine program.
    ///
    /// `Compiled` delays compilation until the first parse, then caches
    /// the compiled program for subsequent parses. This provides:
    /// - Zero overhead for parsers that are never used
    /// - Amortized compilation cost over multiple parses
    /// - Stack-safe execution for deeply nested structures
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var compiled = myParser.compiled(using: .leaf)
    /// let result = try compiled.parse(&input)  // Compiles on first call
    /// let result2 = try compiled.parse(&input2) // Uses cached program
    /// ```
    ///
    /// ## Thread Safety
    ///
    /// `Compiled` is NOT `Sendable`. Use it within a single isolation domain.
    /// For cross-task sharing, use `prepared()` which returns an immutable
    /// `Prepared` wrapper that is conditionally `Sendable`.
    ///
    /// ```swift
    /// let prepared = myParser.compiled(using: .leaf).prepared()
    /// // `prepared` can be shared across tasks
    /// ```
    public struct Compiled<P: Parser_Primitives.Parser.`Protocol`>
    where P.Input: Parser_Primitives.Parser.Input & Sendable,
          P.Output: Sendable,
          P.Failure: Sendable
    {
        @usableFromInline
        let source: P

        @usableFromInline
        let witness: Compile.Witness<P>

        @usableFromInline
        let cache: Cache

        /// Creates a compiled parser wrapper.
        ///
        /// - Parameters:
        ///   - source: The parser to compile.
        ///   - witness: The compilation witness.
        @inlinable
        public init(source: P, witness: Compile.Witness<P>) {
            self.source = source
            self.witness = witness
            self.cache = Cache()
        }

        /// Compiles eagerly and returns an immutable, shareable parser.
        ///
        /// The returned `Prepared` wrapper is conditionally `Sendable` and
        /// safe for cross-task sharing. Use this when you need to share
        /// a compiled parser across actors or concurrent operations.
        ///
        /// - Returns: An immutable prepared parser.
        @inlinable
        public func prepared() -> Prepared<P> {
            let result = cache.getOrCompile(source: source, witness: witness)
            return Prepared(program: result.program, root: result.root)
        }
    }
}

// MARK: - Result

extension Parser.Machine.Compiled {
    /// The cached compilation result.
    @usableFromInline
    struct Result {
        @usableFromInline
        let program: Parser.Machine.Program<P.Input, P.Failure>

        @usableFromInline
        let root: Parser.Machine.Node<P.Input, P.Failure>.ID

        @usableFromInline
        init(
            program: Parser.Machine.Program<P.Input, P.Failure>,
            root: Parser.Machine.Node<P.Input, P.Failure>.ID
        ) {
            self.program = program
            self.root = root
        }
    }
}

// MARK: - Cache

extension Parser.Machine.Compiled {
    /// Reference-type cache for lazy compilation.
    ///
    /// Not Sendable - use within single isolation domain.
    @usableFromInline
    final class Cache {
        @usableFromInline
        var compiled: Result?

        @usableFromInline
        init() {
            self.compiled = nil
        }

        @usableFromInline
        func getOrCompile(
            source: P,
            witness: Parser.Machine.Compile.Witness<P>
        ) -> Result {
            if let existing = compiled {
                return existing
            }
            var builder = Parser.Machine.Builder<P.Input, P.Failure>()
            let expression = witness.compile(source, into: &builder)
            let result = Result(
                program: builder.build(),
                root: expression.node
            )
            compiled = result
            return result
        }
    }
}

// MARK: - Parser Conformance

extension Parser.Machine.Compiled: Parser_Primitives.Parser.`Protocol` {
    public typealias Input = P.Input
    public typealias Output = P.Output
    public typealias Failure = P.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let result = cache.getOrCompile(source: source, witness: witness)
        return try Parser.Machine.run(program: result.program, root: result.root, input: &input, as: Output.self)
    }
}
