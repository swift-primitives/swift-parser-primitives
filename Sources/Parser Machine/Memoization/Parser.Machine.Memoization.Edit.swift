//
//  Machine.Memoization.Edit.swift
//  swift-parser-primitives
//
//  Edit descriptor for cache invalidation.
//

extension Parser.Machine.Memoization {
    /// Describes an edit to the input for cache invalidation.
    ///
    /// An edit replaces a range `[start, oldEnd)` with new content
    /// ending at `newEnd`. This allows precise invalidation of
    /// only the cache entries affected by the edit.
    ///
    /// ## Examples
    ///
    /// Inserting "xyz" at position 10:
    /// ```swift
    /// let edit = Edit(start: 10, oldEnd: 10, newEnd: 13)
    /// ```
    ///
    /// Deleting positions 10-15:
    /// ```swift
    /// let edit = Edit(start: 10, oldEnd: 15, newEnd: 10)
    /// ```
    public struct Edit<Checkpoint: Comparable & Sendable>: Sendable {
        /// The position where the edit starts.
        public let start: Checkpoint

        /// The end position in the old input (before edit).
        public let oldEnd: Checkpoint

        /// The end position in the new input (after edit).
        public let newEnd: Checkpoint

        /// Creates an edit descriptor.
        @inlinable
        public init(start: Checkpoint, oldEnd: Checkpoint, newEnd: Checkpoint) {
            self.start = start
            self.oldEnd = oldEnd
            self.newEnd = newEnd
        }
    }
}

// MARK: - Convenience Initializers

extension Parser.Machine.Memoization.Edit where Checkpoint: Numeric {
    /// Creates an edit for an insertion at a position.
    @inlinable
    public static func insert(at position: Checkpoint, length: Checkpoint) -> Self {
        Self(start: position, oldEnd: position, newEnd: position + length)
    }
}

extension Parser.Machine.Memoization.Edit {
    /// Creates an edit for a deletion of a range.
    @inlinable
    public static func delete(from start: Checkpoint, to end: Checkpoint) -> Self {
        Self(start: start, oldEnd: end, newEnd: start)
    }
}
