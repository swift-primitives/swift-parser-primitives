//
//  Parser.ASCII.Integer.Hexadecimal.swift
//  swift-parser-primitives
//
//  Parses a hexadecimal integer from ASCII bytes.
//

public import Collection_Primitives

extension Parser.ASCII.Integer {
    /// A parser that consumes one or more ASCII hexadecimal digit bytes
    /// (0–9, A–F, a–f) and accumulates them into a `FixedWidthInteger`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let hex = Parser.ASCII.Integer.Hexadecimal<Input, UInt32>()
    /// let value = try hex.parse(&input) // e.g. 0xDEAD
    /// ```
    public struct Hexadecimal<Input: Collection.Slice.`Protocol`, T: FixedWidthInteger>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension Parser.ASCII.Integer.Hexadecimal: Parser.`Protocol` {
    public typealias ParseOutput = T
    public typealias Failure = Parser.ASCII.Integer.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        var result: T = 0
        var count = 0
        var index = input.startIndex

        while index < input.endIndex {
            let byte = input[index]
            guard let digit = Self._hexValue(byte) else { break }

            let (shifted, shiftOverflow) = result.multipliedReportingOverflow(by: 16)
            guard !shiftOverflow else { throw .overflow }
            let (sum, addOverflow) = shifted.addingReportingOverflow(digit)
            guard !addOverflow else { throw .overflow }
            result = sum
            input.formIndex(after: &index)
            count += 1
        }

        guard count > 0 else { throw .noDigits }

        input = input[index...]
        return result
    }

    @inlinable
    static func _hexValue(_ byte: UInt8) -> T? {
        switch byte {
        case 0x30...0x39: T(byte &- 0x30)
        case 0x41...0x46: T(byte &- 0x37)
        case 0x61...0x66: T(byte &- 0x57)
        default: nil
        }
    }
}
