public import Collection_Primitives
public import Iterator_Chunk_Primitives
public import Parser_Primitives

extension Parser.Test {
    /// Iterator over `[UInt8]` conforming to `Iterator.Chunk.Protocol`.
    ///
    /// Stores the array and an index for span-based iteration via
    /// `_elements.span.extracting()`.
    ///
    /// WORKAROUND: this type does NOT conform to stdlib `IteratorProtocol`.
    /// WHY: Swift 6.3.3 (+Asserts, e.g. the Windows CI toolchain) crashes type-checking
    ///      a type that conforms to BOTH the chunk protocol and stdlib `IteratorProtocol` —
    ///      Assertion `getEffects(req).contains(getEffects(witness))` (TypeCheckProtocol.cpp:1311):
    ///      the chunk protocol's `where Element: Copyable` derived `next() throws(Never)` competes
    ///      with the non-throwing `IteratorProtocol.next()` requirement and trips an effects check.
    ///      The stdlib conformance was unused here — `Parser.Test.Bytes` reaches `Iterable` via
    ///      `Collection.Protocol` and needs only `Iterator.Chunk.Protocol`, not stdlib iteration.
    ///      Mirrors the `swift-input-primitives` fix (4262602).
    /// TRACKING: swift-institute/Issues/swift-issue-typed-throws-never-witness-effects-assertion
    ///           (compiler-bug-catalog §A17). Fixed on Swift 6.5-dev.
    /// WHEN TO REMOVE: restore `, IteratorProtocol` (and the `next() -> UInt8?` witness) once the
    ///      Windows CI toolchain ships a Swift carrying the fix.
    public struct Iterator: __IteratorChunkProtocol, Sendable {
        public typealias Failure = Never

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
        public mutating func next(maximumCount: some Carrier.`Protocol`<Cardinal>) -> Swift.Span<UInt8> {
            let remaining = _elements.count - _index
            let take = min(Int(maximumCount.underlying.rawValue), remaining)
            guard take > 0 else { return _elements.span.extracting(first: 0) }
            let start = _index
            _index += take
            return _elements.span
                .extracting(droppingFirst: start)
                .extracting(first: take)
        }
    }
}
