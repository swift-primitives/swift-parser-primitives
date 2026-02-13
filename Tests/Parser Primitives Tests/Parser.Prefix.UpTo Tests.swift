import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.Prefix.UpTo")
struct ParserPrefixUpToTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserPrefixUpToTests.Unit {
    @Test
    func `consumes up to delimiter without including it`() {
        let parser = Parser.Prefix.UpTo<ArraySlice<UInt8>>([UInt8(ascii: ",")])
        var input = ArraySlice<UInt8>(Array("hello,world".utf8))

        let result = parser.parse(&input)

        #expect(Array(result) == Array("hello".utf8))
        #expect(input.first == UInt8(ascii: ","))
    }

    @Test
    func `handles multi-byte delimiter`() {
        let parser = Parser.Prefix.UpTo<ArraySlice<UInt8>>(Array("-->".utf8))
        var input = ArraySlice<UInt8>(Array("content-->rest".utf8))

        let result = parser.parse(&input)

        #expect(Array(result) == Array("content".utf8))
    }
}

// MARK: - Edge Case Tests

extension ParserPrefixUpToTests.EdgeCase {
    @Test
    func `consumes all when delimiter not found`() {
        let parser = Parser.Prefix.UpTo<ArraySlice<UInt8>>([0xFF])
        var input = ArraySlice<UInt8>([0x01, 0x02, 0x03])

        let result = parser.parse(&input)

        #expect(Array(result) == [0x01, 0x02, 0x03])
    }

    @Test
    func `returns empty when delimiter at start`() {
        let parser = Parser.Prefix.UpTo<ArraySlice<UInt8>>([UInt8(ascii: "x")])
        var input = ArraySlice<UInt8>(Array("xyz".utf8))

        let result = parser.parse(&input)

        #expect(result.isEmpty)
        #expect(input.first == UInt8(ascii: "x"))
    }

    @Test
    func `empty input returns empty result`() {
        let parser = Parser.Prefix.UpTo<ArraySlice<UInt8>>([0x00])
        var input: ArraySlice<UInt8> = []

        let result = parser.parse(&input)

        #expect(result.isEmpty)
    }
}
