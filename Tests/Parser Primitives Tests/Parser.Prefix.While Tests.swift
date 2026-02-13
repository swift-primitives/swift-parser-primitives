import Testing
import Parser_Primitives_Test_Support

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
        let digits = Parser.Prefix.While<ArraySlice<UInt8>> {
            $0 >= 0x30 && $0 <= 0x39
        }
        var input = ArraySlice<UInt8>(Array("123abc".utf8))

        let result = try digits.parse(&input)

        #expect(Array(result) == Array("123".utf8))
        #expect(input.first == UInt8(ascii: "a"))
    }

    @Test
    func `consumes all input when predicate always holds`() throws {
        let all = Parser.Prefix.While<ArraySlice<UInt8>> { _ in true }
        var input = ArraySlice<UInt8>([0x01, 0x02, 0x03])

        let result = try all.parse(&input)

        #expect(Array(result) == [0x01, 0x02, 0x03])
        #expect(input.isEmpty)
    }
}

// MARK: - Edge Case Tests

extension ParserPrefixWhileTests.EdgeCase {
    @Test
    func `returns empty when predicate immediately fails`() throws {
        let parser = Parser.Prefix.While<ArraySlice<UInt8>> { _ in false }
        var input = ArraySlice<UInt8>([0x01, 0x02])

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }

    @Test
    func `minLength enforcement fails when too few match`() {
        let parser = Parser.Prefix.While<ArraySlice<UInt8>>(minLength: 3) {
            $0 >= 0x30 && $0 <= 0x39
        }
        var input = ArraySlice<UInt8>(Array("12x".utf8))

        #expect(throws: Parser.Constraint.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `maxLength caps consumed count`() throws {
        let parser = Parser.Prefix.While<ArraySlice<UInt8>>(maxLength: 2) { _ in true }
        var input = ArraySlice<UInt8>([0x01, 0x02, 0x03, 0x04])

        let result = try parser.parse(&input)

        #expect(result.count == 2)
        #expect(input.count == 2)
    }

    @Test
    func `empty input returns empty result`() throws {
        let parser = Parser.Prefix.While<ArraySlice<UInt8>> { _ in true }
        var input: ArraySlice<UInt8> = []

        let result = try parser.parse(&input)

        #expect(result.isEmpty)
    }
}
