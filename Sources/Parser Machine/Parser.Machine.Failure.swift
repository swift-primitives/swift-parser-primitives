import Parser_Primitives
public import Identity_Primitives
public import Machine_Primitives

extension Parser.Machine {
    @usableFromInline
    enum Failure {}
}

extension Parser.Machine.Failure {
    @usableFromInline
    enum Recovery {
        @usableFromInline
        enum Tag {}

        @usableFromInline
        typealias ID = Tagged<Tag, Int>

        case continueWith(ID)
        case handleReady(Parser.Machine.Value.Handle)
        case propagate
    }
}
