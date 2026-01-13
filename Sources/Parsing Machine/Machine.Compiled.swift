//
//  Machine.Compiled.swift
//  swift-parsing-primitives
//
//  Lazy-compiling parser wrapper with cached program.
//

extension Parsing.Machine {
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
    /// let compiled = myParser.compiled(using: .leaf)
    /// let result = try compiled.parse(&input)  // Compiles on first call
    /// let result2 = try compiled.parse(&input2) // Uses cached program
    /// ```
    ///
    /// ## Eager Compilation
    ///
    /// Use `prepared()` when deterministic timing is needed:
    /// ```swift
    /// let compiled = myParser.compiled(using: .leaf).prepared()
    /// // Benchmarking with consistent timing...
    /// ```
    ///
    /// ## Thread Safety
    ///
    /// `Compiled` is NOT `Sendable` by default. Use it within a single
    /// isolation domain. If cross-task sharing is needed, see the
    /// conditional `Sendable` conformance.
    public struct Compiled<P: Parsing.Parser>
    where P.Input: Parsing.Input & Sendable,
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

        /// Eagerly compiles the parser for deterministic timing.
        ///
        /// Call this when you need compilation to happen at a specific time
        /// rather than lazily on first parse.
        ///
        /// - Returns: This same parser (after compilation).
        @inlinable
        @discardableResult
        public func prepared() -> Self {
            _ = cache.getOrCompile(source: source, witness: witness)
            return self
        }
    }
}

// MARK: - Result

extension Parsing.Machine.Compiled {
    /// The cached compilation result.
    @usableFromInline
    struct Result {
        @usableFromInline
        let program: Parsing.Machine.Program<P.Input, P.Failure>

        @usableFromInline
        let root: Parsing.Machine.Node<P.Input, P.Failure>.ID

        @usableFromInline
        init(
            program: Parsing.Machine.Program<P.Input, P.Failure>,
            root: Parsing.Machine.Node<P.Input, P.Failure>.ID
        ) {
            self.program = program
            self.root = root
        }
    }
}

// MARK: - Cache

extension Parsing.Machine.Compiled {
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
            witness: Parsing.Machine.Compile.Witness<P>
        ) -> Result {
            if let existing = compiled {
                return existing
            }
            var builder = Parsing.Machine.Builder<P.Input, P.Failure>()
            let expression = witness.compile(source, into: &builder)
            let result = Result(
                program: builder.program,
                root: expression.node
            )
            compiled = result
            return result
        }
    }
}

// MARK: - Parser Conformance

extension Parsing.Machine.Compiled: Parsing.Parser {
    public typealias Input = P.Input
    public typealias Output = P.Output
    public typealias Failure = P.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let result = cache.getOrCompile(source: source, witness: witness)
        return try result.program.run(root: result.root, input: &input, as: Output.self)
    }
}

// MARK: - Sendable Conformance (Conditional)

// Uncomment when cross-task sharing is needed:
// extension Parsing.Machine.Compiled: @unchecked Sendable
// where P: Sendable { }
