//
//  Machine.Memoization.swift
//  swift-parser-primitives
//
//  Namespace for memoization types used during program execution.
//

extension Parser.Machine {
    /// Namespace for memoization types.
    ///
    /// Memoization enables:
    /// - Linear-time parsing for PEG grammars (packrat parsing)
    /// - Incremental re-parsing after edits (invalidate affected entries)
    ///
    /// Memoization is an execution-time concern, surfaced via
    /// `.parse.incremental` on parser types.
    public enum Memoization {}
}
