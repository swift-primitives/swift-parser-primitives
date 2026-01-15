import Parsing_Primitives
import Storage_Primitives

extension Parsing.Machine.Value {
    /// A handle to a value stored in the arena.
    ///
    /// Handle is a lightweight index that can be copied freely.
    /// The actual value remains in the arena until explicitly released.
    @usableFromInline
    struct Handle: Sendable, Equatable {
        @usableFromInline
        let slot: UInt32

        @inlinable
        init(slot: UInt32) {
            self.slot = slot
        }
    }

    /// Arena-based storage for interpreter values.
    ///
    /// The Arena provides contiguous storage for Value objects,
    /// improving cache locality and reducing allocation overhead compared
    /// to scattered heap allocations. Values are accessed via handles
    /// rather than direct references.
    ///
    /// ## Memory Layout
    ///
    /// Values are stored contiguously in a pre-allocated slab:
    /// ```
    /// ┌─────────┬─────────┬─────────┬─────────┬─────────┐
    /// │ Value 0 │ Value 1 │ Value 2 │ ...     │ (free)  │
    /// └─────────┴─────────┴─────────┴─────────┴─────────┘
    /// ```
    ///
    /// ## Usage Pattern
    ///
    /// ```swift
    /// var arena = try Value.Arena(capacity: 1000)
    /// let handle = arena.allocate(Value.make(42))
    /// let value = arena.read(handle)
    /// arena.release(handle)
    /// ```
    @usableFromInline
    struct Arena: ~Copyable {
        @usableFromInline
        var slab: Slab<Parsing.Machine.Value>

        @usableFromInline
        var nextSlot: UInt32

        /// Creates a new arena with the specified capacity.
        ///
        /// - Parameter capacity: Maximum number of values the arena can hold.
        /// - Throws: `Slab.Error` if allocation fails.
        @inlinable
        init(capacity: Int) throws(Slab<Parsing.Machine.Value>.Error) {
            self.slab = try Slab<Parsing.Machine.Value>(capacity: capacity)
            self.nextSlot = 0
        }

        /// Allocates a value in the arena and returns a handle to it.
        ///
        /// - Parameter value: The value to store.
        /// - Returns: A handle that can be used to access the value.
        /// - Precondition: The arena has available capacity.
        @inlinable
        mutating func allocate(_ value: consuming Parsing.Machine.Value) -> Handle {
            precondition(Int(nextSlot) < slab.capacity, "Value.Arena overflow")
            let slot = nextSlot
            slab.initialize(at: Int(slot), to: value)
            nextSlot += 1
            return Handle(slot: slot)
        }

        /// Reads a value from the arena without removing it.
        ///
        /// - Parameter handle: The handle returned from `allocate`.
        /// - Returns: A copy of the stored value.
        @inlinable
        func read(_ handle: Handle) -> Parsing.Machine.Value {
            unsafe slab.withUnsafePointer(at: Int(handle.slot)) { ptr in
                unsafe ptr.pointee
            }
        }

        /// Reads and type-checks a value from the arena.
        ///
        /// - Parameters:
        ///   - handle: The handle returned from `allocate`.
        ///   - type: The expected type of the value.
        /// - Returns: The typed value, or nil if type doesn't match.
        @inlinable
        func read<T>(_ handle: Handle, as type: T.Type) -> T? {
            let value = read(handle)
            return value.take(T.self)
        }

        /// Releases a value from the arena.
        ///
        /// After release, the handle is invalid and must not be used.
        ///
        /// - Parameter handle: The handle to release.
        /// - Returns: The released value.
        @inlinable
        @discardableResult
        mutating func release(_ handle: Handle) -> Parsing.Machine.Value {
            slab.deinitialize(at: Int(handle.slot))
        }

        /// Resets the arena, invalidating all handles.
        ///
        /// This is more efficient than releasing handles individually
        /// when all values can be discarded together.
        @inlinable
        mutating func reset() {
            // Deinitialize all allocated slots
            for i in 0..<Int(nextSlot) {
                _ = slab.deinitialize(at: i)
            }
            nextSlot = 0
        }

        /// The number of values currently stored in the arena.
        @inlinable
        var count: Int {
            Int(nextSlot)
        }

        /// Whether the arena is empty.
        @inlinable
        var isEmpty: Bool {
            nextSlot == 0
        }

        /// Whether the arena is at capacity.
        @inlinable
        var isFull: Bool {
            Int(nextSlot) >= slab.capacity
        }
    }
}
