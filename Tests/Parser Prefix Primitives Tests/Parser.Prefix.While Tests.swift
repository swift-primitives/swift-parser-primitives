import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Prefix.While")
struct ParserPrefixWhileTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserPrefixWhileTests.Unit {
    @Test
    func `consumes while predicate holds`() throws {
        let digits = Parser.Prefix.While<ByteInput> {
            $0 >= 0x30 && $0 <= 0x39
        }
        // "123abc" as UTF-8 bytes
        var input = ByteInput([0x31, 0x32, 0x33, 0x61, 0x62, 0x63])

        let result = try digits.parse(&input)

        #expect(result.count == 3)
        #expect(input.first == 0x61)
    }

    @Test
    func `consumes all input when predicate always holds`() throws {
        let all = Parser.Prefix.While<ByteInput> { _ in true }
        var input = ByteInput([0x01, 0x02, 0x03])

        let result = try all.parse(&input)

        #expect(result.count == 3)
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ParserPrefixWhileTests.EdgeCase {
    @Test
    func `returns empty when predicate immediately fails`() throws {
        let parser = Parser.Prefix.While<ByteInput> { _ in false }
        var input = ByteInput([0x01, 0x02])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }

    @Test
    func `minLength enforcement fails when too few match`() {
        let parser = Parser.Prefix.While<ByteInput>(minLength: 3) {
            $0 >= 0x30 && $0 <= 0x39
        }
        // "12x" as UTF-8 bytes
        var input = ByteInput([0x31, 0x32, 0x78])

        #expect(throws: Parser.Constraint.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `maxLength caps consumed count`() throws {
        let parser = Parser.Prefix.While<ByteInput>(maxLength: 2) { _ in true }
        var input = ByteInput([0x01, 0x02, 0x03, 0x04])

        let result = try parser.parse(&input)

        #expect(result.count == 2)
        #expect(input.count == 2)
    }

    @Test
    func `empty input returns empty result`() throws {
        let parser = Parser.Prefix.While<ByteInput> { _ in true }
        var input: ByteInput = []

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }
}
