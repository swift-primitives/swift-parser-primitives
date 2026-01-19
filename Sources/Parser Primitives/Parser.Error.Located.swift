//
//  Parser.Error.Located.swift
//  swift-parser-primitives
//
//  Error wrapper with source location.
//

extension Parser.Error {
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
    /// throw Parser.Error.Located(error, at: 42)
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

extension Parser.Error.Located: Equatable where E: Equatable {}

// MARK: - CustomStringConvertible

extension Parser.Error.Located: CustomStringConvertible {
    public var description: String {
        "at offset \(offset): \(error)"
    }
}

// MARK: - Mapping

extension Parser.Error.Located {
    /// Maps the underlying error to a different type.
    @inlinable
    public func map<NewE: Swift.Error & Sendable>(
        _ transform: (E) -> NewE
    ) -> Parser.Error.Located<NewE> {
        Parser.Error.Located<NewE>(transform(error), at: offset)
    }
}

// MARK: - LocatedError Protocol

extension Parser.Error {
    /// Protocol for errors that carry location information.
    ///
    /// Used to enable location-aware utilities on `Either` compositions.
    public protocol LocatedError: Swift.Error {
        /// The byte offset where this error occurred.
        var offset: Int { get }
    }
}

extension Parser.Error.Located: Parser.Error.LocatedError {}

// MARK: - Backward Compatibility

extension Parser {
    /// Backward compatibility alias.
    @available(*, deprecated, renamed: "Error.Located")
    public typealias Located<E: Swift.Error & Sendable> = Parser.Error.Located<E>
}
