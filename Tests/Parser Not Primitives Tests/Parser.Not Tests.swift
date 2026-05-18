import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Not")
struct ParserNotTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserNotTests.Unit {
    @Test
    func `succeeds when upstream fails`() throws(any Swift.Error) {
        let parser = Parser.First.Where<Parser.Test.Input> { $0 == 0x41 }.not()
        var input = Parser.Test.Input([0x42])

        try parser.parse(&input)

        // Input not consumed
        #expect(input.first == 0x42)
    }

    @Test
    func `never consumes input on success`() throws(any Swift.Error) {
        let parser = Parser.First.Element<Parser.Test.Input>()
            .filter { $0 == 0xFF }
            .not()
        var input = Parser.Test.Input([0x01, 0x02])

        try parser.parse(&input)

        #expect(input.first == 0x01)
    }
}

// MARK: - Edge Case Tests

extension ParserNotTests.EdgeCase {
    @Test
    func `fails when upstream succeeds`() {
        let parser = Parser.First.Where<Parser.Test.Input> { $0 == 0x41 }.not()
        var input = Parser.Test.Input([0x41])

        #expect(throws: Parser.Not<Parser.First.Where<Parser.Test.Input>>.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `never consumes input on failure`() {
        let parser = Parser.First.Where<Parser.Test.Input> { $0 == 0x41 }.not()
        var input = Parser.Test.Input([0x41, 0x42])

        _ = try? parser.parse(&input)

        #expect(input.first == 0x41)
    }

    @Test
    func `succeeds on empty input when upstream requires elements`() throws(any Swift.Error) {
        let parser = Parser.First.Element<Parser.Test.Input>().not()
        var input = Parser.Test.Input([])

        try parser.parse(&input)
    }
}
