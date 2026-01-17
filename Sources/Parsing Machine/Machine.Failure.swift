import Parsing_Primitives
public import Identity_Primitives

extension Parsing.Machine {
    @usableFromInline
    enum Failure {}
}

extension Parsing.Machine.Failure {
    @usableFromInline
    enum Recovery {
        @usableFromInline
        enum Tag {}

        @usableFromInline
        typealias ID = Tagged<Tag, Int>

        case continueWith(ID)
        case handleReady(Parsing.Machine.Value.Handle)
        case propagate
    }
}
