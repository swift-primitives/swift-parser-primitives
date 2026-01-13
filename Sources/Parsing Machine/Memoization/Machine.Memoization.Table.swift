//
//  Machine.Memoization.Table.swift
//  swift-parsing-primitives
//
//  Memoization table storing cached parse results.
//

extension Parsing.Machine.Memoization {
    /// Memoization table for caching parse results.
    ///
    /// Maps (position, node) keys to cached results.
    @usableFromInline
    struct Table<Checkpoint: Hashable & Sendable> {
        @usableFromInline
        var storage: [Key<Checkpoint>: Entry<Checkpoint>]

        @inlinable
        init() {
            self.storage = [:]
        }

        @inlinable
        init(capacity: Int) {
            self.storage = Dictionary(minimumCapacity: capacity)
        }
    }
}

// MARK: - Lookup

extension Parsing.Machine.Memoization.Table {
    @inlinable
    func lookup(_ key: Parsing.Machine.Memoization.Key<Checkpoint>) -> Parsing.Machine.Memoization.Entry<Checkpoint>? {
        storage[key]
    }

    @inlinable
    mutating func store(_ entry: Parsing.Machine.Memoization.Entry<Checkpoint>, for key: Parsing.Machine.Memoization.Key<Checkpoint>) {
        storage[key] = entry
    }
}

// MARK: - Metrics

extension Parsing.Machine.Memoization.Table {
    @inlinable
    var count: Int {
        storage.count
    }

    @inlinable
    var isEmpty: Bool {
        storage.isEmpty
    }

    @inlinable
    mutating func clear() {
        storage.removeAll(keepingCapacity: true)
    }
}

// MARK: - Invalidation

extension Parsing.Machine.Memoization.Table where Checkpoint: Comparable {
    @inlinable
    mutating func invalidate(_ edit: Parsing.Machine.Memoization.Edit<Checkpoint>) {
        storage = storage.filter { key, entry in
            switch entry {
            case .success(_, let endPosition):
                return endPosition <= edit.start || key.position >= edit.oldEnd
            case .failure:
                return key.position < edit.start
            }
        }
    }

    @inlinable
    mutating func invalidate(from position: Checkpoint) {
        storage = storage.filter { key, _ in
            key.position < position
        }
    }
}
