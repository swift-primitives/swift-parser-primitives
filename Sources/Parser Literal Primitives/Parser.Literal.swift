//
//  Parser.Literal.swift
//  swift-standards
//
//  Literal byte sequence matching.
//

import Array_Primitives_Core

extension Parser {
    /// A parser that matches a specific byte sequence.
    ///
    /// `Literal` consumes exact bytes from the input. It succeeds with `Void`
    /// output, making it ideal for delimiters and keywords.
    ///
    /// This parser only requires `Streaming` capability (no backtracking),
    /// making it suitable for forward-only input sources. Note that on
    /// partial match failure, input is left partially consumed.
    public struct Literal<Input: Parser.Input.Streaming>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @usableFromInline
        let bytes: [UInt8]

        @inlinable
        public init(_ bytes: [UInt8]) {
            self.bytes = bytes
        }

        @inlinable
        public init(_ string: StaticString) {
            self.bytes = unsafe Swift.Array(string.utf8Start.withMemoryRebound(to: UInt8.self, capacity: string.utf8CodeUnitCount) {
                unsafe UnsafeBufferPointer(start: $0, count: string.utf8CodeUnitCount)
            })
        }
    }
}

extension Parser.Literal: Parser.`Protocol` {
    public typealias Output = Void
    public typealias Failure = Either<Parser.EndOfInput.Error, Parser.Match.Error>

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) {
        for expected in bytes {
            guard !input.isEmpty else {
                throw .left(.unexpected(expected: "byte 0x\(String(expected, radix: 16, uppercase: true))"))
            }
            let actual = try! input.advance()
            guard actual == expected else {
                throw .right(.byteMismatch(expected: [expected], found: [actual]))
            }
        }
    }
}

extension Parser.Literal: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self.bytes = Swift.Array(value.utf8)
    }
}

extension Parser.Literal: ExpressibleByUnicodeScalarLiteral {
    @inlinable
    public init(unicodeScalarLiteral value: Unicode.Scalar) {
        self.bytes = Swift.Array(String(value).utf8)
    }
}

extension Parser.Literal: ExpressibleByExtendedGraphemeClusterLiteral {
    @inlinable
    public init(extendedGraphemeClusterLiteral value: Character) {
        self.bytes = Swift.Array(String(value).utf8)
    }
}

// MARK: - Printer Conformance

extension Parser.Literal: Parser.Printer
where Input: RangeReplaceableCollection {
    @inlinable
    public func print(_ output: Void, into input: inout Input) {
        input.insert(contentsOf: bytes, at: input.startIndex)
    }
}
