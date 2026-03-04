//
//  Parser.Consume.Exactly.swift
//  swift-parser-primitives
//
//  Consume exactly N elements.
//

public import Collection_Primitives

extension Parser.Consume {
    /// A parser that consumes exactly N elements.
    public struct Exactly<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable {
        @usableFromInline
        let count: Int

        @inlinable
        public init(_ count: Int) {
            self.count = count
        }
    }
}

extension Parser.Consume.Exactly: Parser.`Protocol` {
    public typealias Output = Input
    public typealias Failure = Parser.Constraint.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        var endIndex = input.startIndex
        var actualCount = 0
        while actualCount < count, endIndex < input.endIndex {
            endIndex = input.index(after: endIndex)
            actualCount += 1
        }

        guard actualCount == count else {
            throw .countTooLow(expected: count, got: actualCount)
        }

        let result = input[input.startIndex..<endIndex]
        input = input[endIndex...]
        return result
    }
}
