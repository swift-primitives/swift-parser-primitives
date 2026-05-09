import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Literal")
struct ParserLiteralTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserLiteralTests.Unit {
    @Test
    func `matches byte sequence and advances input`() throws {
        let parser = Parser.Literal<ByteInput>([0x48, 0x65, 0x6C])
        var input = ByteInput([0x48, 0x65, 0x6C, 0x6C, 0x6F])

        try parser.parse(&input)

        #expect(input.first == 0x6C)
    }

    @Test
    func `string literal construction matches UTF-8 bytes`() throws {
        let parser: Parser.Literal<ByteInput> = "OK"
        var input = ByteInput(utf8: "OK!")

        try parser.parse(&input)

        #expect(input.first == UInt8(ascii: "!"))
    }

    @Test
    func `exact match consumes all input`() throws {
        let parser: Parser.Literal<ByteInput> = "end"
        var input = ByteInput(utf8: "end")

        try parser.parse(&input)

        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ParserLiteralTests.EdgeCase {
    @Test
    func `empty literal matches without consuming`() throws {
        let parser = Parser.Literal<ByteInput>([])
        var input = ByteInput([0x01, 0x02])

        try parser.parse(&input)

        #expect(input.first == 0x01)
    }

    @Test
    func `fails on empty input`() {
        let parser: Parser.Literal<ByteInput> = "x"
        var input = ByteInput([])

        #expect(throws: (any Swift.Error).self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `fails on partial match`() {
        let parser: Parser.Literal<ByteInput> = "abc"
        var input = ByteInput(utf8: "abx")

        #expect(throws: (any Swift.Error).self) {
            try parser.parse(&input)
        }
    }
}
