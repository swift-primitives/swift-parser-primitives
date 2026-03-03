import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.ASCII.Integer")
struct ParserASCIIIntegerTests {
    @Suite("Decimal") struct Decimal {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
    @Suite("Hexadecimal") struct Hexadecimal {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Decimal Unit Tests

extension ParserASCIIIntegerTests.Decimal.Unit {
    @Test
    func `parses single digit`() throws {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, Int>()
        var input: ByteInput = [0x35] // "5"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }

    @Test
    func `parses multi-digit number`() throws {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, Int>()
        var input: ByteInput = [0x31, 0x32, 0x33] // "123"

        let result = try parser.parse(&input)

        #expect(result == 123)
        #expect(input.isEmpty)
    }

    @Test
    func `stops at non-digit byte`() throws {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, Int>()
        var input: ByteInput = [0x34, 0x32, 0x2E, 0x35] // "42.5"

        let result = try parser.parse(&input)

        #expect(result == 42)
        #expect(input.first == 0x2E)
    }

    @Test
    func `parses into UInt16`() throws {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, UInt16>()
        var input: ByteInput = [0x38, 0x30, 0x38, 0x30] // "8080"

        let result = try parser.parse(&input)

        #expect(result == 8080)
    }

    @Test
    func `parses zero`() throws {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, Int>()
        var input: ByteInput = [0x30] // "0"

        let result = try parser.parse(&input)

        #expect(result == 0)
    }

    @Test
    func `parses leading zeros`() throws {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, Int>()
        var input: ByteInput = [0x30, 0x30, 0x35] // "005"

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(input.isEmpty)
    }
}

// MARK: - Decimal Edge Case Tests

extension ParserASCIIIntegerTests.Decimal.EdgeCase {
    @Test
    func `fails on empty input`() {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, Int>()
        var input: ByteInput = []

        #expect(throws: Parser.ASCII.Integer.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on non-digit first byte`() {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, Int>()
        var input: ByteInput = [0x41] // "A"

        #expect(throws: Parser.ASCII.Integer.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `detects UInt8 overflow`() {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, UInt8>()
        var input: ByteInput = [0x32, 0x35, 0x36] // "256"

        #expect(throws: Parser.ASCII.Integer.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `boundary value UInt8 max`() throws {
        let parser = Parser.ASCII.Integer.Decimal<ByteInput, UInt8>()
        var input: ByteInput = [0x32, 0x35, 0x35] // "255"

        let result = try parser.parse(&input)

        #expect(result == 255)
    }
}

// MARK: - Hexadecimal Unit Tests

extension ParserASCIIIntegerTests.Hexadecimal.Unit {
    @Test
    func `parses lowercase hex`() throws {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, UInt32>()
        var input: ByteInput = [0x64, 0x65, 0x61, 0x64] // "dead"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses uppercase hex`() throws {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, UInt32>()
        var input: ByteInput = [0x44, 0x45, 0x41, 0x44] // "DEAD"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses mixed case hex`() throws {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, UInt32>()
        var input: ByteInput = [0x44, 0x65, 0x41, 0x64] // "DeAd"

        let result = try parser.parse(&input)

        #expect(result == 0xDEAD)
    }

    @Test
    func `parses decimal digits as hex`() throws {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, UInt8>()
        var input: ByteInput = [0x31, 0x30] // "10"

        let result = try parser.parse(&input)

        #expect(result == 0x10)
    }

    @Test
    func `stops at non-hex byte`() throws {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, UInt32>()
        var input: ByteInput = [0x46, 0x46, 0x3B] // "FF;"

        let result = try parser.parse(&input)

        #expect(result == 0xFF)
        #expect(input.first == 0x3B)
    }
}

// MARK: - Hexadecimal Edge Case Tests

extension ParserASCIIIntegerTests.Hexadecimal.EdgeCase {
    @Test
    func `fails on empty input`() {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, Int>()
        var input: ByteInput = []

        #expect(throws: Parser.ASCII.Integer.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on non-hex first byte`() {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, Int>()
        var input: ByteInput = [0x47] // "G"

        #expect(throws: Parser.ASCII.Integer.Error.noDigits) {
            try parser.parse(&input)
        }
    }

    @Test
    func `detects UInt8 overflow`() {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, UInt8>()
        var input: ByteInput = [0x31, 0x30, 0x30] // "100" = 256

        #expect(throws: Parser.ASCII.Integer.Error.overflow) {
            try parser.parse(&input)
        }
    }

    @Test
    func `boundary value UInt8 max`() throws {
        let parser = Parser.ASCII.Integer.Hexadecimal<ByteInput, UInt8>()
        var input: ByteInput = [0x46, 0x46] // "FF"

        let result = try parser.parse(&input)

        #expect(result == 255)
    }
}
