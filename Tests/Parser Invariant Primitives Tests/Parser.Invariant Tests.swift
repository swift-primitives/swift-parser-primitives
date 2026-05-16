import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Invariant")
struct ParserInvariantTests {
    @Suite struct InputPosition {}
    @Suite struct Algebra {}
    @Suite struct ErrorPropagation {}
    @Suite struct CheckpointRestore {}
    @Suite struct Boundary {}
}

// MARK: - Input Position: Non-Consuming Parsers

extension ParserInvariantTests.InputPosition {
    @Test
    func `Always does not advance input`() {
        let parser = Parser.Always<Parser.Test.Input, Int>(99)
        var input = Parser.Test.Input([0x01, 0x02, 0x03])
        let checkpoint = input.checkpoint

        _ = parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `Fail does not advance input`() {
        let parser = Parser.Fail<Parser.Test.Input, Int, Parser.Match.Error>(
            .predicateFailed(description: "test")
        )
        var input = Parser.Test.Input([0x01, 0x02, 0x03])
        let checkpoint = input.checkpoint

        _ = try? parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `Peek does not advance input on success`() throws {
        let parser = Parser.First.Element<Parser.Test.Input>().peek()
        var input = Parser.Test.Input([0x41, 0x42])
        let checkpoint = input.checkpoint

        _ = try parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `Not does not advance input on success`() throws {
        let parser = Parser.First.Where<Parser.Test.Input> { $0 == 0xFF }.not()
        var input = Parser.Test.Input([0x01, 0x02])
        let checkpoint = input.checkpoint

        try parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `End does not advance input`() throws {
        let parser = Parser.End<Parser.Test.Input>()
        var input = Parser.Test.Input([])
        let checkpoint = input.checkpoint

        try parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    // MARK: - Input Position: Consuming Parsers

    @Test
    func `First.Element advances exactly one position`() throws {
        let parser = Parser.First.Element<Parser.Test.Input>()
        var input = Parser.Test.Input([0x0A, 0x0B, 0x0C])

        _ = try parser.parse(&input)

        #expect(input.first == 0x0B)
    }

    @Test
    func `Consume.Exactly advances by count`() throws {
        let parser = Parser.Consume.Exactly<Parser.Test.Input>(4)
        var input = Parser.Test.Input([0x0A, 0x0B, 0x0C, 0x0D, 0x0E])

        _ = try parser.parse(&input)

        #expect(input.first == 0x0E)
    }

    @Test
    func `Prefix.While advances by matched prefix length`() throws {
        let parser = Parser.Prefix.While<Parser.Test.Input> { $0 < 0x05 }
        var input = Parser.Test.Input([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])

        let result = try parser.parse(&input)

        #expect(result.count == 4)
        #expect(input.first == 0x05)
    }

    @Test
    func `Rest advances to end`() {
        let parser = Parser.Rest<Parser.Test.Input>()
        var input = Parser.Test.Input([0x01, 0x02, 0x03])

        _ = parser.parse(&input)

        #expect(input.isEmpty)
    }

    // MARK: - Input Position: Backtracking

    @Test
    func `OneOf restores position on failed first branch`() throws {
        let parser = Parser.OneOf.Two(
            Parser.First.Where<Parser.Test.Input> { $0 == 0xFF },
            Parser.First.Where<Parser.Test.Input> { $0 == 0x42 }
        )
        var input = Parser.Test.Input([0x42, 0x43])

        try parser.parse(&input)

        #expect(input.first == 0x43)
    }

    @Test
    func `Optional restores position on failure`() {
        let parser = Parser.Optionally<Parser.First.Where<Parser.Test.Input>> {
            Parser.First.Where<Parser.Test.Input> { $0 == 0xFF }
        }
        var input = Parser.Test.Input([0x01, 0x02])
        let checkpoint = input.checkpoint

        _ = parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }
}

// MARK: - Parser Algebra Laws

extension ParserInvariantTests.Algebra {
    @Test
    func `map identity law`() throws {
        let base = Parser.First.Element<Parser.Test.Input>()
        let mapped = base.map { $0 }
        var input1 = Parser.Test.Input([0x42])
        var input2 = Parser.Test.Input([0x42])

        let result1 = try base.parse(&input1)
        let result2 = try mapped.parse(&input2)

        #expect(result1 == result2)
        #expect(input1.isEmpty == input2.isEmpty)
    }

    @Test
    func `map composition law`() throws {
        let f: @Sendable (UInt8) -> Int = { Int($0) }
        let g: @Sendable (Int) -> String = { "\($0)" }

        let chained = Parser.First.Element<Parser.Test.Input>().map(f).map(g)
        let composed = Parser.First.Element<Parser.Test.Input>().map { g(f($0)) }

        var input1 = Parser.Test.Input([0x0A])
        var input2 = Parser.Test.Input([0x0A])

        let result1 = try chained.parse(&input1)
        let result2 = try composed.parse(&input2)

        #expect(result1 == result2)
        #expect(input1.isEmpty == input2.isEmpty)
    }

    @Test
    func `flatMap left identity`() throws {
        let value: UInt8 = 0x05
        let f: @Sendable (UInt8) -> Parser.Consume.Exactly<Parser.Test.Input> = { count in
            Parser.Consume.Exactly(Int(count))
        }

        let lhs = Parser.Always<Parser.Test.Input, UInt8>(value).flatMap(f)
        let rhs = f(value)

        var input1 = Parser.Test.Input([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])
        var input2 = Parser.Test.Input([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])

        let result1 = try lhs.parse(&input1)
        let result2 = try rhs.parse(&input2)

        #expect(result1.count == result2.count)
        #expect(input1.first == input2.first)
    }

    @Test
    func `flatMap right identity`() throws {
        let base = Parser.First.Element<Parser.Test.Input>()
        let lifted = base.flatMap { Parser.Always<Parser.Test.Input, UInt8>($0) }

        var input1 = Parser.Test.Input([0x42, 0x43])
        var input2 = Parser.Test.Input([0x42, 0x43])

        let result1 = try base.parse(&input1)
        let result2 = try lifted.parse(&input2)

        #expect(result1 == result2)
        #expect(input1.first == input2.first)
    }
}

// MARK: - Error Propagation

extension ParserInvariantTests.ErrorPropagation {
    @Test
    func `FlatMap tags upstream error as left`() {
        let parser = Parser.First.Element<Parser.Test.Input>()
            .flatMap { _ in Parser.Always<Parser.Test.Input, Int>(0) }
        var input = Parser.Test.Input([])

        #expect {
            try parser.parse(&input)
        } throws: { error in
            guard
                let either = error
                    as? Either<
                        Parser.EndOfInput.Error,
                        Never
                    >
            else { return false }
            return either.left != nil
        }
    }

    @Test
    func `FlatMap tags downstream error as right`() {
        let parser = Parser.Always<Parser.Test.Input, UInt8>(10)
            .flatMap { count -> Parser.Consume.Exactly<Parser.Test.Input> in
                Parser.Consume.Exactly(Int(count))
            }
        var input = Parser.Test.Input([0x01, 0x02])

        #expect {
            try parser.parse(&input)
        } throws: { error in
            guard
                let either = error
                    as? Either<
                        Never,
                        Parser.Constraint.Error
                    >
            else { return false }
            return either.right != nil
        }
    }

    @Test
    func `OneOf exposes error when all branches fail`() {
        let parser = Parser.OneOf.Two(
            Parser.First.Where<Parser.Test.Input> { $0 == 0x41 },
            Parser.First.Where<Parser.Test.Input> { $0 == 0x42 }
        )
        var input = Parser.Test.Input([0x43])

        #expect(throws: (any Swift.Error).self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `Filter wraps predicate failure in right`() {
        let parser = Parser.First.Element<Parser.Test.Input>()
            .filter { $0 == 0x00 }
        var input = Parser.Test.Input([0xFF])

        #expect {
            try parser.parse(&input)
        } throws: { error in
            guard
                let either = error
                    as? Either<
                        Parser.EndOfInput.Error,
                        Parser.Constraint.Error
                    >
            else { return false }
            return either.right != nil
        }
    }
}

// MARK: - Checkpoint/Restore

extension ParserInvariantTests.CheckpointRestore {
    @Test
    func `OneOf.Two restores position on first-branch failure`() throws {
        let parser = Parser.OneOf.Two(
            Parser.First.Where<Parser.Test.Input> { $0 == 0xFF }.map { _ in "first" },
            Parser.First.Element<Parser.Test.Input>().map { _ in "second" }
        )
        var input = Parser.Test.Input([0x42])

        let result = try parser.parse(&input)

        #expect(result == "second")
        #expect(input.isEmpty)
    }

    @Test
    func `Peek does not consume on success`() throws {
        let parser = Parser.First.Element<Parser.Test.Input>().peek()
        var input = Parser.Test.Input([0x41, 0x42])
        let before = input.checkpoint

        _ = try parser.parse(&input)

        #expect(input.checkpoint == before)
    }

    @Test
    func `Not does not consume on success when inner fails`() throws {
        let parser = Parser.First.Where<Parser.Test.Input> { $0 == 0xFF }.not()
        var input = Parser.Test.Input([0x01])
        let before = input.checkpoint

        try parser.parse(&input)

        #expect(input.checkpoint == before)
    }

    @Test
    func `Optional restores on inner failure`() {
        let parser = Parser.Optionally<Parser.First.Where<Parser.Test.Input>> {
            Parser.First.Where<Parser.Test.Input> { $0 == 0xFF }
        }
        var input = Parser.Test.Input([0x01, 0x02, 0x03])
        let before = input.checkpoint

        let result: Parser.First.Where<Parser.Test.Input>.Output? = parser.parse(&input)

        #expect(result == nil)
        #expect(input.checkpoint == before)
    }
}

// MARK: - Boundary Conditions

extension ParserInvariantTests.Boundary {
    @Test
    func `empty input - First.Element fails`() {
        let parser = Parser.First.Element<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        #expect(throws: Parser.EndOfInput.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `empty input - Rest returns empty`() {
        let parser = Parser.Rest<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        let result = parser.parse(&input)

        #expect(result.isEmpty)
    }

    @Test
    func `empty input - End succeeds`() throws {
        let parser = Parser.End<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        try parser.parse(&input)
    }

    @Test
    func `single element - First.Element consumes all`() throws {
        let parser = Parser.First.Element<Parser.Test.Input>()
        var input = Parser.Test.Input([0xFF])

        _ = try parser.parse(&input)

        #expect(input.isEmpty)
    }

    @Test
    func `many with large input`() throws {
        let bytes = [UInt8](repeating: 0x41, count: 1000) + [0x42]
        let parser = Parser.Prefix.While<Parser.Test.Input> { $0 == 0x41 }
        var input = Parser.Test.Input(bytes)

        let result = try parser.parse(&input)

        #expect(result.count == 1000)
        #expect(input.first == 0x42)
    }
}
