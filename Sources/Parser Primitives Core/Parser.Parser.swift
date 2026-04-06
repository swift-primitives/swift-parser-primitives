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
    /// ## Declarative Composition
    ///
    /// Domain parsers can declare their grammar via ``body-swift.property``,
    /// composing existing parsers with output and error mapping:
    ///
    /// ```swift
    /// struct MediaTypeParser<Input: Collection.Slice.Protocol>: Parser.Protocol
    /// where Input: Sendable, Input.Element == UInt8 {
    ///     typealias Output = MediaType
    ///     typealias Failure = MediaTypeParser<Input>.Error
    ///
    ///     var body: some Parser.Protocol<Input, MediaType, Failure> {
    ///         Parser.Take.Sequence {
    ///             OWS<Input>()
    ///             Token<Input>()
    ///             Slash<Input>()
    ///             Token<Input>()
    ///         }
    ///         .map { (type, subtype) in MediaType(type, subtype) }
    ///         .error.map { either -> Failure in ... }
    ///     }
    /// }
    /// ```
    ///
    /// The default ``parse(_:)`` delegates to ``body-swift.property``.
    /// Leaf parsers implement ``parse(_:)`` directly; their ``Body`` is `Never`.
    ///
    /// ## Leaf Parser Example
    ///
    /// ```swift
    /// struct IntParser: Parser.`Protocol` {
    ///     typealias Input = Parser.Bytes.Input
    ///     typealias Output = Int
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
    public protocol `Protocol`<Input, Output, Failure> {
        /// The input type this parser consumes.
        ///
        /// Supports both escapable inputs (collections, cursors) and non-escapable
        /// inputs like `Span<UInt8>` for zero-copy borrowed parsing.
        associatedtype Input: ~Copyable & ~Escapable

        /// The output type this parser produces.
        associatedtype Output

        /// The error type this parser can throw.
        ///
        /// Use `Never` for infallible parsers.
        associatedtype Failure: Swift.Error

        /// The type of the composed parser body, or `Never` for leaf parsers.
        associatedtype Body

        /// The composed parser body.
        ///
        /// Override this property to declare a parser declaratively.
        /// Leaf parsers that implement ``parse(_:)`` directly do not
        /// override this property — the default returns `Never`.
        @Parser.Builder<Input>
        var body: Body { get }

        /// Parses a value from the input.
        ///
        /// On success, consumes the parsed portion from input and returns the result.
        /// On failure, throws an error. The input state after failure is undefined.
        ///
        /// - Parameter input: The input to parse from. Modified to reflect consumption.
        /// - Returns: The parsed value.
        /// - Throws: `Failure` if parsing fails.
        func parse(_ input: inout Input) throws(Failure) -> Output
    }
}

// MARK: - Leaf Parser Default (Body == Never)

extension Parser.`Protocol` where Body == Never {
    /// Leaf parsers do not have a body.
    @inlinable
    public var body: Never {
        fatalError("\(Self.self) is a leaf parser — implement parse(_:) directly")
    }
}

// MARK: - Declarative Parser Default (Body: Parser.Protocol)

extension Parser.`Protocol`
where Body: Parser.`Protocol`, Body.Input == Input,
      Body.Output == Output, Body.Failure == Failure
{
    /// Default parse implementation that delegates to ``body-swift.property``.
    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        try body.parse(&input)
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
