public import Collection_Primitives
public import Parser_Primitives

extension Parser.Test {
    /// Minimal `Collection.Protocol` conformer wrapping `[UInt8]` for testing.
    ///
    /// Standard library `Array` does not conform to `Collection.Protocol`
    /// from collection-primitives. This wrapper enables
    /// `Input.Slice<Parser.Test.Bytes>` as a universal byte-oriented test input.
    public struct Bytes: Collection.`Protocol`, Sendable {
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
            // SAFETY: Collection.Protocol contract — index(after:) is only invoked on
            // indices strictly less than endIndex, so successor.exact() cannot fail.
            // swiftlint:disable:next force_try
            try! i.successor.exact()
        }

        public func makeIterator() -> Parser.Test.Iterator {
            Parser.Test.Iterator(storage)
        }
    }
}
