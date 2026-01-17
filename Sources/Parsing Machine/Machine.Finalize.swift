import Parsing_Primitives
public import Identity_Primitives

extension Parsing.Machine {
    @usableFromInline
    enum Finalize {}
}

extension Parsing.Machine.Finalize {
    @safe
    @usableFromInline
    struct Array: @unchecked Sendable {
        @usableFromInline
        let finalize: @Sendable ([Parsing.Machine.Value]) -> Parsing.Machine.Value

        @usableFromInline
        init<T: Sendable>(_ elementType: T.Type) {
            self.finalize = { values in
                Parsing.Machine.Value.make(values.map { $0.unsafeTake(T.self) })
            }
        }
    }
}
