import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Many")
struct ParserManySimpleTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserManySimpleTests.Unit {
    @Test
    func `zero or more collects all matching elements`() throws(any Swift.Error) {
        let parser = Parser.Many {
            Parser.First.Where<Parser.Test.Input> { $0 == 0x41 }
        }
        var input = Parser.Test.Input([0x41, 0x41, 0x41, 0x42])

        let result = try parser.parse(&input)

        #expect(result.count == 3)
        #expect(input.first == 0x42)
    }

    @Test
    func `one or more requires at least one match`() throws(any Swift.Error) {
        let parser = Parser.Many(1...) {
            Parser.First.Element<Parser.Test.Input>()
        }
        var input = Parser.Test.Input([0x0A, 0x0B])

        let result = try parser.parse(&input)

        #expect(result == [0x0A, 0x0B])
    }

    @Test
    func `exact count with closed range`() throws(any Swift.Error) {
        let parser = Parser.Many(2...2) {
            Parser.First.Element<Parser.Test.Input>()
        }
        var input = Parser.Test.Input([0x01, 0x02, 0x03])

        let result = try parser.parse(&input)

        #expect(result == [0x01, 0x02])
        #expect(input.first == 0x03)
    }
}

// MARK: - Edge Case Tests

extension ParserManySimpleTests.EdgeCase {
    @Test
    func `zero or more returns empty on no match`() throws(any Swift.Error) {
        let parser = Parser.Many {
            Parser.First.Where<Parser.Test.Input> { $0 == 0xFF }
        }
        var input = Parser.Test.Input([0x01])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
        #expect(input.first == 0x01)
    }

    @Test
    func `one or more fails on empty input`() {
        let parser = Parser.Many(1...) {
            Parser.First.Element<Parser.Test.Input>()
        }
        var input = Parser.Test.Input([])

        #expect(throws: Parser.Many<Parser.Test.Input, Parser.First.Element<Parser.Test.Input>>.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `zero or more succeeds on empty input`() throws(any Swift.Error) {
        let parser = Parser.Many {
            Parser.First.Element<Parser.Test.Input>()
        }
        var input = Parser.Test.Input([])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }
}
