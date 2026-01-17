import Parsing_Primitives
public import Identity_Primitives

extension Parsing.Machine {
    @usableFromInline
    enum Next {}
}

extension Parsing.Machine.Next {
    @safe
    @usableFromInline
    struct Erased: @unchecked Sendable {
        @usableFromInline
        enum Tag {}

        @usableFromInline
        typealias ID = Tagged<Tag, Int>

        @usableFromInline
        let next: @Sendable (Parsing.Machine.Value) -> ID

        @usableFromInline
        init<In>(_ nextFn: @Sendable @escaping (In) -> ID) {
            self.next = { value in
                let input = value.unsafeTake(In.self)
                return nextFn(input)
            }
        }
    }
}
