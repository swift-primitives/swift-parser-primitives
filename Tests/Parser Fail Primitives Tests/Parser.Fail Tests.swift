import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Fail")
struct ParserFailTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserFailTests.Unit {
    @Test
    func `always throws the provided error`() {
        let parser = Parser.Fail<Parser.Test.Input, Int, Parser.Match.Error>(
            .predicateFailed(description: "test error")
        )
        var input = Parser.Test.Input([0x01, 0x02])

        #expect(throws: Parser.Match.Error.self) {
            try parser.parse(&input)
        }
    }
}

// MARK: - Edge Case Tests

extension ParserFailTests.EdgeCase {
    @Test
    func `throws on empty input without consuming`() {
        let parser = Parser.Fail<Parser.Test.Input, Void, Parser.Constraint.Error>(
            .countTooLow(expected: 1, got: 0)
        )
        var input = Parser.Test.Input([])

        #expect(throws: Parser.Constraint.Error.self) {
            try parser.parse(&input)
        }
    }
}
