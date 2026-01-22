extension Binary.Bytes.Input {
    /// Creates an input cursor from any byte collection.
    ///
    /// Materializes to an array for owned storage.
    ///
    /// - Parameter bytes: The bytes to parse.
    @inlinable
    public init<Bytes: Collection>(_ bytes: Bytes) where Bytes.Element == UInt8 {
        self.storage = Swift.Array(bytes)
        self.position = 0
    }

    /// Creates an input cursor from an array (no copy needed).
    ///
    /// - Parameter bytes: The byte array to parse.
    @inlinable
    public init(_ bytes: [UInt8]) {
        self.storage = bytes
        self.position = 0
    }

    /// Creates an input cursor from an array slice.
    ///
    /// - Parameter bytes: The byte slice to parse.
    @inlinable
    public init(_ bytes: ArraySlice<UInt8>) {
        self.storage = Swift.Array(bytes)
        self.position = 0
    }
}
