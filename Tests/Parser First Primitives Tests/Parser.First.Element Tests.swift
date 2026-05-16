import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.First.Element")
struct ParserFirstElementTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserFirstElementTests.Unit {
    @Test
    func `returns first element and advances`() throws {
        let parser = Parser.First.Element<Parser.Test.Input>()
        var input = Parser.Test.Input([0x41, 0x42, 0x43])

        let result = try parser.parse(&input)

        #expect(result == 0x41)
        #expect(input.first == 0x42)
    }

    @Test
    func `consumes last element leaving input empty`() throws {
        let parser = Parser.First.Element<Parser.Test.Input>()
        var input = Parser.Test.Input([0xFF])

        let result = try parser.parse(&input)

        #expect(result == 0xFF)
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ParserFirstElementTests.EdgeCase {
    @Test
    func `fails on empty input`() {
        let parser = Parser.First.Element<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        #expect(throws: Parser.EndOfInput.Error.self) {
            try parser.parse(&input)
        }
    }
}
