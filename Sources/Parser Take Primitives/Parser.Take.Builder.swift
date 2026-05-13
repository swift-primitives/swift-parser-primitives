//
//  Parser.Take.Builder.swift
//  swift-standards
//
//  Result builder for sequential parser composition.
//

extension Parser.Take {
    /// A result builder for composing parsers sequentially.
    ///
    /// `Builder` enables declarative parser composition using Swift's
    /// result builder syntax. Parsers are combined sequentially, with their
    /// outputs collected into tuples.
    ///
    /// ## Sequential Composition
    ///
    /// Multiple parsers run in sequence. Outputs are combined into tuples:
    ///
    /// ```swift
    /// Parser.Take.Sequence {
    ///     IntParser()      // Output: Int
    ///     ","              // Output: Void (discarded)
    ///     IntParser()      // Output: Int
    /// }
    /// // Result: (Int, Int)
    /// ```
    ///
    /// ## Void Skipping
    ///
    /// Parsers with `Void` output are automatically skipped in the result tuple.
    @resultBuilder
    public struct Builder<Input: ~Copyable & ~Escapable> {}
}

// MARK: - Empty and Single Block

extension Parser.Take.Builder {
    /// Builds an empty parser that consumes nothing and returns Void.
    @inlinable
    public static func buildBlock() -> Parser.Always<Input, Void> {
        Parser.Always(())
    }

    /// Builds a single parser unchanged.
    @inlinable
    public static func buildBlock<P: Parser.`Protocol`>(
        _ parser: P
    ) -> P where P.Input == Input {
        parser
    }
}

// MARK: - Two Parsers

extension Parser.Take.Builder {
    /// Combines two parsers sequentially.
    @inlinable
    public static func buildBlock<P0: Parser.`Protocol`, P1: Parser.`Protocol`>(
        _ p0: P0,
        _ p1: P1
    ) -> Parser.Take.Two<P0, P1>
    where P0.Input == Input, P1.Input == Input {
        Parser.Take.Two(p0, p1)
    }

    /// Combines parsers, skipping Void output from first.
    @inlinable
    public static func buildBlock<P0: Parser.`Protocol`, P1: Parser.`Protocol`>(
        _ p0: P0,
        _ p1: P1
    ) -> Parser.Skip.First<P0, P1>
    where P0.Input == Input, P1.Input == Input, P0.Output == Void {
        Parser.Skip.First(p0, p1)
    }

    /// Combines parsers, skipping Void output from second.
    @inlinable
    public static func buildBlock<P0: Parser.`Protocol`, P1: Parser.`Protocol`>(
        _ p0: P0,
        _ p1: P1
    ) -> Parser.Skip.Second<P0, P1>
    where P0.Input == Input, P1.Input == Input, P1.Output == Void {
        Parser.Skip.Second(p0, p1)
    }
}

// MARK: - Partial Block Building

extension Parser.Take.Builder {
    /// Starts building a partial block.
    @inlinable
    public static func buildPartialBlock<P: Parser.`Protocol`>(
        first: P
    ) -> P where P.Input == Input {
        first
    }

    /// Accumulates into partial block (general case - two elements).
    @_disfavoredOverload
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Take.Two<Accumulated, Next>
    where Accumulated.Input == Input, Next.Input == Input {
        Parser.Take.Two(accumulated, next)
    }

    /// Accumulates with tuple flattening using parameter packs.
    ///
    /// This enables unlimited parser composition by flattening nested tuples:
    /// `((A, B), C)` becomes `(A, B, C)`.
    @inlinable
    public static func buildPartialBlock<
        Accumulated: Parser.`Protocol`,
        Next: Parser.`Protocol`,
        each O1,
        O2
    >(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Take.Two<Accumulated, Next>.Map<(repeat each O1, O2)>
    where
        Accumulated.Input == Input,
        Next.Input == Input,
        Accumulated.Output == (repeat each O1),
        Next.Output == O2
    {
        Parser.Take.Two(accumulated, next)
            .map { tuple, next in
                (repeat each tuple, next)
            }
    }

    /// Accumulates with Void skipping (accumulated is Void).
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Skip.First<Accumulated, Next>
    where Accumulated.Input == Input, Next.Input == Input, Accumulated.Output == Void {
        Parser.Skip.First(accumulated, next)
    }

    /// Accumulates with Void skipping (next is Void).
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.Skip.Second<Accumulated, Next>
    where Accumulated.Input == Input, Next.Input == Input, Next.Output == Void {
        Parser.Skip.Second(accumulated, next)
    }
}

// MARK: - Conditionals

extension Parser.Take.Builder {
    /// Builds an optional parser from an `if` statement.
    @inlinable
    public static func buildIf<P: Parser.`Protocol`>(
        _ parser: P?
    ) -> Parser.Optional<P> where P.Input == Input {
        .init(parser)
    }

    /// Builds the first branch of if-else.
    @inlinable
    public static func buildEither<First: Parser.`Protocol`, Second: Parser.`Protocol`>(
        first: First
    ) -> Parser.Conditional<First, Second>
    where First.Input == Input, Second.Input == Input, First.Output == Second.Output {
        Parser.Conditional.first(first)
    }

    /// Builds the second branch of if-else.
    @inlinable
    public static func buildEither<First: Parser.`Protocol`, Second: Parser.`Protocol`>(
        second: Second
    ) -> Parser.Conditional<First, Second>
    where First.Input == Input, Second.Input == Input, First.Output == Second.Output {
        Parser.Conditional.second(second)
    }
}

// MARK: - Expressions

extension Parser.Take.Builder {
    /// Wraps an expression in the builder context.
    @inlinable
    public static func buildExpression<P: Parser.`Protocol`>(
        _ parser: P
    ) -> P where P.Input == Input {
        parser
    }
}

// MARK: - String Literal Support

extension Parser.Take.Builder
where Input: Parser.Input.Streaming, Input.Element == UInt8 {
    /// Enables bare string literals as `Parser.Literal` in builder bodies.
    ///
    /// ```swift
    /// Parser.Take.Sequence {
    ///     ASCII.Decimal.Parser<_, UInt16>()
    ///     ":"                                  // ← inferred as Parser.Literal<Input>
    ///     ASCII.Decimal.Parser<_, UInt16>()
    /// }
    /// ```
    @inlinable
    public static func buildExpression(
        _ literal: Parser.Literal<Input>
    ) -> Parser.Literal<Input> {
        literal
    }

    /// Re-declared generic pass-through for constrained extension.
    ///
    /// Without this, the `Parser.Literal` overload above shadows the
    /// generic `buildExpression` from the unconstrained extension,
    /// causing non-literal parsers to fail type-checking.
    @inlinable
    public static func buildExpression<P: Parser.`Protocol`>(
        _ parser: P
    ) -> P where P.Input == Input {
        parser
    }
}

// MARK: - Byte Array Literal Support

extension Parser.Take.Builder where Input == ArraySlice<UInt8> {
    /// Converts a `[UInt8]` array literal to a parser.
    ///
    /// This enables using byte arrays directly in builders:
    /// ```swift
    /// Parser.Many.Separated(1...) {
    ///     element
    /// } separator: {
    ///     [0x2C]  // Comma byte
    /// }
    /// ```
    @inlinable
    public static func buildExpression(_ bytes: [UInt8]) -> [UInt8] {
        bytes
    }
}
