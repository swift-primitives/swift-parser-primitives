import Parsing_Primitives

extension Parsing.Machine {
    @safe
    @usableFromInline
    struct Value: @unchecked Sendable {
        @usableFromInline
        let type: ObjectIdentifier

        /// Stores a retained Box<T> as AnyObject to avoid raw memory.
        @usableFromInline
        let box: AnyObject

        @usableFromInline
        init(type: ObjectIdentifier, box: AnyObject) {
            self.type = type
            self.box = box
        }

        @inlinable
        static func make<T: Sendable>(_ value: T) -> Value {
            let box = Box(value)
            return Value(
                type: ObjectIdentifier(T.self),
                box: box
            )
        }

        @inlinable
        func take<T>(_ expectedType: T.Type) -> T? {
            guard type == ObjectIdentifier(T.self) else {
                return nil
            }
            // Safe conditional downcast
            guard let typedBox = box as? Box<T> else {
                return nil
            }
            return typedBox.value
        }

        @inlinable
        func unsafeTake<T>(_ expectedType: T.Type) -> T {
            // Extra safety: check box is still valid
            precondition(
                type == ObjectIdentifier(T.self),
                "Machine.Value type mismatch: expected \(T.self), got type with id \(type)"
            )
            // Use conditional downcast instead of unsafeBitCast for safety
            guard let typedBox = box as? Box<T> else {
                fatalError("Machine.Value box downcast failed: expected Box<\(T.self)>")
            }
            return typedBox.value
        }

        @inlinable
        func release() {
            // No-op: ARC handles deallocation when Value is dropped
        }
    }
}
