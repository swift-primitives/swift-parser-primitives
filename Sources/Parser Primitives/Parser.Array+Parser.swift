//
//  Parser.Array+Parser.swift
//  swift-standards
//
//  Array conformance to Parser and Printer for literal usage.
//

extension Array: Parser.Parser where Element: Equatable {
    public typealias Input = ArraySlice<Element>
    public typealias Output = Void
    public typealias Failure = Parser.Match.Error

    @inlinable
    public func parse(_ input: inout ArraySlice<Element>) throws(Failure) {
        for expected in self {
            guard let actual = input.first else {
                throw .literalMismatch(expected: "\(expected)", found: "end of input")
            }
            guard actual == expected else {
                throw .literalMismatch(expected: "\(expected)", found: "\(actual)")
            }
            input = input.dropFirst()
        }
    }
}

extension Array: Parser.Printer where Element: Equatable {
    @inlinable
    public func print(_ output: Void, into input: inout ArraySlice<Element>) {
        input.insert(contentsOf: self, at: input.startIndex)
    }
}
