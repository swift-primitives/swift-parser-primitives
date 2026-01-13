import Parsing_Primitives
import Identity_Primitives

extension Parsing.Machine {
    @usableFromInline
    enum Node<Input: Parsing.Input, Failure: Error & Sendable>: @unchecked Sendable
    where Input: Sendable {
        @usableFromInline
        enum Tag {}

        @usableFromInline
        typealias ID = Tagged<Tag, Int>

        case leaf(Leaf<Input, Failure>)
        case pure(Value)
        case map(child: ID, transform: Transform.Erased)
        case tryMap(child: ID, transform: Transform.Throwing<Failure>)
        case flatMap(child: ID, next: Next.Erased)
        case sequence(a: ID, b: ID, combine: Combine.Erased)
        case oneOf([ID])
        case many(child: ID, finalize: Finalize.Array)
        case optional(child: ID, wrapSome: Transform.Erased, noneValue: Value)
        case ref(ID)
        case hole
    }

    @usableFromInline
    struct Leaf<Input: Parsing.Input, Failure: Error & Sendable>: @unchecked Sendable
    where Input: Sendable {
        @usableFromInline
        let run: @Sendable (inout Input) throws(Failure) -> Value

        @usableFromInline
        init(_ run: @Sendable @escaping (inout Input) throws(Failure) -> Value) {
            self.run = run
        }
    }
}
