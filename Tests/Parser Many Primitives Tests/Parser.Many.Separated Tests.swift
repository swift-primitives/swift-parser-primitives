import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Many.Separated")
struct ParserManySeparatedTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserManySeparatedTests.Unit {
    @Test
    func `parses comma-separated bytes`() throws {
        let parser = Parser.Many.Separated<ByteInput, Parser.First.Element<ByteInput>, Parser.Byte<ByteInput>> {
            Parser.First.Element<ByteInput>()
        } separator: {
            Parser.Byte<ByteInput>(UInt8(ascii: ","))
        }
        var input = ByteInput(utf8: "a,b,c")

        let result = try parser.parse(&input)

        #expect(result.count == 3)
        #expect(result[0] == UInt8(ascii: "a"))
        #expect(result[1] == UInt8(ascii: "b"))
        #expect(result[2] == UInt8(ascii: "c"))
    }

    @Test
    func `single element without separator`() throws {
        let parser = Parser.Many.Separated<ByteInput, Parser.First.Element<ByteInput>, Parser.Byte<ByteInput>> {
            Parser.First.Element<ByteInput>()
        } separator: {
            Parser.Byte<ByteInput>(UInt8(ascii: ","))
        }
        var input = ByteInput([0x42])

        let result = try parser.parse(&input)

        #expect(result == [0x42])
    }
}

// MARK: - Edge Case Tests

extension ParserManySeparatedTests.EdgeCase {
    @Test
    func `empty input returns empty array`() throws {
        let parser = Parser.Many.Separated<ByteInput, Parser.Byte<ByteInput>, Parser.Byte<ByteInput>> {
            Parser.Byte<ByteInput>(0x41)
        } separator: {
            Parser.Byte<ByteInput>(UInt8(ascii: ","))
        }
        var input = ByteInput([])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }

    @Test
    func `trailing separator not consumed`() throws {
        let parser = Parser.Many.Separated<ByteInput, Parser.Byte<ByteInput>, Parser.Byte<ByteInput>> {
            Parser.Byte<ByteInput>(UInt8(ascii: "x"))
        } separator: {
            Parser.Byte<ByteInput>(UInt8(ascii: ","))
        }
        var input = ByteInput(utf8: "x,x,")

        let result = try parser.parse(&input)

        #expect(result.count == 2)
        #expect(input.first == UInt8(ascii: ","))
    }

    @Test
    func `minimum count enforcement`() {
        let parser = Parser.Many.Separated<ByteInput, Parser.Byte<ByteInput>, Parser.Byte<ByteInput>>(3...) {
            Parser.Byte<ByteInput>(UInt8(ascii: "a"))
        } separator: {
            Parser.Byte<ByteInput>(UInt8(ascii: ","))
        }
        var input = ByteInput(utf8: "a,a")

        #expect(throws: Parser.Many.Error.self) {
            try parser.parse(&input)
        }
    }
}
