import Parsing_Primitives
public import Identity_Primitives

extension Parsing.Machine {
    @usableFromInline
    enum Transform {}
}

extension Parsing.Machine.Transform {
    @safe
    @usableFromInline
    struct Erased: @unchecked Sendable {
        @usableFromInline
        let apply: @Sendable (Parsing.Machine.Value) -> Parsing.Machine.Value

        @usableFromInline
        init<In, Out: Sendable>(_ transform: @Sendable @escaping (In) -> Out) {
            self.apply = { value in
                let input = value.unsafeTake(In.self)
                return Parsing.Machine.Value.make(transform(input))
            }
        }
    }

    @safe
    @usableFromInline
    struct Throwing<Failure: Error & Sendable>: @unchecked Sendable {
        @usableFromInline
        let apply: @Sendable (Parsing.Machine.Value) throws(Failure) -> Parsing.Machine.Value

        @usableFromInline
        init<In, Out: Sendable>(_ transform: @Sendable @escaping (In) throws(Failure) -> Out) {
            self.apply = { (value: Parsing.Machine.Value) throws(Failure) -> Parsing.Machine.Value in
                let input = value.unsafeTake(In.self)
                return Parsing.Machine.Value.make(try transform(input))
            }
        }
    }
}
