//
//  Parser.Rest.swift
//  swift-parser-primitives
//
//  Consume all remaining input.
//

public import Collection_Primitives

extension Parser {
    /// A parser that consumes and returns all remaining input.
    ///
    /// Always succeeds, possibly with empty output.
    public struct Rest<Input: Collection.Slice.`Protocol`> {
        @inlinable
        public init() {}
    }
}

extension Parser.Rest: Parser.`Protocol` {
    public typealias Output = Input
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> Output {
        let result = input
        input = input[input.endIndex...]
        return result
    }
}
