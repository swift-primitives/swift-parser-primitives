//
//  Parser.Input.swift
//  swift-parser-primitives
//
//  Namespace and typealiases for parser input types from swift-input-primitives.
//

public import Array_Dynamic_Primitives
public import Collection_Primitives
public import Input_Primitives

extension Parser {
    /// Namespace for parser input types.
    ///
    /// ## Protocol Hierarchy
    ///
    /// ```
    /// Input.Streaming   ← minimal, forward-only (isEmpty, first, removeFirst)
    ///     ↑
    /// Input.Protocol    ← adds checkpoint/restore for backtracking
    /// ```
    ///
    /// ## Concrete Types
    ///
    /// - ``Input/Bytes``: Concrete input for parsing `[UInt8]` / UTF-8 strings
    /// - ``Input/Collection``: Generic input for any `Collection.Protocol`
    ///
    /// ## Constraint Bundles
    ///
    /// - ``Input/Stream``: `Collection.Slice.Protocol & Input.Streaming`
    public enum Input {}
}

extension Parser.Input {
    /// A type that can be used as input to a parser with backtracking support.
    ///
    /// This is a typealias to `Input.Protocol` from swift-input-primitives.
    ///
    /// ## Protocol Hierarchy
    ///
    /// ```
    /// Streaming   ← minimal, forward-only (isEmpty, first, removeFirst)
    ///     ↑
    ///   Protocol   ← adds checkpoint/restore for backtracking
    /// ```
    ///
    /// ## Checkpoint-Based Backtracking
    ///
    /// The `Checkpoint` associated type and related methods enable efficient
    /// backtracking without copying the entire input state:
    ///
    /// ```swift
    /// var input = Input_Primitives.Input.Slice([1, 2, 3, 4, 5])
    /// let checkpoint = input.checkpoint
    ///
    /// // Try to match something
    /// let a = input.removeFirst()  // 1
    /// let b = input.removeFirst()  // 2
    ///
    /// // Failed, restore position
    /// input.restore(to: checkpoint)
    /// assert(input.first == 1)  // Back at start
    /// ```
    ///
    /// ## Concrete Types
    ///
    /// Use `Input.Slice` for zero-copy parsing over collections:
    /// ```swift
    /// var input = Input_Primitives.Input.Slice(bytes[...])
    /// try parser.parse(&input)
    /// ```
    ///
    /// Use `Input.Buffer` for owned buffer parsing:
    /// ```swift
    /// var input = Input_Primitives.Input.Buffer([1, 2, 3, 4, 5])
    /// try parser.parse(&input)
    /// ```
    public typealias `Protocol` = Input_Primitives.Input.`Protocol`

    /// A type that can be used as streaming input to a parser.
    ///
    /// This is a typealias to `Input.Streaming` from swift-input-primitives.
    ///
    /// ## Forward-Only Parsing
    ///
    /// `Streaming` provides the minimal interface for forward-only parsing:
    /// - `isEmpty`: Check if input is exhausted
    /// - `advance()`: Consume and return the next element
    ///
    /// For backtracking support, use ``Protocol`` instead.
    public typealias Streaming = Input_Primitives.Input.Streaming

    /// Wrapper to use any Collection as parser input.
    ///
    /// This is a typealias to `Input.Slice` from swift-input-primitives.
    ///
    /// Provides O(1) slicing by tracking start/end indices:
    ///
    /// ```swift
    /// var input = Parser.Input.Collection(bytes[...])
    /// try parser.parse(&input)
    /// ```
    public typealias Collection<Base: Collection_Primitives.Collection.`Protocol`> = Input_Primitives.Input.Slice<Base>
    where Base: Sendable, Base.Index: Sendable

    /// Concrete input type for parsing byte arrays with parser combinators.
    ///
    /// Standard bridge from `[UInt8]` / `String.UTF8View` to the
    /// `Collection.Slice.Protocol`-constrained parser world.
    ///
    /// ```swift
    /// var input = Parser.Input.Bytes(utf8: "text/html; charset=utf-8")
    /// let result = try HTTP.MediaType.Parser<Parser.Input.Bytes>().parse(&input)
    /// ```
    public typealias Bytes = Input_Primitives.Input.Slice<Array<UInt8>.Indexed<UInt8>>

    /// Common constraint set for byte-stream parser inputs.
    ///
    /// Bundles `Collection.Slice.Protocol & Streaming`
    /// into a single name, reducing constraint boilerplate on parser definitions.
    ///
    /// ```swift
    /// // Before:
    /// struct Parser<Input: Collection.Slice.Protocol & Parser.Input.Streaming>
    /// where Input.Element == UInt8 { ... }
    ///
    /// // After:
    /// struct Parser<Input: Parser.Input.Stream>
    /// where Input.Element == UInt8 { ... }
    /// ```
    public typealias Stream = Collection_Primitives.Collection.Slice.`Protocol`
        & Streaming
}
