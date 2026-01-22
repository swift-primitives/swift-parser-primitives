//
//  Binary.Bytes.Input+Input.Protocol.swift
//  swift-binary-primitives
//
//  Conformance of Binary.Bytes.Input to Input.Protocol for parsing integration.
//

public import Input_Primitives

extension Binary.Bytes.Input: Input.`Protocol` {
    public typealias Element = UInt8
    public typealias Checkpoint = Int

    /// The current position as a checkpoint for backtracking.
    @inlinable
    public var checkpoint: Checkpoint {
        position
    }

    /// The range of valid checkpoints (start to end of input).
    @inlinable
    public var checkpointRange: ClosedRange<Checkpoint> {
        0...totalCount
    }

    /// Sets the input position to a previously saved checkpoint.
    ///
    /// - Parameter checkpoint: A checkpoint obtained from `checkpoint`.
    /// - Precondition: The checkpoint was created from this input instance
    ///   and is within valid bounds.
    @inlinable
    public mutating func setPosition(to checkpoint: Checkpoint) {
        precondition(checkpoint >= 0 && checkpoint <= totalCount,
                     "Invalid checkpoint: \(checkpoint) not in 0...\(totalCount)")
        position = checkpoint
    }
}

// MARK: - Random Access

extension Binary.Bytes.Input: Input.Access.Random {}
