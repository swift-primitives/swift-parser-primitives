//
//  Parser.ByteInput.swift
//  swift-parser-primitives
//
//  Convenience initializers for Parser.ByteInput.
//

extension Parser.ByteInput {
    @inlinable
    public init(_ bytes: Swift.Array<UInt8>) {
        var storage = Array<UInt8>()
        for byte in bytes {
            storage.append(byte)
        }
        self = Input.Slice(Array<UInt8>.Indexed<UInt8>(storage))
    }

    @inlinable
    public init(utf8 string: String) {
        self.init(Swift.Array(string.utf8))
    }
}
