import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.Prefix.Through")
struct ParserPrefixThroughTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserPrefixThroughTests.Unit {
    @Test
    func `consumes through delimiter including it`() throws {
        let parser = Parser.Prefix.Through<ByteInput>([UInt8(ascii: "\n")])
        var input = ByteInput(utf8: "line1\nline2")

        let result = try parser.parse(&input)

        #expect(result == ByteInput(utf8: "line1\n"))
        #expect(input.first == UInt8(ascii: "l"))
    }

    @Test
    func `handles multi-byte delimiter`() throws {
        let parser = Parser.Prefix.Through<ByteInput>(Swift.Array("\r\n".utf8))
        var input = ByteInput(utf8: "header\r\nbody")

        let result = try parser.parse(&input)

        #expect(result == ByteInput(utf8: "header\r\n"))
    }
}

// MARK: - Edge Case Tests

extension ParserPrefixThroughTests.EdgeCase {
    @Test
    func `fails when delimiter not found`() {
        let parser = Parser.Prefix.Through<ByteInput>([0xFF])
        var input: ByteInput = [0x01, 0x02]

        #expect(throws: Parser.Match.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `consumes entire input when delimiter at end`() throws {
        let parser = Parser.Prefix.Through<ByteInput>([UInt8(ascii: "!")])
        var input = ByteInput(utf8: "ok!")

        let result = try parser.parse(&input)

        #expect(result == ByteInput(utf8: "ok!"))
        #expect(input.isEmpty)
    }
}
