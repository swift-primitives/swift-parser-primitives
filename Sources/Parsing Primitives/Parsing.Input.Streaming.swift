//
//  Parsing.Input.Streaming.swift
//  swift-parsing-primitives
//
//  Base protocol for streaming (non-backtracking) input sources.
//

extension Parsing {
    /// A type that can be used as streaming input to a parser.
    ///
    /// `Streaming` represents the minimal interface for forward-only input:
    /// - Check for end of input (`isEmpty`)
    /// - Peek at next element (`first`)
    /// - Consume next element (`removeFirst()`)
    ///
    /// Unlike `Parsing.Input`, this protocol does not require checkpointing
    /// or backtracking support, making it suitable for:
    /// - Network streams (where bytes cannot be re-read)
    /// - Large file parsing (where buffering is expensive)
    /// - Committed-choice parsing (where backtracking is not needed)
    ///
    /// ## Protocol Hierarchy
    ///
    /// ```
    /// Streaming   ← minimal, forward-only
    ///     ↑
    ///   Input     ← adds checkpoint/restore for backtracking
    /// ```
    ///
    /// ## Constraints
    ///
    /// Parsers that require backtracking (like `OneOf`, `Peek`, `Not`)
    /// constrain their input to `Parsing.Input`. Parsers that work with
    /// forward-only consumption can use `Streaming` for broader
    /// compatibility.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // A streaming wrapper around AsyncSequence
    /// struct AsyncInput<S: AsyncSequence>: Parsing.Streaming
    /// where S.Element: Sendable {
    ///     var iterator: S.AsyncIterator
    ///     var peeked: S.Element?
    ///
    ///     var isEmpty: Bool { peeked == nil }
    ///     var first: S.Element? { peeked }
    ///     mutating func removeFirst() -> S.Element {
    ///         let result = peeked!
    ///         peeked = try? await iterator.next()
    ///         return result
    ///     }
    /// }
    /// ```
    public protocol Streaming: ~Copyable {
        /// The element type of the input.
        associatedtype Element

        /// Whether the input is empty.
        var isEmpty: Bool { get }

        /// The first element, if any.
        ///
        /// Returns `nil` if the input is empty. Does not consume the element.
        var first: Element? { get }

        /// Removes and returns the first element.
        ///
        /// - Precondition: `!isEmpty`
        /// - Returns: The first element.
        mutating func removeFirst() -> Element
    }
}

// MARK: - Default Implementations
//
// Note: removeFirst(_:) is intentionally not provided as a default
// implementation here to avoid ambiguity with Collection.removeFirst(_:).
// Types conforming to Streaming can use Collection's implementation
// if they also conform to Collection, or provide their own.
