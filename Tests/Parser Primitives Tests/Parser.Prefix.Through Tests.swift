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
        let parser = Parser.Prefix.Through<ArraySlice<UInt8>>([UInt8(ascii: "\n")])
        var input = ArraySlice<UInt8>(Array("line1\nline2".utf8))

        let result = try parser.parse(&input)

        #expect(Array(result) == Array("line1\n".utf8))
        #expect(input.first == UInt8(ascii: "l"))
    }

    @Test
    func `handles multi-byte delimiter`() throws {
        let parser = Parser.Prefix.Through<ArraySlice<UInt8>>(Array("\r\n".utf8))
        var input = ArraySlice<UInt8>(Array("header\r\nbody".utf8))

        let result = try parser.parse(&input)

        #expect(Array(result) == Array("header\r\n".utf8))
    }
}

// MARK: - Edge Case Tests

extension ParserPrefixThroughTests.EdgeCase {
    @Test
    func `fails when delimiter not found`() {
        let parser = Parser.Prefix.Through<ArraySlice<UInt8>>([0xFF])
        var input = ArraySlice<UInt8>([0x01, 0x02])

        #expect(throws: Parser.Match.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `consumes entire input when delimiter at end`() throws {
        let parser = Parser.Prefix.Through<ArraySlice<UInt8>>([UInt8(ascii: "!")])
        var input = ArraySlice<UInt8>(Array("ok!".utf8))

        let result = try parser.parse(&input)

        #expect(Array(result) == Array("ok!".utf8))
        #expect(input.isEmpty)
    }
}
