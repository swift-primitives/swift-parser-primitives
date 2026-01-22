extension Binary.Bytes.Input {
    /// Consumes and returns the first byte.
    ///
    /// - Precondition: The input must not be empty.
    /// - Returns: The first byte.
    @inlinable
    @discardableResult
    public mutating func advance() -> UInt8 {
        precondition(position < totalCount, "advance() called on empty input")
        let byte = storage[position]
        position += 1
        return byte
    }

    /// Advances by `n` bytes.
    ///
    /// - Parameter count: The number of bytes to skip.
    /// - Precondition: `count >= 0` and `count <= self.count`.
    @inlinable
    public mutating func advance(by count: Int) {
        precondition(count >= 0 && count <= self.count)
        position += count
    }
}
