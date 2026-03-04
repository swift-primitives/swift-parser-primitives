//
//  Parser.Discard.Exactly.swift
//  swift-parser-primitives
//
//  Discard exactly N elements.
//

public import Collection_Primitives

extension Parser.Discard {
    /// A parser that skips N elements without returning them.
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

extension Parser.Discard.Exactly: Parser.`Protocol` {
    public typealias Output = Void
    public typealias Failure = Parser.Constraint.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) {
        _ = try Parser.Consume.Exactly<Input>(count).parse(&input)
    }
}
