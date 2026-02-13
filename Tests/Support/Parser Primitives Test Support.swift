public import Parser_Primitives
public import Collection_Primitives
public import Sequence_Primitives

// MARK: - ByteIterator

/// Iterator over `[UInt8]` conforming to `Sequence.Iterator.Protocol`.
public struct ByteIterator: Sequence.Iterator.`Protocol`, IteratorProtocol, Sendable {
    @usableFromInline
    var base: Array<UInt8>.Iterator

    @inlinable
    public init(_ array: [UInt8]) {
        self.base = array.makeIterator()
    }

    @inlinable
    public mutating func next() -> UInt8? {
        base.next()
    }
}

// MARK: - TestBytes

/// Minimal `Collection.Protocol` conformer wrapping `[UInt8]` for testing.
///
/// Standard library `Array` does not conform to `Collection.Protocol`
/// from collection-primitives. This wrapper enables `Input.Slice<TestBytes>`
/// as a universal byte-oriented test input.
public struct TestBytes: Collection.`Protocol`, Sendable {
    public let storage: [UInt8]
    
    public typealias Index = Index_Primitives.Index<UInt8>

    public init(_ bytes: [UInt8]) {
        self.storage = bytes
    }

    public var startIndex: Index { .zero }

    public var endIndex: Index {
        Index.Count(Cardinal(UInt(storage.count))).map(Ordinal.init)
    }

    public subscript(position: Index) -> UInt8 {
        storage[Int(bitPattern: position)]
    }

    public func index(after i: Index) -> Index {
        try! i.successor.exact()
    }

    public func makeIterator() -> ByteIterator {
        ByteIterator(storage)
    }
}

// MARK: - ByteInput

/// Byte-oriented cursor input for testing parsers that require `Input.Protocol`.
///
/// Use this for streaming-based and input-based parsers (`Parser.Byte`,
/// `Parser.Literal`, `Parser.Many`, etc.).
public typealias ByteInput = Input.Slice<TestBytes>

extension Input.Slice where Base == TestBytes {
    /// Creates a byte input from raw bytes.
    public init(_ bytes: [UInt8]) {
        self.init(TestBytes(bytes))
    }

    /// Creates a byte input from a string's UTF-8 representation.
    public init(utf8 string: Swift.String) {
        self.init(TestBytes(Array(string.utf8)))
    }
}
