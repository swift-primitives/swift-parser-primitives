//
//  Parser.Byte.swift
//  swift-standards
//
//  Single byte literal matching.
//

extension Parser {
    /// A parser that matches a single byte.
    ///
    /// More efficient than `Literal` for single bytes.
    ///
    /// This parser only requires `Streaming` capability (no backtracking),
    /// making it suitable for forward-only input sources.
    public struct Byte<Input: Parser.Streaming>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @usableFromInline
        let expected: UInt8

        @inlinable
        public init(_ expected: UInt8) {
            self.expected = expected
        }
    }
}

extension Parser.Byte: Parser.`Protocol` {
    public typealias ParseOutput = Void
    public typealias Failure = Parser.Error.Either<Parser.EndOfInput.Error, Parser.Match.Error>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) {
        guard let actual = input.first else {
            throw .left(.unexpected(expected: "byte 0x\(String(expected, radix: 16, uppercase: true))"))
        }
        guard actual == expected else {
            throw .right(.byteMismatch(expected: [expected], found: [actual]))
        }
        // SAFETY: first returned Some, so advance() cannot throw .empty
        _ = try! input.advance()
    }
}

// MARK: - Printer Conformance

extension Parser.Byte: Parser.Printer
where Input: RangeReplaceableCollection {
    @inlinable
    public func print(_ output: Void, into input: inout Input) {
        input.insert(expected, at: input.startIndex)
    }
}
