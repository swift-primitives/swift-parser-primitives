import Parser_Primitives
import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Always")
struct ParserAlwaysTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserAlwaysTests.Unit {
    @Test
    func `returns provided value without consuming input`() {
        let parser = Parser.Always<Parser.Test.Input, Int>(42)
        var input = Parser.Test.Input([0x01, 0x02, 0x03])

        let result = parser.parse(&input)

        #expect(result == 42)
        #expect(!input.isEmpty)
    }

    @Test
    func `produces Void output`() {
        let parser = Parser.Always<Parser.Test.Input, Void>(())
        var input = Parser.Test.Input([0xFF])

        parser.parse(&input)

        #expect(!input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ParserAlwaysTests.EdgeCase {
    @Test
    func `succeeds on empty input`() {
        let parser = Parser.Always<Parser.Test.Input, String>("hello")
        var input = Parser.Test.Input([])

        let result = parser.parse(&input)

        #expect(result == "hello")
        #expect(input.isEmpty)
    }
}
