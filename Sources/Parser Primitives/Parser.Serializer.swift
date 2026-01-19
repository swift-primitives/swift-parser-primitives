//
//  Parser.Serializer.swift
//  swift-parser-primitives
//
//  Serializer protocol for append-based output.
//

extension Parser {
    /// A type that can serialize a value by appending to a buffer.
    ///
    /// `Serializer` is designed for efficient one-way serialization where
    /// O(1) append performance is critical. Unlike `Printer`, which uses
    /// prepend semantics for parser-printer symmetry, `Serializer` appends
    /// to enable efficient buffer construction.
    ///
    /// ## When to Use
    ///
    /// - **Serializer**: One-way encoding (JSON, binary formats, logging)
    /// - **Printer**: Bidirectional round-trip with matching `Parser`
    ///
    /// ## Performance
    ///
    /// Serializers append to buffers, which is O(1) amortized for array-based
    /// collections. This is critical for large output where prepend-based
    /// construction would be O(n²).
    ///
    /// ## Design Rationale
    ///
    /// The `Printer` protocol uses prepend semantics to enable parser-printer
    /// round-trip symmetry:
    /// - Parser: consumes from front (`removeFirst()`)
    /// - Printer: constructs from front (`insert at startIndex`)
    ///
    /// This symmetry ensures `parse(print(value)) == value`.
    ///
    /// However, for pure serialization (no parsing counterpart), prepend
    /// semantics cause O(n) per operation, leading to O(n²) overall.
    /// `Serializer` provides append semantics for these use cases.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct IntSerializer: Parser.Serializer {
    ///     typealias Output = Int
    ///     typealias Buffer = [UInt8]
    ///     typealias Failure = Never
    ///
    ///     func serialize(_ output: Int, into buffer: inout [UInt8]) {
    ///         buffer.append(contentsOf: "\(output)".utf8)
    ///     }
    /// }
    ///
    /// let serializer = IntSerializer()
    /// let bytes = serializer.serialize(42)  // [0x34, 0x32] ("42")
    /// ```
    public protocol Serializer<Output, Buffer, Failure> {
        /// The type of value this serializer accepts.
        associatedtype Output

        /// The buffer type this serializer writes to.
        associatedtype Buffer

        /// The error type this serializer can throw.
        ///
        /// Use `Never` for infallible serializers.
        associatedtype Failure: Swift.Error & Sendable

        /// Serializes a value by appending to the buffer.
        ///
        /// On success, appends the serialized representation to buffer.
        /// On failure, throws an error. The buffer state after failure is undefined.
        ///
        /// - Parameters:
        ///   - output: The value to serialize.
        ///   - buffer: The buffer to append to.
        /// - Throws: `Failure` if serialization fails.
        func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure)
    }
}

// MARK: - Convenience Extensions

extension Parser.Serializer where Buffer: RangeReplaceableCollection {
    /// Serializes a value, returning the constructed buffer.
    ///
    /// Use this for top-level serialization where you want to create a new buffer.
    ///
    /// - Parameter output: The value to serialize.
    /// - Returns: The serialized buffer.
    /// - Throws: `Failure` if serialization fails.
    @inlinable
    public func serialize(_ output: Output) throws(Failure) -> Buffer {
        var buffer = Buffer()
        try serialize(output, into: &buffer)
        return buffer
    }
}

// MARK: - Infallible Convenience

extension Parser.Serializer where Failure == Never {
    /// Serializes a value, returning the constructed buffer.
    ///
    /// Infallible version for serializers that cannot fail.
    ///
    /// - Parameter output: The value to serialize.
    /// - Returns: The serialized buffer.
    @inlinable
    public func serialize(_ output: Output) -> Buffer
    where Buffer: RangeReplaceableCollection {
        var buffer = Buffer()
        serialize(output, into: &buffer)
        return buffer
    }
}
