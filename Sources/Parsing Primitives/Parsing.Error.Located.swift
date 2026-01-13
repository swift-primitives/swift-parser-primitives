//
//  Parsing.Error.Located.swift
//  swift-parsing-primitives
//
//  Error wrapper with source location.
//

extension Parsing.Error {
    /// An error with source location information.
    ///
    /// `Located` wraps any error with its byte offset in the input,
    /// enabling precise error reporting without runtime overhead
    /// for parsers that don't need location tracking.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Wrap an error with location
    /// throw Parsing.Error.Located(error, at: 42)
    ///
    /// // In error messages
    /// print("Error at byte \(error.offset): \(error.error)")
    /// ```
    ///
    /// ## Line/Column
    ///
    /// Byte offset is the primitive. Line/column can be derived:
    /// ```swift
    /// let line = input.prefix(error.offset).filter { $0 == "\n" }.count + 1
    /// ```
    public struct Located<E: Swift.Error & Sendable>: Swift.Error, Sendable {
        /// The underlying error.
        public let error: E

        /// Byte offset from the start of input where the error occurred.
        public let offset: Int

        /// Creates a located error.
        ///
        /// - Parameters:
        ///   - error: The underlying error.
        ///   - offset: Byte offset from input start.
        @inlinable
        public init(_ error: E, at offset: Int) {
            self.error = error
            self.offset = offset
        }
    }
}

// MARK: - Equatable

extension Parsing.Error.Located: Equatable where E: Equatable {}

// MARK: - CustomStringConvertible

extension Parsing.Error.Located: CustomStringConvertible {
    public var description: String {
        "at offset \(offset): \(error)"
    }
}

// MARK: - Mapping

extension Parsing.Error.Located {
    /// Maps the underlying error to a different type.
    @inlinable
    public func map<NewE: Swift.Error & Sendable>(
        _ transform: (E) -> NewE
    ) -> Parsing.Error.Located<NewE> {
        Parsing.Error.Located<NewE>(transform(error), at: offset)
    }
}

// MARK: - LocatedError Protocol

extension Parsing.Error {
    /// Protocol for errors that carry location information.
    ///
    /// Used to enable location-aware utilities on `Either` compositions.
    public protocol LocatedError: Swift.Error {
        /// The byte offset where this error occurred.
        var offset: Int { get }
    }
}

extension Parsing.Error.Located: Parsing.Error.LocatedError {}

// MARK: - Backward Compatibility

extension Parsing {
    /// Backward compatibility alias.
    @available(*, deprecated, renamed: "Error.Located")
    public typealias Located<E: Swift.Error & Sendable> = Parsing.Error.Located<E>
}
