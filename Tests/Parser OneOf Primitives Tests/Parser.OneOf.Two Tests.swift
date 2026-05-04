import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.OneOf.Two")
struct ParserOneOfTwoTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserOneOfTwoTests.Unit {
    @Test
    func `returns first parser result when it succeeds`() throws {
        let parser = Parser.OneOf.Two(
            Parser.Byte<ByteInput>(0x41).map { "A" },
            Parser.Byte<ByteInput>(0x42).map { "B" }
        )
        var input = ByteInput([0x41])

        let result = try parser.parse(&input)

        #expect(result == "A")
    }

    @Test
    func `falls back to second parser when first fails`() throws {
        let parser = Parser.OneOf.Two(
            Parser.Byte<ByteInput>(0x41).map { "A" },
            Parser.Byte<ByteInput>(0x42).map { "B" }
        )
        var input = ByteInput([0x42])

        let result = try parser.parse(&input)

        #expect(result == "B")
    }
}

// MARK: - Edge Case Tests

extension ParserOneOfTwoTests.EdgeCase {
    @Test
    func `fails when both alternatives fail`() {
        let parser = Parser.OneOf.Two(
            Parser.Byte<ByteInput>(0x41),
            Parser.Byte<ByteInput>(0x42)
        )
        var input = ByteInput([0x43])

        #expect(throws: (any Error).self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `backtracks first attempt before trying second`() throws {
        let parser = Parser.OneOf.Two(
            Parser.Byte<ByteInput>(0xFF).map { "first" },
            Parser.First.Element<ByteInput>().map { _ in "second" }
        )
        var input = ByteInput([0x42])

        let result = try parser.parse(&input)

        #expect(result == "second")
        #expect(input.isEmpty)
    }
}
