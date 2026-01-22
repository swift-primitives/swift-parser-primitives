extension Binary.Bytes.Input {
    /// Total length of the underlying storage.
    @usableFromInline
    internal var totalCount: Int {
        storage.count
    }

    /// The number of bytes remaining to parse.
    @inlinable
    public var count: Int { totalCount - position }

    /// Whether there are no more bytes to parse.
    @inlinable
    public var isEmpty: Bool { position == totalCount }

    /// The number of bytes consumed since construction (canonical measure).
    @inlinable
    public var consumedCount: Int { position }

    /// The first byte, or `nil` if empty.
    @inlinable
    public var first: UInt8? {
        guard position < totalCount else { return nil }
        return storage[position]
    }
}
