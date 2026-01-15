import Parsing_Primitives
import Identity_Primitives

extension Parsing.Machine {
    @usableFromInline
    enum Combine {}
}

extension Parsing.Machine.Combine {
    @safe
    @usableFromInline
    struct Erased: @unchecked Sendable {
        @usableFromInline
        let combine: @Sendable (Parsing.Machine.Value, Parsing.Machine.Value) -> Parsing.Machine.Value

        @usableFromInline
        init<A, B, Out: Sendable>(_ combineFn: @Sendable @escaping (A, B) -> Out) {
            self.combine = { a, b in
                let aVal = a.unsafeTake(A.self)
                let bVal = b.unsafeTake(B.self)
                return Parsing.Machine.Value.make(combineFn(aVal, bVal))
            }
        }
    }
}
