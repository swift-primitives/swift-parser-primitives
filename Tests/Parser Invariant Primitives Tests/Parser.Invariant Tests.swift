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
        let parser = Parser.Always<ByteInput, Int>(99)
        var input = ByteInput([0x01, 0x02, 0x03])
        let checkpoint = input.checkpoint

        _ = parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `Fail does not advance input`() {
        let parser = Parser.Fail<ByteInput, Int, Parser.Match.Error>(
            .predicateFailed(description: "test")
        )
        var input = ByteInput([0x01, 0x02, 0x03])
        let checkpoint = input.checkpoint

        _ = try? parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `Peek does not advance input on success`() throws {
        let parser = Parser.First.Element<ByteInput>().peek()
        var input = ByteInput([0x41, 0x42])
        let checkpoint = input.checkpoint

        _ = try parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `Not does not advance input on success`() throws {
        let parser = Parser.Byte<ByteInput>(0xFF).not()
        var input = ByteInput([0x01, 0x02])
        let checkpoint = input.checkpoint

        try parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    @Test
    func `End does not advance input`() throws {
        let parser = Parser.End<ByteInput>()
        var input = ByteInput([])
        let checkpoint = input.checkpoint

        try parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }

    // MARK: - Input Position: Consuming Parsers

    @Test
    func `Byte advances exactly one position`() throws {
        let parser = Parser.Byte<ByteInput>(0x41)
        var input = ByteInput([0x41, 0x42, 0x43])

        try parser.parse(&input)

        #expect(input.first == 0x42)
    }

    @Test
    func `First.Element advances exactly one position`() throws {
        let parser = Parser.First.Element<ByteInput>()
        var input = ByteInput([0x0A, 0x0B, 0x0C])

        _ = try parser.parse(&input)

        #expect(input.first == 0x0B)
    }

    @Test
    func `Literal advances by literal length`() throws {
        let parser = Parser.Literal<ByteInput>([0x01, 0x02, 0x03])
        var input = ByteInput([0x01, 0x02, 0x03, 0x04, 0x05])

        try parser.parse(&input)

        #expect(input.first == 0x04)
    }

    @Test
    func `Consume.Exactly advances by count`() throws {
        let parser = Parser.Consume.Exactly<ByteInput>(4)
        var input = ByteInput([0x0A, 0x0B, 0x0C, 0x0D, 0x0E])

        _ = try parser.parse(&input)

        #expect(input.first == 0x0E)
    }

    @Test
    func `Prefix.While advances by matched prefix length`() throws {
        let parser = Parser.Prefix.While<ByteInput> { $0 < 0x05 }
        var input = ByteInput([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])

        let result = try parser.parse(&input)

        #expect(result.count == 4)
        #expect(input.first == 0x05)
    }

    @Test
    func `Rest advances to end`() {
        let parser = Parser.Rest<ByteInput>()
        var input = ByteInput([0x01, 0x02, 0x03])

        _ = parser.parse(&input)

        #expect(input.isEmpty)
    }

    // MARK: - Input Position: Backtracking

    @Test
    func `OneOf restores position on failed first branch`() throws {
        let parser = Parser.OneOf.Two(
            Parser.Byte<ByteInput>(0xFF),
            Parser.Byte<ByteInput>(0x42)
        )
        var input = ByteInput([0x42, 0x43])

        try parser.parse(&input)

        #expect(input.first == 0x43)
    }

    @Test
    func `Optional restores position on failure`() {
        let parser = Parser.Optionally<Parser.Byte<ByteInput>> {
            Parser.Byte<ByteInput>(0xFF)
        }
        var input = ByteInput([0x01, 0x02])
        let checkpoint = input.checkpoint

        _ = parser.parse(&input)

        #expect(input.checkpoint == checkpoint)
    }
}

// MARK: - Parser Algebra Laws

extension ParserInvariantTests.Algebra {
    @Test
    func `map identity law`() throws {
        let base = Parser.First.Element<ByteInput>()
        let mapped = base.map { $0 }
        var input1 = ByteInput([0x42])
        var input2 = ByteInput([0x42])

        let result1 = try base.parse(&input1)
        let result2 = try mapped.parse(&input2)

        #expect(result1 == result2)
        #expect(input1.isEmpty == input2.isEmpty)
    }

    @Test
    func `map composition law`() throws {
        let f: @Sendable (UInt8) -> Int = { Int($0) }
        let g: @Sendable (Int) -> String = { "\($0)" }

        let chained = Parser.First.Element<ByteInput>().map(f).map(g)
        let composed = Parser.First.Element<ByteInput>().map { g(f($0)) }

        var input1 = ByteInput([0x0A])
        var input2 = ByteInput([0x0A])

        let result1 = try chained.parse(&input1)
        let result2 = try composed.parse(&input2)

        #expect(result1 == result2)
        #expect(input1.isEmpty == input2.isEmpty)
    }

    @Test
    func `flatMap left identity`() throws {
        let value: UInt8 = 0x05
        let f: @Sendable (UInt8) -> Parser.Consume.Exactly<ByteInput> = { count in
            Parser.Consume.Exactly(Int(count))
        }

        let lhs = Parser.Always<ByteInput, UInt8>(value).flatMap(f)
        let rhs = f(value)

        var input1 = ByteInput([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])
        var input2 = ByteInput([0x01, 0x02, 0x03, 0x04, 0x05, 0x06])

        let result1 = try lhs.parse(&input1)
        let result2 = try rhs.parse(&input2)

        #expect(result1.count == result2.count)
        #expect(input1.first == input2.first)
    }

    @Test
    func `flatMap right identity`() throws {
        let base = Parser.First.Element<ByteInput>()
        let lifted = base.flatMap { Parser.Always<ByteInput, UInt8>($0) }

        var input1 = ByteInput([0x42, 0x43])
        var input2 = ByteInput([0x42, 0x43])

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
        let parser = Parser.First.Element<ByteInput>()
            .flatMap { _ in Parser.Always<ByteInput, Int>(0) }
        var input = ByteInput([])

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
        let parser = Parser.Always<ByteInput, UInt8>(10)
            .flatMap { count -> Parser.Consume.Exactly<ByteInput> in
                Parser.Consume.Exactly(Int(count))
            }
        var input = ByteInput([0x01, 0x02])

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
            Parser.Byte<ByteInput>(0x41),
            Parser.Byte<ByteInput>(0x42)
        )
        var input = ByteInput([0x43])

        #expect(throws: (any Swift.Error).self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `Filter wraps predicate failure in right`() {
        let parser = Parser.First.Element<ByteInput>()
            .filter { $0 == 0x00 }
        var input = ByteInput([0xFF])

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
            Parser.Byte<ByteInput>(0xFF).map { "first" },
            Parser.First.Element<ByteInput>().map { _ in "second" }
        )
        var input = ByteInput([0x42])

        let result = try parser.parse(&input)

        #expect(result == "second")
        #expect(input.isEmpty)
    }

    @Test
    func `Peek does not consume on success`() throws {
        let parser = Parser.First.Element<ByteInput>().peek()
        var input = ByteInput([0x41, 0x42])
        let before = input.checkpoint

        _ = try parser.parse(&input)

        #expect(input.checkpoint == before)
    }

    @Test
    func `Not does not consume on success when inner fails`() throws {
        let parser = Parser.Byte<ByteInput>(0xFF).not()
        var input = ByteInput([0x01])
        let before = input.checkpoint

        try parser.parse(&input)

        #expect(input.checkpoint == before)
    }

    @Test
    func `Optional restores on inner failure`() {
        let parser = Parser.Optionally<Parser.Byte<ByteInput>> {
            Parser.Byte<ByteInput>(0xFF)
        }
        var input = ByteInput([0x01, 0x02, 0x03])
        let before = input.checkpoint

        let result: Parser.Byte<ByteInput>.Output? = parser.parse(&input)

        #expect(result == nil)
        #expect(input.checkpoint == before)
    }
}

