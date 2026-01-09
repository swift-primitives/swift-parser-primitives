//
//  Parsing.Located.swift
//  swift-standards
//
//  Error wrapper with source location.
//

extension Parsing {
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
    /// throw Located(error: .unexpected, offset: 42)
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

extension Parsing.Located: Equatable where E: Equatable {}

// MARK: - CustomStringConvertible

extension Parsing.Located: CustomStringConvertible {
    public var description: String {
        "at offset \(offset): \(error)"
    }
}

// MARK: - Mapping

extension Parsing.Located {
    /// Maps the underlying error to a different type.
    @inlinable
    public func map<NewE: Swift.Error & Sendable>(
        _ transform: (E) -> NewE
    ) -> Parsing.Located<NewE> {
        Parsing.Located<NewE>(transform(error), at: offset)
    }
}
