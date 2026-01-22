// Binary.Bytes.Machine.Frame.swift
// Stack frame for machine interpreter

public import Machine_Primitives

extension Binary.Bytes.Machine {
    /// Checkpoint for backtracking - just the cursor position.
    public typealias Checkpoint = Int

    /// Frame is a typealias to the core Machine.Frame with Binary's types.
    ///
    /// Binary uses `Never` for Extra since it has no memoization (the extra case is uninhabited).
    public typealias Frame = Machine_Primitives.Machine.Frame<Node.ID, Checkpoint, Machine_Primitives.Machine.Capture.Mode.Reference, Fault, Never>
}
