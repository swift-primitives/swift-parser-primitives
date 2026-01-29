//
//  Parser.First.Element.swift
//  swift-standards
//
//  Parse first element unconditionally.
//

extension Parser.First {
    /// A parser that consumes and returns the first element.
    ///
    /// Fails if the input is empty.
    ///
    /// This parser only requires `Streaming` capability (no backtracking),
    /// making it suitable for forward-only input sources.
    public struct Element<Input: Parser.Streaming>: Sendable
    where Input: Sendable {
        @inlinable
        public init() {}
    }
}

extension Parser.First.Element: Parser.`Protocol` {
    public typealias Output = Input.Element
    public typealias Failure = Parser.EndOfInput.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard !input.isEmpty else {
            throw .unexpected(expected: "any element")
        }
        // SAFETY: isEmpty returned false, so advance() cannot throw .empty
        return try! input.advance()
    }
}

// MARK: - Printer Conformance

extension Parser.First.Element: Parser.Printer
where Input: RangeReplaceableCollection {
    @inlinable
    public func print(_ output: Input.Element, into input: inout Input) {
        input.insert(output, at: input.startIndex)
    }
}
