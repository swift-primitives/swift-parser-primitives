//
//  Machine.Memoization.Key.swift
//  swift-parser-primitives
//
//  Cache key: (position, node) pair.
//

extension Parser.Machine.Memoization {
    /// Cache key for memoization: (position, node) pair.
    ///
    /// Each unique combination of input position and parser node
    /// produces at most one cached result.
    @usableFromInline
    struct Key<Checkpoint: Hashable & Sendable>: Hashable, Sendable {
        /// The input position where parsing started.
        @usableFromInline
        let position: Checkpoint

        /// The node index in the program.
        @usableFromInline
        let node: Int

        @inlinable
        init(position: Checkpoint, node: Int) {
            self.position = position
            self.node = node
        }
    }
}
