import Parser_Pair_Primitives
import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Pair as Parser")
struct PairAsParserTests {
    @Suite struct ParityWithTakeTwo {}
}

// MARK: - Parity with Parser.Take.Two

extension PairAsParserTests.ParityWithTakeTwo {
    @Test
    func `both succeed: outputs match and input state matches`() throws(any Swift.Error) {
        var inputA = Parser.Test.Input([0x0A, 0x0B, 0x0C])
        let takeResult = try Parser.Take.Two(
            Parser.First.Element<Parser.Test.Input>(),
            Parser.First.Element<Parser.Test.Input>()
        ).parse(&inputA)

        var inputB = Parser.Test.Input([0x0A, 0x0B, 0x0C])
        let pairResult = try Pair(
            Parser.First.Element<Parser.Test.Input>(),
            Parser.First.Element<Parser.Test.Input>()
        ).parse(&inputB)

        #expect(takeResult.0 == pairResult.0)
        #expect(takeResult.1 == pairResult.1)
        #expect(takeResult.0 == 0x0A)
        #expect(takeResult.1 == 0x0B)
        #expect(inputA.first == inputB.first)
        #expect(inputA.first == 0x0C)
    }

    @Test
    func `empty input: both throw on first parser`() {
        var inputA = Parser.Test.Input([])
        #expect(throws: (any Swift.Error).self) {
            try Parser.Take.Two(
                Parser.First.Element<Parser.Test.Input>(),
                Parser.First.Element<Parser.Test.Input>()
            ).parse(&inputA)
        }

        var inputB = Parser.Test.Input([])
        #expect(throws: (any Swift.Error).self) {
            try Pair(
                Parser.First.Element<Parser.Test.Input>(),
                Parser.First.Element<Parser.Test.Input>()
            ).parse(&inputB)
        }
    }

    @Test
    func `one-byte input: both throw on second parser`() {
        var inputA = Parser.Test.Input([0x01])
        #expect(throws: (any Swift.Error).self) {
            try Parser.Take.Two(
                Parser.First.Element<Parser.Test.Input>(),
                Parser.First.Element<Parser.Test.Input>()
            ).parse(&inputA)
        }

        var inputB = Parser.Test.Input([0x01])
        #expect(throws: (any Swift.Error).self) {
            try Pair(
                Parser.First.Element<Parser.Test.Input>(),
                Parser.First.Element<Parser.Test.Input>()
            ).parse(&inputB)
        }
    }
}
