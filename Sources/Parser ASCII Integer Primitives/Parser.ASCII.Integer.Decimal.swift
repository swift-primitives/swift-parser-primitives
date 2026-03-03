//
//  Parser.ASCII.Integer.Decimal.swift
//  swift-parser-primitives
//
//  Parses a decimal integer from ASCII bytes.
//

public import Collection_Primitives

extension Parser.ASCII.Integer {
    /// A parser that consumes one or more ASCII decimal digit bytes (0x30–0x39)
    /// and accumulates them into a `FixedWidthInteger`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let port = Parser.ASCII.Integer.Decimal<Input, UInt16>()
    /// let value = try port.parse(&input) // e.g. 8080
    /// ```
    public struct Decimal<Input: Collection.Slice.`Protocol`, T: FixedWidthInteger>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension Parser.ASCII.Integer.Decimal: Parser.`Protocol` {
    public typealias ParseOutput = T
    public typealias Failure = Parser.ASCII.Integer.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> T {
        var result: T = 0
        var count = 0
        var index = input.startIndex

        while index < input.endIndex {
            let byte = input[index]
            guard byte >= 0x30, byte <= 0x39 else {
                break
            }
            let digit = T(byte &- 0x30)
            let (product, mulOverflow) = result.multipliedReportingOverflow(by: 10)
            guard !mulOverflow else { throw .overflow }
            let (sum, addOverflow) = product.addingReportingOverflow(digit)
            guard !addOverflow else { throw .overflow }
            result = sum
            input.formIndex(after: &index)
            count += 1
        }

        guard count > 0 else { throw .noDigits }

        input = input[index...]
        return result
    }
}
