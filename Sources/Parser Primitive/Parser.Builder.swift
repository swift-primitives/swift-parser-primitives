//
//  Parser.Builder.swift
//  swift-parser-primitives
//
//  Result builder for declarative parser composition.
//

extension Parser {
    /// A result builder for composing parsers.
    ///
    /// `Builder` enables declarative parser composition using Swift's
    /// result builder syntax. It is the canonical builder for
    /// ``Parser/Protocol/body-swift.property``.
    ///
    /// Sequential composition, Void-skipping, tuple flattening,
    /// conditionals, and optionals are added via extensions in
    /// downstream modules.
    @resultBuilder
    public struct Builder<Input: ~Copyable & ~Escapable> {}
}

// MARK: - Single Expression (Pass-Through)

extension Parser.Builder {
    /// Wraps an expression in the builder context.
    @inlinable
    public static func buildExpression<P: Parser.`Protocol`>(
        _ parser: P
    ) -> P where P.Input == Input {
        parser
    }

    /// Builds a single parser unchanged.
    @inlinable
    public static func buildBlock<P: Parser.`Protocol`>(
        _ parser: P
    ) -> P where P.Input == Input {
        parser
    }

    /// Starts building a partial block.
    @inlinable
    public static func buildPartialBlock<P: Parser.`Protocol`>(
        first: P
    ) -> P where P.Input == Input {
        first
    }
}
