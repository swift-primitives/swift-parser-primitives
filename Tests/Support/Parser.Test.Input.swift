public import Parser_Primitives

extension Parser.Test {
    /// Byte-oriented cursor input for testing parsers that require `Input.Protocol`.
    ///
    /// Uses a locally-defined `Parser.Test.Bytes` type as the backing collection.
    /// This avoids a Swift runtime SIGSEGV that occurs when composing
    /// parser types over `Input.Slice<Buffer<Storage<UInt8>.Contiguous<Memory.Heap<UInt8>>>.Linear>` across modules.
    public typealias Input = Parser_Primitives.Input.Slice<Parser.Test.Bytes>
}

// MARK: - ExpressibleByArrayLiteral

extension Input.Slice: @retroactive ExpressibleByArrayLiteral
where Base == Parser.Test.Bytes {
    public init(arrayLiteral elements: UInt8...) {
        self.init(Parser.Test.Bytes(elements))
    }
}

// MARK: - Convenience Initializers

extension Input.Slice where Base == Parser.Test.Bytes {
    /// Creates a byte input from raw bytes.
    public init(_ bytes: [UInt8]) {
        self.init(Parser.Test.Bytes(bytes))
    }

    /// Creates a byte input from a string's UTF-8 representation.
    public init(utf8 string: Swift.String) {
        self.init(Parser.Test.Bytes([UInt8](string.utf8)))
    }
}
