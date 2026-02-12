//
//  Parser.Discard.Exactly.swift
//  swift-standards
//
//  Discard exactly N elements.
//

extension Parser.Discard {
    /// A parser that skips N elements without returning them.
    public struct Exactly<Input: Collection>: Sendable
    where Input: Sendable, Input.SubSequence == Input {
        @usableFromInline
        let count: Int

        @inlinable
        public init(_ count: Int) {
            self.count = count
        }
    }
}

extension Parser.Discard.Exactly: Parser.`Protocol` {
    public typealias ParseOutput = Void
    public typealias Failure = Parser.Constraint.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) {
        let endIndex = input.index(input.startIndex, offsetBy: count, limitedBy: input.endIndex)
            ?? input.endIndex

        let actualCount = input.distance(from: input.startIndex, to: endIndex)
        guard actualCount == count else {
            throw .countTooLow(expected: count, got: actualCount)
        }

        input = input[endIndex...]
    }
}
