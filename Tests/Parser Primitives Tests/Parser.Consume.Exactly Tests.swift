import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.Consume.Exactly")
struct ParserConsumeExactlyTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserConsumeExactlyTests.Unit {
    @Test
    func `consumes exactly N elements`() throws {
        let parser = Parser.Consume.Exactly<ArraySlice<UInt8>>(3)
        var input = ArraySlice<UInt8>([0x01, 0x02, 0x03, 0x04, 0x05])

        let result = try parser.parse(&input)

        #expect(Array(result) == [0x01, 0x02, 0x03])
        #expect(input.count == 2)
    }

    @Test
    func `consumes all when count equals input length`() throws {
        let parser = Parser.Consume.Exactly<ArraySlice<UInt8>>(3)
        var input = ArraySlice<UInt8>([0x0A, 0x0B, 0x0C])

        let result = try parser.parse(&input)

        #expect(Array(result) == [0x0A, 0x0B, 0x0C])
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ParserConsumeExactlyTests.EdgeCase {
    @Test
    func `fails when input has fewer elements than requested`() {
        let parser = Parser.Consume.Exactly<ArraySlice<UInt8>>(5)
        var input = ArraySlice<UInt8>([0x01, 0x02])

        #expect(throws: Parser.Constraint.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `zero count succeeds without consuming`() throws {
        let parser = Parser.Consume.Exactly<ArraySlice<UInt8>>(0)
        var input = ArraySlice<UInt8>([0x01])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
        #expect(!input.isEmpty)
    }

    @Test
    func `zero count succeeds on empty input`() throws {
        let parser = Parser.Consume.Exactly<ArraySlice<UInt8>>(0)
        var input: ArraySlice<UInt8> = []

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }
}
