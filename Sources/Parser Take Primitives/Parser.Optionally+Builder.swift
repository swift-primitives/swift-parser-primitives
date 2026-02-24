extension Parser.Optionally {
    @inlinable
    public init(@Parser.Take.Builder<Wrapped.Input> _ wrapped: () -> Wrapped) {
        self.init(wrapped())
    }
}
