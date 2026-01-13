import Parsing_Primitives

extension Parsing.Machine {
    /// Type-erased box for storing values with proper ARC semantics.
    /// Uses a heap-allocated class to avoid raw memory hazards.
    @usableFromInline
    final class Box<T>: @unchecked Sendable {
        @usableFromInline
        var value: T

        @usableFromInline
        init(_ value: T) {
            self.value = value
        }
    }
}
