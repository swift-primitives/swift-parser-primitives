//
//  Parsing.Input.swift
//  swift-parsing-primitives
//
//  Typealiases for Input protocols from swift-input-primitives.
//

public import Input_Primitives

extension Parsing {
    /// A type that can be used as streaming input to a parser.
    ///
    /// This is a typealias to `Input.Streaming` from swift-input-primitives.
    ///
    /// ## Forward-Only Parsing
    ///
    /// `Streaming` provides the minimal interface for forward-only parsing:
    /// - `isEmpty`: Check if input is exhausted
    /// - `first`: Peek at the next element without consuming
    /// - `removeFirst()`: Consume and return the next element
    ///
    /// For backtracking support, use ``Input`` instead.
    public typealias Streaming = Input_Primitives.Input.Streaming

    /// A type that can be used as input to a parser with backtracking support.
    ///
    /// This is a typealias to `Input.Protocol` from swift-input-primitives.
    ///
    /// ## Protocol Hierarchy
    ///
    /// ```
    /// Streaming   ← minimal, forward-only (isEmpty, first, removeFirst)
    ///     ↑
    ///   Input     ← adds checkpoint/restore for backtracking
    /// ```
    ///
    /// ## Checkpoint-Based Backtracking
    ///
    /// The `Checkpoint` associated type and related methods enable efficient
    /// backtracking without copying the entire input state:
    ///
    /// ```swift
    /// var input = Input.Slice([1, 2, 3, 4, 5])
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
    /// var input = Input.Slice(bytes[...])
    /// try parser.parse(&input)
    /// ```
    ///
    /// Use `Input.Buffer` for owned buffer parsing:
    /// ```swift
    /// var input = Input.Buffer([1, 2, 3, 4, 5])
    /// try parser.parse(&input)
    /// ```
    public typealias Input = Input_Primitives.Input.`Protocol`

    /// Wrapper to use any Collection as parser input.
    ///
    /// This is a typealias to `Input.Slice` from swift-input-primitives.
    ///
    /// Provides O(1) slicing by tracking start/end indices:
    ///
    /// ```swift
    /// var input = Parsing.CollectionInput(bytes[...])
    /// try parser.parse(&input)
    /// ```
    public typealias CollectionInput<Base: Collection> = Input_Primitives.Input.Slice<Base>
        where Base: Sendable, Base.Index: Sendable
}

// MARK: - Convenience Extensions

extension Input_Primitives.Input.`Protocol` where Element: Equatable {
    /// Checks if the input starts with the given element.
    @inlinable
    public func starts(with element: Element) -> Bool {
        first == element
    }
}
