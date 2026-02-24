//
//  Parser.Parser.swift
//  swift-parser-primitives
//
//  Core Parser protocol definition.
//

public import Collection_Primitives

extension Parser {
    /// A type that can parse a value from an input.
    ///
    /// Parsers are composable: complex parsers are built from simpler ones using
    /// combinators like `map`, `flatMap`, `oneOf`, and result builders.
    ///
    /// ## Input Mutation
    ///
    /// The `parse` method takes `inout Input` and consumes from the front.
    /// On success, the input is advanced past the consumed portion.
    /// On failure, the input state is undefined (callers should save/restore if needed).
    ///
    /// ## Performance
    ///
    /// The protocol is designed for zero-copy, non-allocating parsing:
    /// - Input types like `Span<UInt8>` provide O(1) slicing
    /// - Index-based consumption avoids copying data
    /// - Result builders inline parser composition
    ///
    /// ## Error Handling
    ///
    /// Parsers use typed throws with a `Failure` associated type for precise,
    /// domain-specific error propagation. Combinators compose error types:
    /// - `Map` preserves the upstream `Failure`
    /// - `FlatMap` produces `Either<Upstream.Failure, Downstream.Failure>`
    /// - `OneOf` produces `Either<P0.Failure, P1.Failure>`
    /// - Infallible parsers use `Failure == Never`
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct IntParser: Parser.`Protocol` {
    ///     typealias Input = Parser.Bytes.Input
    ///     typealias ParseOutput = Int
    ///     typealias Failure = Parser.Match.Error
    ///
    ///     func parse(_ input: inout Input) throws(Failure) -> Int {
    ///         var value = 0
    ///         var consumed = false
    ///
    ///         while let byte = input.first, byte >= 0x30, byte <= 0x39 {
    ///             value = value * 10 + Int(byte - 0x30)
    ///             input.removeFirst()
    ///             consumed = true
    ///         }
    ///
    ///         guard consumed else {
    ///             throw .predicateFailed(description: "digit")
    ///         }
    ///         return value
    ///     }
    /// }
    /// ```
    public protocol `Protocol`<Input, ParseOutput, Failure> {
        /// The input type this parser consumes.
        ///
        /// Supports both escapable inputs (collections, cursors) and non-escapable
        /// inputs like `Span<UInt8>` for zero-copy borrowed parsing.
        associatedtype Input: ~Escapable

        /// The output type this parser produces.
        associatedtype ParseOutput

        /// The error type this parser can throw.
        ///
        /// Use `Never` for infallible parsers.
        associatedtype Failure: Swift.Error & Sendable

        /// Parses a value from the input.
        ///
        /// On success, consumes the parsed portion from input and returns the result.
        /// On failure, throws an error. The input state after failure is undefined.
        ///
        /// - Parameter input: The input to parse from. Modified to reflect consumption.
        /// - Returns: The parsed value.
        /// - Throws: `Failure` if parsing fails.
        func parse(_ input: inout Input) throws(Failure) -> ParseOutput
    }
}

// MARK: - Remaining Count

extension Collection.Slice.`Protocol` {
    /// Counts remaining elements by walking indices.
    ///
    /// Used for error reporting when a typed count is not available.
    public var remainingCount: Int {
        var count = 0
        var i = startIndex
        while i < endIndex {
            i = index(after: i)
            count += 1
        }
        return count
    }
}
