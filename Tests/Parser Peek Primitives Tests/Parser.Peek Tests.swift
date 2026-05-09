import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Peek")
struct ParserPeekTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserPeekTests.Unit {
    @Test
    func `returns output without consuming input`() throws {
        let parser = Parser.First.Element<ByteInput>().peek()
        var input = ByteInput([0x41, 0x42])

        let result = try parser.parse(&input)

        #expect(result == 0x41)
        #expect(input.first == 0x41)
    }

    @Test
    func `repeated peeks return same value`() throws {
        let parser = Parser.First.Element<ByteInput>().peek()
        var input = ByteInput([0xFF])

        let first = try parser.parse(&input)
        let second = try parser.parse(&input)

        #expect(first == second)
        #expect(first == 0xFF)
    }
}

// MARK: - Edge Case Tests

extension ParserPeekTests.EdgeCase {
    @Test
    func `upstream failure does not consume input`() {
        let parser = Parser.Byte<ByteInput>(0x41).peek()
        var input = ByteInput([0x42])

        #expect(throws: (any Swift.Error).self) {
            try parser.parse(&input)
        }
        #expect(input.first == 0x42)
    }

    @Test
    func `empty input propagates upstream error`() {
        let parser = Parser.First.Element<ByteInput>().peek()
        var input = ByteInput([])

        #expect(throws: Parser.EndOfInput.Error.self) {
            try parser.parse(&input)
        }
    }
}
