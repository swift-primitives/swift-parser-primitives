//
//  Parsing.Input.swift
//  swift-standards
//
//  Protocol for parser input types enabling zero-copy parsing.
//

extension Parsing {
    /// A type that can be used as input to a parser.
    ///
    /// `Input` abstracts over different input representations:
    /// - `Span<UInt8>` for zero-copy byte parsing
    /// - `[UInt8]` for byte array parsing
    /// - `Substring.UTF8View` for string parsing
    /// - Custom types for specialized parsing
    ///
    /// ## Design Rationale
    ///
    /// The protocol is minimal by design:
    /// - `Element`: What we're iterating over (e.g., `UInt8` for bytes)
    /// - `isEmpty`: Check for end of input
    /// - `first`: Peek at next element without consuming
    /// - `removeFirst()`: Consume and return next element
    /// - `prefix(_:)`: Extract a prefix (for multi-element consumption)
    /// - `dropFirst(_:)`: Skip elements (returns Self for chaining)
    ///
    /// This mirrors `Collection` but allows non-Collection types (like `Span`)
    /// to participate in parsing.
    ///
    /// ## Zero-Copy Guarantee
    ///
    /// All operations should be O(1) and non-allocating for conforming types.
    /// The protocol does not require random access - only forward iteration.
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
    public protocol Input<Element>: ~Copyable {
        /// The element type of the input.
        associatedtype Element

        /// Whether the input is empty.
        var isEmpty: Bool { get }

        /// The number of elements remaining, if known.
        ///
        /// Some input types may not know their count without traversal.
        /// Default implementation returns `nil`.
        var count: Int? { get }

        /// The first element, if any.
        ///
        /// Returns `nil` if the input is empty. Does not consume the element.
        var first: Element? { get }

        /// Removes and returns the first element.
        ///
        /// - Precondition: `!isEmpty`
        /// - Returns: The first element.
        mutating func removeFirst() -> Element

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
    /// Default count implementation returns nil (unknown).
    @inlinable
    public var count: Int? { nil }

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

        @usableFromInline
        let base: Base

        @usableFromInline
        var startIndex: Base.Index

        @usableFromInline
        var endIndex: Base.Index

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
        public var count: Int? {
            base.distance(from: startIndex, to: endIndex)
        }

        @inlinable
        public var first: Element? {
            isEmpty ? nil : base[startIndex]
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
    @inlinable
    public var count: Int? {
        endIndex - startIndex
    }

    @inlinable
    public var remaining: ArraySlice<Element> {
        self
    }
}

// MARK: - Substring Conformance

extension Substring: Parsing.Input {
    @inlinable
    public var count: Int? {
        utf8.distance(from: utf8.startIndex, to: utf8.endIndex)
    }

    @inlinable
    public var remaining: Substring {
        self
    }
}

extension Substring.UTF8View: Parsing.Input {
    @inlinable
    public var count: Int? {
        distance(from: startIndex, to: endIndex)
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
