// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-parsing open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp and the swift-parsing project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Effect_Primitives

extension Parser {
    /// Effect for non-deterministic choice in parsing.
    ///
    /// When performed, this effect suspends the current parse and allows
    /// a handler to explore multiple alternatives using multi-shot continuations.
    /// This enables declarative backtracking without manual checkpoint management.
    ///
    /// ## Motivation
    ///
    /// Traditional backtracking in `OneOf` combinators uses manual checkpoint/restore:
    ///
    /// ```swift
    /// // Current approach (manual)
    /// let saved = input
    /// do {
    ///     return try parser1.parse(&input)
    /// } catch {
    ///     input = saved  // Manual restore
    ///     return try parser2.parse(&input)
    /// }
    /// ```
    ///
    /// With effects, backtracking becomes declarative:
    ///
    /// ```swift
    /// // Effect-based approach
    /// let choice = try await Effect.perform(Parser.Backtrack(
    ///     alternatives: [parser1, parser2],
    ///     checkpoint: input.checkpoint
    /// ))
    /// ```
    ///
    /// ## Handler Semantics
    ///
    /// Handlers use `Effect.Continuation.Multi` to explore alternatives:
    ///
    /// ```swift
    /// struct BacktrackHandler: Effect.Handler.Protocol {
    ///     typealias Handled = Parser.Backtrack<MyInput, MyOutput>
    ///
    ///     func handle(
    ///         _ effect: Handled,
    ///         continuation: consuming Effect.Continuation.One<MyOutput, Parser.Error>
    ///     ) async {
    ///         for alternative in effect.alternatives {
    ///             var input = effect.checkpoint.restore()
    ///             do {
    ///                 let result = try alternative(&input)
    ///                 await continuation.resume(returning: result)
    ///                 return
    ///             } catch {
    ///                 continue  // Try next alternative
    ///             }
    ///         }
    ///         await continuation.resume(throwing: Parser.Error.noAlternativeMatched)
    ///     }
    /// }
    /// ```
    ///
    /// ## Use Cases
    ///
    /// - **Parser combinators**: `OneOf`, `Optional`, ambiguous grammars
    /// - **Search**: Explore multiple paths, backtrack on failure
    /// - **Testing**: Observe which alternatives were tried
    /// - **Profiling**: Measure backtracking frequency
    public struct Backtrack<Input: Parser.Input, Output: Sendable, E: Swift.Error & Sendable>: Effect.`Protocol` {
        public typealias Alternative = @Sendable (inout Input) throws(E) -> Output
        public typealias Arguments = [Alternative]
        public typealias Value = Output
        public typealias Failure = E

        /// The alternatives to try, in order.
        public let alternatives: [Alternative]

        /// The arguments for this effect (the alternatives).
        public var arguments: [Alternative] { alternatives }

        /// Creates a backtrack effect with the given alternatives.
        ///
        /// - Parameter alternatives: Closures representing parser alternatives.
        @inlinable
        public init(alternatives: [Alternative]) {
            self.alternatives = alternatives
        }

        /// Creates a backtrack effect from two parsers.
        ///
        /// - Parameters:
        ///   - first: The first parser to try.
        ///   - second: The fallback parser if the first fails.
        @inlinable
        public init(
            first: @escaping Alternative,
            second: @escaping Alternative
        ) {
            self.alternatives = [first, second]
        }
    }
}
