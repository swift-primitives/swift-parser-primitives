//
//  Parser.Error.Located.swift
//  swift-parser-primitives
//
//  Error wrapper with source location.
//

public import Text_Primitives

extension Parser.Error {
    /// An error with source location information.
    ///
    /// `Located` wraps any error with its text position in the input,
    /// enabling precise error reporting without runtime overhead
    /// for parsers that don't need location tracking.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Wrap an error with location
    /// let position: Text.Position = 42
    /// throw Parser.Error.Located(error, at: position)
    ///
    /// // In error messages
    /// print("Error at offset \(error.offset): \(error.error)")
    /// ```
    ///
    /// ## Line/Column
    ///
    /// Byte offset is the primitive. Use `Text.Line.Map` to derive
    /// line/column from a `Text.Position`.
    public struct Located<E: Swift.Error>: Swift.Error, Sendable {
        /// The underlying error.
        public let error: E

        /// Text position from the start of input where the error occurred.
        public let offset: Text.Position

        /// Creates a located error.
        ///
        /// - Parameters:
        ///   - error: The underlying error.
        ///   - offset: Text position from input start.
        @inlinable
        public init(_ error: E, at offset: Text.Position) {
            self.error = error
            self.offset = offset
        }
    }
}

// MARK: - Typed Boundary Overload

extension Parser.Error.Located {
    /// Creates a located error from a typed index offset.
    ///
    /// Boundary overload per [IMPL-010]: retags the index to `Text.Position`.
    @inlinable
    public init<Element: ~Copyable & ~Escapable>(_ error: E, at offset: Index<Element>) {
        self.init(error, at: offset.retag(Text.self))
    }
}

// MARK: - Equatable

extension Parser.Error.Located: Equatable where E: Equatable {}

// MARK: - Hashable

extension Parser.Error.Located: Hashable where E: Hashable {}

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
    public func map<NewE: Swift.Error>(
        _ transform: (E) -> NewE
    ) -> Parser.Error.Located<NewE> {
        Parser.Error.Located<NewE>(transform(error), at: offset)
    }
}

// MARK: - Backward Compatibility

extension Parser {
    /// Backward compatibility alias.
    @available(*, deprecated, renamed: "Error.Located")
    public typealias Located<E: Swift.Error> = Parser.Error.Located<E>
}
