import Parser_Primitives

extension Parser.Machine {
    @usableFromInline
    enum Runtime {}
}

extension Parser.Machine.Runtime {
    @usableFromInline
    enum Error: Swift.Error, Sendable {
        case depthExceeded(limit: Int)
        case typeMismatch
        case internalError(String)
        case cachedFailure
    }
}
