public import Collection_Primitives
public import Parser_Primitives

extension Parser.Test {
    /// Iterator over `[UInt8]` conforming to `Sequence.Iterator.Protocol`.
    ///
    /// Stores the array and an index for span-based iteration via
    /// `_elements.span.extracting()`.
    public struct Iterator: Sequence.Iterator.`Protocol`, IteratorProtocol, Sendable {
        @usableFromInline
        var _elements: [UInt8]

        @usableFromInline
        var _index: Int

        @inlinable
        public init(_ array: [UInt8]) {
            self._elements = array
            self._index = 0
        }

        @_lifetime(&self)
        @inlinable
        public mutating func nextSpan(maximumCount: Cardinal) -> Swift.Span<UInt8> {
            let remaining = _elements.count - _index
            let take = min(Int(maximumCount.rawValue), remaining)
            guard take > 0 else { return _elements.span.extracting(first: 0) }
            let start = _index
            _index += take
            return _elements.span
                .extracting(droppingFirst: start)
                .extracting(first: take)
        }

        @inlinable
        public mutating func next() -> UInt8? {
            guard _index < _elements.count else { return nil }
            defer { _index += 1 }
            return _elements[_index]
        }
    }
}
