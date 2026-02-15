//
//  Parser.Tracked.swift
//  swift-standards
//
//  Input wrapper that tracks byte offset.
//

extension Parser {
    /// An input wrapper that tracks the current byte offset.
    ///
    /// `Tracked` wraps any `Input` type and maintains a running count
    /// of bytes consumed, enabling location-aware parsing.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var input = Parser.Tracked(myInput)
    /// let result = try parser.parse(&input)
    /// print("Parsed up to offset \(input.offset)")
    /// ```
    ///
    /// ## Zero Overhead When Not Used
    ///
    /// Regular parsers don't use `Tracked` - location tracking is opt-in.
    /// Only wrap input in `Tracked` when you need position information.
    ///
    /// ## With Located Errors
    ///
    /// Combine with `Located<E>` for precise error locations:
    /// ```swift
    /// var input = Parser.Tracked(source)
    /// do {
    ///     return try parser.parse(&input)
    /// } catch {
    ///     throw Located(error, at: input.offset)
    /// }
    /// ```
    public struct Tracked<Base: Input>: Sendable
    where Base: Sendable {
        /// The underlying input.
        @usableFromInline
        internal var base: Base

        /// Current element offset from the start of input.
        @usableFromInline
        internal var offset: Index<Element>

        /// The underlying input (read-only access).
        @inlinable
        public var input: Base { base }

        /// Current element offset from the start of input.
        @inlinable
        public var currentOffset: Index<Element> { offset }

        /// Creates a tracked input.
        ///
        /// - Parameter base: The input to track.
        @inlinable
        public init(_ base: Base) {
            self.base = base
            self.offset = .zero
        }

        /// Creates a tracked input with an initial offset.
        ///
        /// Useful for resuming parsing or when input is a slice.
        ///
        /// - Parameters:
        ///   - base: The input to track.
        ///   - offset: Initial offset value.
        @inlinable
        public init(_ base: Base, offset: Index<Element>) {
            self.base = base
            self.offset = offset
        }
    }
}

// MARK: - Input Conformance

extension Parser.Tracked: Parser.Input {
    public typealias Element = Base.Element

    /// Checkpoint stores both the base input checkpoint and tracked offset.
    ///
    /// Equality and ordering delegate to `baseCheckpoint` only, matching
    /// the semantics of the underlying `Buffer.Ring.Checkpoint`.
    public struct Checkpoint: Sendable, Comparable {
        @usableFromInline
        let baseCheckpoint: Base.Checkpoint

        @usableFromInline
        let trackedOffset: Index<Element>

        @inlinable
        init(baseCheckpoint: Base.Checkpoint, trackedOffset: Index<Element>) {
            self.baseCheckpoint = baseCheckpoint
            self.trackedOffset = trackedOffset
        }

        @inlinable
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.baseCheckpoint == rhs.baseCheckpoint
        }

        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.baseCheckpoint < rhs.baseCheckpoint
        }
    }

    @inlinable
    public var isEmpty: Bool {
        base.isEmpty
    }

    @inlinable
    public var count: Index<Element>.Count {
        base.count
    }

    @inlinable
    public var checkpoint: Checkpoint {
        Checkpoint(baseCheckpoint: base.checkpoint, trackedOffset: offset)
    }

    @inlinable
    public var checkpointRange: ClosedRange<Checkpoint> {
        let baseRange = base.checkpointRange
        return Checkpoint(baseCheckpoint: baseRange.lowerBound, trackedOffset: .zero)
            ... Checkpoint(baseCheckpoint: baseRange.upperBound, trackedOffset: .zero)
    }

    @inlinable
    public mutating func setPosition(to checkpoint: Checkpoint) {
        base.setPosition(to: checkpoint.baseCheckpoint)
        offset = checkpoint.trackedOffset
    }

    @inlinable
    @discardableResult
    public mutating func advance() throws(Input.Stream.Error) -> Element {
        offset += .one
        return try base.advance()
    }

    @inlinable
    public mutating func advance(by count: Index<Element>.Count) {
        offset += count
        base.advance(by: count)
    }
}

// MARK: - Tracked Parsing

extension Parser.Tracked {
    /// Parses upstream, tracking offset and wrapping errors with location.
    ///
    /// Shared logic for `Parser.Span` and `Parser.Locate`.
    @inlinable
    mutating func parseTracked<P: Parser.`Protocol`>(
        _ parser: P
    ) throws(Parser.Error.Located<P.Failure>) -> (output: P.ParseOutput, start: Index<Element>)
    where P.Input == Base {
        let start = currentOffset
        let countBefore = base.count
        let value: P.ParseOutput
        do {
            value = try parser.parse(&base)
        } catch {
            throw Parser.Error.Located(error, at: start)
        }
        offset += countBefore.subtract.saturating(base.count)
        return (value, start)
    }
}

// MARK: - Convenience

extension Parser.Tracked {
    /// Saves the current position for later restoration.
    ///
    /// Use with `restore(to:)` for backtracking.
    @inlinable
    public func savepoint() -> (base: Base, offset: Index<Element>) {
        (base, offset)
    }

    /// Restores to a previously saved position.
    @inlinable
    public mutating func restore(to savepoint: (base: Base, offset: Index<Element>)) {
        self.base = savepoint.base
        self.offset = savepoint.offset
    }
}
