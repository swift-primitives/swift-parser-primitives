//
//  Machine.Memoization.Entry.swift
//  swift-parser-primitives
//
//  Cached parse result: success or failure.
//

extension Parser.Machine.Memoization {
    /// Cached parse result.
    ///
    /// For packrat parsing, both successes and failures are cached.
    /// Caching failures is essential for linear-time guarantees.
    @usableFromInline
    enum Entry<Checkpoint: Sendable> {
        /// Successful parse with output and end position.
        case success(output: Parser.Machine.Value, end: Checkpoint)

        /// Failed parse at this position.
        case failure
    }
}

// MARK: - Predicates

extension Parser.Machine.Memoization.Entry {
    @inlinable
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    @inlinable
    var isFailure: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }
}
