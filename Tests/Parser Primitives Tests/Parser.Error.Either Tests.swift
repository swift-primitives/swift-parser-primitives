import Testing
import Parser_Primitives_Test_Support

// MARK: - Test Suite Structure

extension Parser.Error.Either where Left == Parser.EndOfInput.Error, Right == Parser.Match.Error {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit Tests

extension Parser.Error.Either<Parser.EndOfInput.Error, Parser.Match.Error>.Test.Unit {
    typealias E = Parser.Error.Either<Parser.EndOfInput.Error, Parser.Match.Error>

    @Test
    func `left case extracts left value`() {
        let error = E.left(.unexpected(expected: "byte"))

        #expect(error.left != nil)
        #expect(error.right == nil)
    }

    @Test
    func `right case extracts right value`() {
        let error = E.right(.expectedEnd(remaining: 5))

        #expect(error.left == nil)
        #expect(error.right != nil)
    }

    @Test
    func `first accessor is alias for left`() {
        let error = E.left(.unexpected(expected: "test"))

        #expect(error.first != nil)
    }

    @Test
    func `equatable conformance`() {
        let a = E.left(.unexpected(expected: "x"))
        let b = E.left(.unexpected(expected: "x"))
        let c = E.right(.expectedEnd(remaining: 1))

        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - Edge Case Tests — Never Elimination

@Suite("Parser.Error.Either Never Elimination")
struct ParserErrorEitherNeverTests {
    @Suite struct Unit {}
}

extension ParserErrorEitherNeverTests.Unit {
    @Test
    func `left Never extracts right unconditionally`() {
        let error: Parser.Error.Either<Never, Parser.Match.Error> =
            .right(.expectedEnd(remaining: 3))

        let extracted = error.error

        #expect(extracted == .expectedEnd(remaining: 3))
    }

    @Test
    func `right Never extracts left unconditionally`() {
        let error: Parser.Error.Either<Parser.Match.Error, Never> =
            .left(.predicateFailed(description: "test"))

        let extracted = error.error

        #expect(extracted == .predicateFailed(description: "test"))
    }
}
