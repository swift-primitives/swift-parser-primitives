//
//  Machine.Parser.Parse.Incremental.swift
//  swift-parsing-primitives
//
//  Incremental parsing context with memoization.
//

extension Parsing.Machine.Parser.Parse where Input.Checkpoint: Hashable {
    /// Returns an incremental parsing context.
    ///
    /// The context maintains a memoization table across parse invocations,
    /// enabling efficient re-parsing after edits.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var ctx = parser.parse.incremental
    ///
    /// // Initial parse (populates memoization table)
    /// let tree1 = try ctx(&input)
    ///
    /// // After edit, invalidate affected entries
    /// ctx.invalidate(edit)
    ///
    /// // Re-parse (reuses cached results)
    /// let tree2 = try ctx(&input2)
    /// ```
    @inlinable
    public var incremental: Incremental {
        Incremental(parser: parser)
    }
}

extension Parsing.Machine.Parser.Parse {
    /// Incremental parsing context with memoization.
    ///
    /// Maintains a memoization table that caches parse results,
    /// enabling efficient re-parsing after edits.
    public struct Incremental where Input.Checkpoint: Hashable {
        @usableFromInline
        let parser: Parsing.Machine.Parser<Input, Output, Failure>

        @usableFromInline
        var memoization: Parsing.Machine.Memoization.Table<Input.Checkpoint>

        /// Creates an incremental parsing context.
        ///
        /// - Parameter parser: The parser to use for parsing.
        @inlinable
        public init(parser: Parsing.Machine.Parser<Input, Output, Failure>) {
            self.parser = parser
            self.memoization = .init()
        }

        /// Creates an incremental parsing context with reserved capacity.
        ///
        /// - Parameters:
        ///   - parser: The parser to use for parsing.
        ///   - capacity: Expected number of memoization entries.
        @inlinable
        public init(parser: Parsing.Machine.Parser<Input, Output, Failure>, capacity: Int) {
            self.parser = parser
            self.memoization = .init(capacity: capacity)
        }
    }
}

// MARK: - Parsing

extension Parsing.Machine.Parser.Parse.Incremental {
    /// Parses the input using memoization.
    ///
    /// Cached results from previous parses are reused when the
    /// memoization table contains valid entries.
    ///
    /// - Parameter input: The input to parse.
    /// - Returns: The parsed output.
    /// - Throws: The failure error if parsing fails.
    @inlinable
    public mutating func callAsFunction(_ input: inout Input) throws(Failure) -> Output {
        try parser.program.run(
            root: parser.root,
            input: &input,
            memoization: &memoization,
            as: Output.self
        )
    }
}

// MARK: - Invalidation

extension Parsing.Machine.Parser.Parse.Incremental where Input.Checkpoint: Comparable {
    /// Invalidates memoization entries affected by an edit.
    ///
    /// Call this after the input has been modified to ensure
    /// stale cache entries are not reused.
    ///
    /// - Parameter edit: The edit descriptor.
    @inlinable
    public mutating func invalidate(_ edit: Parsing.Machine.Memoization.Edit<Input.Checkpoint>) {
        memoization.invalidate(edit)
    }

    /// Invalidates all memoization entries at or after a position.
    ///
    /// Use this simpler form when you don't have precise edit information.
    ///
    /// - Parameter position: Invalidate entries at or after this position.
    @inlinable
    public mutating func invalidate(from position: Input.Checkpoint) {
        memoization.invalidate(from: position)
    }
}

// MARK: - Table Access

extension Parsing.Machine.Parser.Parse.Incremental {
    /// The number of cached entries.
    @inlinable
    public var count: Int {
        memoization.count
    }

    /// Whether the memoization table is empty.
    @inlinable
    public var isEmpty: Bool {
        memoization.isEmpty
    }

    /// Clears all cached entries.
    @inlinable
    public mutating func clear() {
        memoization.clear()
    }
}
