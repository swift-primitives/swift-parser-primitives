//
//  Parsing.Input.swift
//  swift-standards
//
//  Protocol for parser input types enabling zero-copy parsing.
//

extension Parsing {
    /// A type that can be used as input to a parser with backtracking support.
    ///
    /// `Input` refines `Streaming` by adding checkpoint-based backtracking,
    /// enabling parser combinators like `OneOf`, `Peek`, and `Not` to try
    /// alternatives and restore position on failure.
    ///
    /// ## Protocol Hierarchy
    ///
    /// ```
    /// Streaming   ← minimal, forward-only (isEmpty, first, removeFirst)
    ///     ↑
    ///   Input     ← adds checkpoint/restore for backtracking
    /// ```
    ///
    /// ## Abstracts Over
    ///
    /// - `Span<UInt8>` for zero-copy byte parsing
    /// - `[UInt8]` for byte array parsing
    /// - `Substring.UTF8View` for string parsing
    /// - Custom types for specialized parsing
    ///
    /// ## Zero-Copy Guarantee
    ///
    /// All operations should be O(1) and non-allocating for conforming types.
    /// The protocol does not require random access - only forward iteration
    /// with the ability to save and restore positions.
    ///
    /// ## Position-Based Checkpointing
    ///
    /// The `Checkpoint` associated type and related methods enable efficient
    /// backtracking without copying the entire input state. This is critical
    /// for parser combinators that need to restore input position on failure.
    ///
    /// ## Example Conformances
    ///
    /// ```swift
    /// // Span<UInt8> - zero-copy view
    /// extension Span: Parsing.Input where Element == UInt8 {}
    ///
    /// // [UInt8] - via ArraySlice for O(1) slicing
    /// extension ArraySlice: Parsing.Input where Element == UInt8 {}
    /// ```
    public protocol Input<Element>: Streaming {
        /// The checkpoint type for position-based backtracking.
        ///
        /// Typically a lightweight value like `Int` or an index type.
        /// Must be `Sendable` for use in concurrent parsing contexts.
        associatedtype Checkpoint: Sendable

        /// The number of elements remaining.
        var count: Int { get }

        /// Creates a checkpoint at the current position.
        ///
        /// The checkpoint can be used with `restore(to:)` to backtrack.
        /// This must be O(1) and should not allocate.
        var checkpoint: Checkpoint { get }

        /// Restores the input to a previously saved checkpoint.
        ///
        /// - Parameter checkpoint: A checkpoint obtained from `checkpoint`.
        /// - Precondition: The checkpoint was created from this input instance.
        mutating func restore(to checkpoint: Checkpoint)

        /// Removes and discards the first `n` elements.
        ///
        /// - Parameter n: The number of elements to skip.
        /// - Precondition: The input contains at least `n` elements.
        mutating func removeFirst(_ n: Int)

        /// The remaining input as the same type (for composability).
        ///
        /// Default implementation returns `self`. Override for types
        /// that need conversion (e.g., Array → ArraySlice).
        var remaining: Self { get }
    }
}

// MARK: - Default Implementations

extension Parsing.Input {
    /// Default remaining implementation returns self.
    @inlinable
    public var remaining: Self {
        self
    }
}

// MARK: - Span Conformance
//
// Note: Span<T> is ~Escapable, which requires special handling.
// For now, we provide conformances only for Escapable collection types.
// Span-based parsing will be added when lifetime annotations are stable.
//
// Future: Add Span conformance with proper @_lifetime annotations:
//
// extension Span: Parsing.Input where Element: ~Copyable {
//     @inlinable
//     @_lifetime(self: ...)
//     public var first: Element? { ... }
// }

// MARK: - Collection Conformance

extension Parsing {
    /// Wrapper to use any Collection as parser input.
    ///
    /// Provides O(1) slicing by tracking start/end indices.
    public struct CollectionInput<Base: Collection>: Parsing.Input, Sendable
    where Base: Sendable, Base.Index: Sendable {
        public typealias Element = Base.Element
        public typealias Checkpoint = Base.Index

        @usableFromInline
        let base: Base

        @usableFromInline
        var startIndex: Base.Index

        @usableFromInline
        let endIndex: Base.Index

        /// Creates input from a collection.
        @inlinable
        public init(_ base: Base) {
            self.base = base
            self.startIndex = base.startIndex
            self.endIndex = base.endIndex
        }

        @inlinable
        init(base: Base, startIndex: Base.Index, endIndex: Base.Index) {
            self.base = base
            self.startIndex = startIndex
            self.endIndex = endIndex
        }

        @inlinable
        public var isEmpty: Bool {
            startIndex >= endIndex
        }

        @inlinable
        public var count: Int {
            base.distance(from: startIndex, to: endIndex)
        }

        @inlinable
        public var first: Element? {
            isEmpty ? nil : base[startIndex]
        }

        @inlinable
        public var checkpoint: Checkpoint {
            startIndex
        }

        @inlinable
        public mutating func restore(to checkpoint: Checkpoint) {
            startIndex = checkpoint
        }

        @inlinable
        public mutating func removeFirst() -> Element {
            let element = base[startIndex]
            startIndex = base.index(after: startIndex)
            return element
        }

        @inlinable
        public mutating func removeFirst(_ n: Int) {
            startIndex = base.index(startIndex, offsetBy: n)
        }
    }
}

// MARK: - ArraySlice Conformance

extension ArraySlice: Parsing.Input {
    public typealias Checkpoint = Int

    @inlinable
    public var count: Int {
        endIndex - startIndex
    }

    @inlinable
    public var checkpoint: Checkpoint {
        startIndex
    }

    @inlinable
    public mutating func restore(to checkpoint: Checkpoint) {
        // Create a new slice starting at checkpoint through the current end
        // This works because ArraySlice subscripting preserves the base array reference
        self = self[checkpoint...]
    }

    @inlinable
    public var remaining: ArraySlice<Element> {
        self
    }
}

// MARK: - Substring Conformance

extension Substring: Parsing.Input {
    public typealias Checkpoint = String.Index

    @inlinable
    public var count: Int {
        utf8.distance(from: utf8.startIndex, to: utf8.endIndex)
    }

    @inlinable
    public var checkpoint: Checkpoint {
        startIndex
    }

    @inlinable
    public mutating func restore(to checkpoint: Checkpoint) {
        // Create a suffix from checkpoint to current end
        self = self[checkpoint...]
    }

    @inlinable
    public var remaining: Substring {
        self
    }
}

extension Substring.UTF8View: Parsing.Input {
    public typealias Checkpoint = String.Index

    @inlinable
    public var count: Int {
        distance(from: startIndex, to: endIndex)
    }

    @inlinable
    public var checkpoint: Checkpoint {
        startIndex
    }

    @inlinable
    public mutating func restore(to checkpoint: Checkpoint) {
        // Create a suffix from checkpoint
        self = self[checkpoint...]
    }

    @inlinable
    public var remaining: Substring.UTF8View {
        self
    }
}

// MARK: - Convenience Extensions

extension Parsing.Input where Element: Equatable {
    /// Checks if the input starts with the given element.
    @inlinable
    public func starts(with element: Element) -> Bool {
        first == element
    }
}

// Note: starts(with:) for sequences is provided by Collection.
// No additional extension needed here as it would cause infinite recursion.
