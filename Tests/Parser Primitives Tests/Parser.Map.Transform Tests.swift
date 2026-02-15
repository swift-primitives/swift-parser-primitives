import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.Map.Transform")
struct ParserMapTransformTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserMapTransformTests.Unit {
    @Test
    func `transforms output of upstream parser`() throws {
        let parser = Parser.First.Element<ByteInput>()
            .map { Int($0) }
        var input = ByteInput([0x0A])

        let result = try parser.parse(&input)

        #expect(result == 10)
    }

    @Test
    func `preserves input consumption from upstream`() throws {
        let parser = Parser.First.Element<ByteInput>()
            .map { String($0, radix: 16) }
        var input = ByteInput([0xFF, 0x01])

        _ = try parser.parse(&input)

        #expect(input.first == 0x01)
    }
}

// MARK: - Edge Case Tests

extension ParserMapTransformTests.EdgeCase {
    @Test
    func `upstream failure propagates through map`() {
        let parser = Parser.First.Element<ByteInput>()
            .map { $0 * 2 }
        var input = ByteInput([])

        #expect(throws: Parser.EndOfInput.Error.self) {
            try parser.parse(&input)
        }
    }
}
