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
    public struct Where<Input: Parser.Streaming>: Sendable
    where Input: Sendable {
        @usableFromInline
        let predicate: @Sendable (Input.Element) -> Bool

        @usableFromInline
        let expected: String

        @inlinable
        public init(
            expected: String = "matching element",
            _ predicate: @escaping @Sendable (Input.Element) -> Bool
        ) {
            self.predicate = predicate
            self.expected = expected
        }
    }
}

extension Parser.First.Where: Parser.`Protocol` {
    public typealias Output = Input.Element
    public typealias Failure = Parser.Error.Either<Parser.EndOfInput.Error, Parser.Match.Error>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        guard let element = input.first else {
            throw .left(.unexpected(expected: expected))
        }
        guard predicate(element) else {
            throw .right(.predicateFailed(description: expected))
        }
        // SAFETY: first returned Some, so advance() cannot throw .empty
        return try! input.advance()
    }
}
