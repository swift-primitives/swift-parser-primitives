import Parsing_Primitives

extension Parsing.Machine {
    @usableFromInline
    enum Runtime {}
}

extension Parsing.Machine.Runtime {
    @usableFromInline
    enum Error: Swift.Error, Sendable {
        case depthExceeded(limit: Int)
        case typeMismatch
        case internalError(String)
        case cachedFailure
    }
}
