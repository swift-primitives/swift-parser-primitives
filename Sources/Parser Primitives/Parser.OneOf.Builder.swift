//
//  Parser.OneOf.Builder.swift
//  swift-standards
//
//  Result builder for alternative parsers.
//

extension Parser.OneOf {
    /// A result builder for alternative parsers.
    ///
    /// `Builder` combines parsers as alternatives - the first one that
    /// succeeds wins.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// Parser.OneOf.Sequence {
    ///     "true".map { true }
    ///     "false".map { false }
    /// }
    /// ```
    @resultBuilder
    public struct Builder<Input, ParseOutput> {}
}

extension Parser.OneOf.Builder {
    /// Builds a single alternative.
    @inlinable
    public static func buildBlock<P: Parser.`Protocol`>(
        _ parser: P
    ) -> P where P.Input == Input, P.ParseOutput == ParseOutput {
        parser
    }

    /// Combines two alternatives.
    @inlinable
    public static func buildBlock<P0: Parser.`Protocol`, P1: Parser.`Protocol`>(
        _ p0: P0,
        _ p1: P1
    ) -> Parser.OneOf.Two<P0, P1>
    where P0.Input == Input, P1.Input == Input,
          P0.ParseOutput == ParseOutput, P1.ParseOutput == ParseOutput {
        Parser.OneOf.Two(p0, p1)
    }

    /// Combines three alternatives.
    @inlinable
    public static func buildBlock<P0: Parser.`Protocol`, P1: Parser.`Protocol`, P2: Parser.`Protocol`>(
        _ p0: P0,
        _ p1: P1,
        _ p2: P2
    ) -> Parser.OneOf.Three<P0, P1, P2>
    where P0.Input == Input, P1.Input == Input, P2.Input == Input,
          P0.ParseOutput == ParseOutput, P1.ParseOutput == ParseOutput, P2.ParseOutput == ParseOutput {
        Parser.OneOf.Three(p0, p1, p2)
    }

    /// Starts partial block.
    @inlinable
    public static func buildPartialBlock<P: Parser.`Protocol`>(
        first: P
    ) -> P where P.Input == Input, P.ParseOutput == ParseOutput {
        first
    }

    /// Accumulates alternatives.
    @inlinable
    public static func buildPartialBlock<Accumulated: Parser.`Protocol`, Next: Parser.`Protocol`>(
        accumulated: Accumulated,
        next: Next
    ) -> Parser.OneOf.Two<Accumulated, Next>
    where Accumulated.Input == Input, Next.Input == Input,
          Accumulated.ParseOutput == ParseOutput, Next.ParseOutput == ParseOutput {
        Parser.OneOf.Two(accumulated, next)
    }
}
