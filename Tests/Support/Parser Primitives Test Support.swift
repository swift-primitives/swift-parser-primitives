public import Parser_Primitives
@_exported public import Buffer_Linear_Primitives

// MARK: - ByteInput

/// Byte-oriented cursor input for testing parsers.
///
/// Uses `Buffer.Linear` from buffer-primitives as the backing collection,
/// providing full `Collection.Protocol` conformance with `~Copyable` support.
public typealias ByteInput = Input.Slice<Buffer<UInt8>.Linear>

// MARK: - ExpressibleByArrayLiteral

extension Input.Slice: @retroactive ExpressibleByArrayLiteral
where Base == Buffer<UInt8>.Linear {
    public init(arrayLiteral elements: UInt8...) {
        var buffer = Buffer<UInt8>.Linear()
        for element in elements {
            buffer.append(element)
        }
        self.init(buffer)
    }
}

// MARK: - Convenience Initializers

extension Input.Slice where Base == Buffer<UInt8>.Linear {
    /// Creates a byte input from a string's UTF-8 representation.
    public init(utf8 string: Swift.String) {
        var buffer = Buffer<UInt8>.Linear()
        for byte in string.utf8 {
            buffer.append(byte)
        }
        self.init(buffer)
    }
}