// MARK: - Boundary Conditions

extension ParserInvariantTests.Boundary {
    @Test
    func `empty input - First.Element fails`() {
        let parser = Parser.First.Element<ByteInput>()
        var input = ByteInput([])

        #expect(throws: Parser.EndOfInput.Error.self) {
            try parser.parse(&input)
        }
    }

    @Test
    func `empty input - Rest returns empty`() {
        let parser = Parser.Rest<ByteInput>()
        var input = ByteInput([])

        let result = parser.parse(&input)

        #expect(result.isEmpty)
    }

    @Test
    func `empty input - End succeeds`() throws {
        let parser = Parser.End<ByteInput>()
        var input = ByteInput([])

        try parser.parse(&input)
    }

    @Test
    func `single element - First.Element consumes all`() throws {
        let parser = Parser.First.Element<ByteInput>()
        var input = ByteInput([0xFF])

        _ = try parser.parse(&input)

        #expect(input.isEmpty)
    }

    @Test
    func `input exhausted exactly - Literal matches exact length`() throws {
        let parser = Parser.Literal<ByteInput>([0x01, 0x02, 0x03])
        var input = ByteInput([0x01, 0x02, 0x03])

        try parser.parse(&input)

        #expect(input.isEmpty)
    }

    @Test
    func `many with large input`() throws {
        let bytes = [UInt8](repeating: 0x41, count: 1000) + [0x42]
        let parser = Parser.Prefix.While<ByteInput> { $0 == 0x41 }
        var input = ByteInput(bytes)

        let result = try parser.parse(&input)

        #expect(result.count == 1000)
        #expect(input.first == 0x42)
    }
}
