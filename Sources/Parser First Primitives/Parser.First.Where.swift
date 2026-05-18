//
//  Parser.First.Where.swift
//  swift-standards
//
//  Parse first element matching predicate.
//

extension Parser.First {
    /// A parser that consumes the first element if it matches a predicate.
    ///
    /// This parser only requires `Streaming` capability (no backtracking),
    /// making it suitable for forward-only input sources.
    public struct Where<Input: Input_Primitives.Input.Streaming>
    where Input.Element: Copyable {
        @usableFromInline
        let predicate: (Input.Element) -> Bool

        @usableFromInline
        let expected: String

        @inlinable
        public init(
            expected: String = "matching element",
            _ predicate: @escaping (Input.Element) -> Bool
        ) {
            self.predicate = predicate
            self.expected = expected
        }
    }
}

extension Parser.First.Where: Parser.`Protocol` {
    public typealias Output = Input.Element
    public typealias Failure = Either<Parser.EndOfInput.Error, Parser.Match.Error>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard !input.isEmpty else {
            throw .left(.unexpected(expected: expected))
        }
        // SAFETY: isEmpty returned false, so advance() cannot throw .empty
        // swiftlint:disable:next force_try
        let element = try! input.advance()
        guard predicate(element) else {
            throw .right(.predicateFailed(description: expected))
        }
        return element
    }
}
