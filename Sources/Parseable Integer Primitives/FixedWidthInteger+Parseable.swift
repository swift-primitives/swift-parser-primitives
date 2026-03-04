//
//  FixedWidthInteger+Parseable.swift
//  swift-parser-primitives
//
//  Parseable conformances for standard library integer types.
//

extension Int: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, Int> { .init() }
}

extension UInt: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, UInt> { .init() }
}

extension Int8: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, Int8> { .init() }
}

extension Int16: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, Int16> { .init() }
}

extension Int32: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, Int32> { .init() }
}

extension Int64: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, Int64> { .init() }
}

extension UInt8: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, UInt8> { .init() }
}

extension UInt16: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, UInt16> { .init() }
}

extension UInt32: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, UInt32> { .init() }
}

extension UInt64: Parseable {
    public static var parser: Parser.ASCII.Integer.Decimal<Parser.ByteInput, UInt64> { .init() }
}
