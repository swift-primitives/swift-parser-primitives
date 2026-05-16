import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Optionally")
struct ParserOptionallyTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserOptionallyTests.Unit {
    @Test
    func `returns value when parser succeeds`() {
        let parser = Parser.Optionally<Parser.First.Where<Parser.Test.Input>> {
            Parser.First.Where<Parser.Test.Input> { $0 == 0x41 }
        }
        var input = Parser.Test.Input([0x41, 0x42])

        let result = parser.parse(&input)

        #expect(result != nil)
        #expect(input.first == 0x42)
    }

    @Test
    func `returns nil when parser fails`() {
        let parser = Parser.Optionally<Parser.First.Where<Parser.Test.Input>> {
            Parser.First.Where<Parser.Test.Input> { $0 == 0x41 }
        }
        var input = Parser.Test.Input([0x42])

        let result = parser.parse(&input)

        #expect(result == nil)
    }
}

// MARK: - Edge Case Tests

extension ParserOptionallyTests.EdgeCase {
    @Test
    func `backtracks on failure`() {
        let parser = Parser.Optionally<Parser.First.Where<Parser.Test.Input>> {
            Parser.First.Where<Parser.Test.Input> { $0 == 0xFF }
        }
        var input = Parser.Test.Input([0x01, 0x02])

        _ = parser.parse(&input)

        #expect(input.first == 0x01)
    }

    @Test
    func `returns nil on empty input`() {
        let parser = Parser.Optionally<Parser.First.Element<Parser.Test.Input>> {
            Parser.First.Element<Parser.Test.Input>()
        }
        var input = Parser.Test.Input([])

        let result = parser.parse(&input)

        #expect(result == nil)
    }
}
