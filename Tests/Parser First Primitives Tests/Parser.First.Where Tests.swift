import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

@Suite("Parser.First.Where")
struct ParserFirstWhereTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit Tests

extension ParserFirstWhereTests.Unit {
    @Test
    func `returns element when predicate matches`() throws {
        let parser = Parser.First.Where<ByteInput>(expected: "digit") {
            $0 >= 0x30 && $0 <= 0x39
        }
        var input = ByteInput([0x35, 0x41])

        let result = try parser.parse(&input)

        #expect(result == 0x35)
        #expect(input.first == 0x41)
    }
}

// MARK: - Edge Case Tests

extension ParserFirstWhereTests.EdgeCase {
    @Test
    func `fails on empty input with EndOfInput error`() {
        let parser = Parser.First.Where<ByteInput> { _ in true }
        var input = ByteInput([])

        #expect {
            try parser.parse(&input)
        } throws: { error in
            guard let either = error as? Either<Parser.EndOfInput.Error, Parser.Match.Error> else {
                return false
            }
            return either.left != nil
        }
    }

    @Test
    func `fails when predicate returns false`() {
        let parser = Parser.First.Where<ByteInput>(expected: "uppercase") {
            $0 >= 0x41 && $0 <= 0x5A
        }
        var input = ByteInput([0x61])

        #expect {
            try parser.parse(&input)
        } throws: { error in
            guard let either = error as? Either<Parser.EndOfInput.Error, Parser.Match.Error> else {
                return false
            }
            return either.right != nil
        }
    }
}
