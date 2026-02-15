import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.Many.Simple")
struct ParserManySimpleTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserManySimpleTests.Unit {
    @Test
    func `zero or more collects all matching elements`() throws {
        let parser = Parser.Many.Simple<ByteInput, Parser.Byte<ByteInput>> {
            Parser.Byte<ByteInput>(0x41)
        }
        var input = ByteInput([0x41, 0x41, 0x41, 0x42])

        let result = try parser.parse(&input)

        #expect(result.count == 3)
        #expect(input.first == 0x42)
    }

    @Test
    func `one or more requires at least one match`() throws {
        let parser = Parser.Many.Simple<ByteInput, Parser.First.Element<ByteInput>>(1...) {
            Parser.First.Element<ByteInput>()
        }
        var input = ByteInput([0x0A, 0x0B])

        let result = try parser.parse(&input)

        #expect(result == [0x0A, 0x0B])
    }

    @Test
    func `exact count with closed range`() throws {
        let parser = Parser.Many.Simple<ByteInput, Parser.First.Element<ByteInput>>(2...2) {
            Parser.First.Element<ByteInput>()
        }
        var input = ByteInput([0x01, 0x02, 0x03])

        let result = try parser.parse(&input)

        #expect(result == [0x01, 0x02])
        #expect(input.first == 0x03)
    }
}

// MARK: - Edge Case Tests

extension ParserManySimpleTests.EdgeCase {
    @Test
    func `zero or more returns empty on no match`() throws {
        let parser = Parser.Many.Simple<ByteInput, Parser.Byte<ByteInput>> {
            Parser.Byte<ByteInput>(0xFF)
        }
        var input = ByteInput([0x01])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
        #expect(input.first == 0x01)
    }

    @Test
    func `one or more fails on empty input`() {
        let parser = Parser.Many.Simple<ByteInput, Parser.First.Element<ByteInput>>(1...) {
            Parser.First.Element<ByteInput>()
        }
        var input = ByteInput([])

        #expect(throws: Parser.Many.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `zero or more succeeds on empty input`() throws {
        let parser = Parser.Many.Simple<ByteInput, Parser.First.Element<ByteInput>> {
            Parser.First.Element<ByteInput>()
        }
        var input = ByteInput([])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }
}
