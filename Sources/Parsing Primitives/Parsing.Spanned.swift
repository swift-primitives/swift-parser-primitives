//
//  Parsing.Spanned.swift
//  swift-standards
//
//  Value wrapper with source span.
//

extension Parsing {
    /// A value with its source span.
    ///
    /// `Spanned` wraps any parsed value with its start and end offsets,
    /// enabling source mapping and AST node location tracking.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // A parsed identifier with its location
    /// let identifier: Spanned<String> = ...
    /// print("'\(identifier.value)' at \(identifier.start)..<\(identifier.end)")
    ///
    /// // Highlight in source
    /// let source = originalInput[identifier.start..<identifier.end]
    /// ```
    ///
    /// ## AST Nodes
    ///
    /// Use `Spanned` for AST nodes that need source location:
    /// ```swift
    /// struct FunctionDecl {
    ///     let name: Spanned<String>
    ///     let parameters: [Spanned<Parameter>]
    ///     let body: Spanned<Block>
    /// }
    /// ```
    public struct Spanned<T: Sendable>: Sendable {
        /// The wrapped value.
        public let value: T

        /// Byte offset where this value starts in the input.
        public let start: Int

        /// Byte offset where this value ends in the input.
        public let end: Int

        /// Creates a spanned value.
        ///
        /// - Parameters:
        ///   - value: The parsed value.
        ///   - start: Start offset in input.
        ///   - end: End offset in input.
        @inlinable
        public init(_ value: T, start: Int, end: Int) {
            self.value = value
            self.start = start
            self.end = end
        }

        /// The length of this span in bytes.
        @inlinable
        public var length: Int {
            end - start
        }

        /// The range of this span.
        @inlinable
        public var range: Range<Int> {
            start..<end
        }
    }
}

// MARK: - Equatable

extension Parsing.Spanned: Equatable where T: Equatable {}

// MARK: - Hashable

extension Parsing.Spanned: Hashable where T: Hashable {}

// MARK: - Mapping

extension Parsing.Spanned {
    /// Maps the value while preserving the span.
    @inlinable
    public func map<U: Sendable>(_ transform: (T) -> U) -> Parsing.Spanned<U> {
        Parsing.Spanned<U>(transform(value), start: start, end: end)
    }
}

// MARK: - CustomStringConvertible

extension Parsing.Spanned: CustomStringConvertible where T: CustomStringConvertible {
    public var description: String {
        "\(value) [\(start)..<\(end)]"
    }
}
