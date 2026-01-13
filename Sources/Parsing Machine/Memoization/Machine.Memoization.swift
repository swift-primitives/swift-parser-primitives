//
//  Machine.Memoization.swift
//  swift-parsing-primitives
//
//  Namespace for memoization types used during program execution.
//

extension Parsing.Machine {
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
