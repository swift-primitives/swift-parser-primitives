import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.Rest")
struct ParserRestTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserRestTests.Unit {
    @Test
    func `consumes all remaining input`() {
        let parser = Parser.Rest<ByteInput>()
        var input: ByteInput = [0x01, 0x02, 0x03]

        let result = parser.parse(&input)

        #expect(result == [0x01, 0x02, 0x03])
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ParserRestTests.EdgeCase {
    @Test
    func `returns empty slice on empty input`() {
        let parser = Parser.Rest<ByteInput>()
        var input: ByteInput = []

        let result = parser.parse(&input)

        #expect(result.isEmpty)
        #expect(input.isEmpty)
    }

    @Test
    func `returns single element`() {
        let parser = Parser.Rest<ByteInput>()
        var input: ByteInput = [0xFF]

        let result = parser.parse(&input)

        #expect(result == [0xFF])
    }
}
