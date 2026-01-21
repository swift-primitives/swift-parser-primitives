import Testing
@testable import Parser_Machine
import ASCII_Primitives

extension Parsing.CollectionInput where Base == [UInt8] {
    func remainingBytes() -> [UInt8] {
        var copy = self
        var out: [UInt8] = []
        out.reserveCapacity(16)
        while copy.first != nil {
            out.append(copy.removeFirst())
        }
        return out
    }
}

@Suite("Parsing.Machine Tests")
struct MachineTests {
    @Test("Value make and take")
    func valueMakeAndTake() {
        let value = Parsing.Machine.Value.make(42)
        #expect(value.take(Int.self) == 42)
        #expect(value.take(String.self) == nil)
        value.release()
    }

    @Test("Value with string")
    func valueWithString() {
        let value = Parsing.Machine.Value.make("hello")
        #expect(value.take(String.self) == "hello")
        value.release()
    }
}

@Suite("Machine Parser Tests")
struct MachineParserTests {
    // Simple parser that consumes a single byte
    struct ByteParser: Parsing.Parser, Sendable {
        enum Error: Swift.Error, Sendable {
            case endOfInput
        }

        func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> UInt8 {
            guard let byte = input.first else {
                throw .endOfInput
            }
            _ = input.removeFirst()
            return byte
        }
    }

    // Parser that matches a specific byte
    struct MatchByte: Parsing.Parser, Sendable {
        let expected: UInt8

        enum Error: Swift.Error, Sendable {
            case mismatch(expected: UInt8, actual: UInt8?)
        }

        func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> UInt8 {
            guard let byte = input.first else {
                throw .mismatch(expected: expected, actual: nil)
            }
            guard byte == expected else {
                throw .mismatch(expected: expected, actual: byte)
            }
            _ = input.removeFirst()
            return byte
        }
    }

    typealias Input = Parsing.CollectionInput<[UInt8]>

    @Test("Pure expression")
    func pureExpression() throws {
        let parser: Parsing.Machine.Parser<Input, Int, ByteParser.Error> = Parsing.Machine.build { builder in
            Parsing.Machine.pure(42, in: &builder)
        }

        var input = Input([1, 2, 3])
        let result = try parser.parse(&input)
        #expect(result == 42)
        #expect(input.remainingBytes() == [1, 2, 3]) // Input unchanged
    }

    @Test("Leaf parser wrapping")
    func leafParserWrapping() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, ByteParser.Error> = Parsing.Machine.build { builder in
            Parsing.Machine.leaf(ByteParser(), in: &builder)
        }

        var input = Input([65, 66, 67])
        let result = try parser.parse(&input)
        #expect(result == 65)
        #expect(input.remainingBytes() == [66, 67])
    }

    @Test("Map combinator")
    func mapCombinator() throws {
        let parser: Parsing.Machine.Parser<Input, Int, ByteParser.Error> = Parsing.Machine.build { builder in
            let byte = Parsing.Machine.leaf(ByteParser(), in: &builder)
            return byte.map({ Int($0) * 2 }, in: &builder)
        }

        var input = Input([10])
        let result = try parser.parse(&input)
        #expect(result == 20)
    }

    @Test("Sequence combinator")
    func sequenceCombinator() throws {
        let parser: Parsing.Machine.Parser<Input, (UInt8, UInt8), ByteParser.Error> = Parsing.Machine.build { builder in
            let first = Parsing.Machine.leaf(ByteParser(), in: &builder)
            let second = Parsing.Machine.leaf(ByteParser(), in: &builder)
            return Parsing.Machine.sequence(first, second, combine: { ($0, $1) }, in: &builder)
        }

        var input = Input([1, 2, 3])
        let result = try parser.parse(&input)
        #expect(result.0 == 1)
        #expect(result.1 == 2)
        #expect(input.remainingBytes() == [3])
    }

    @Test("Many combinator - zero elements")
    func manyCombinatorZero() throws {
        let parser: Parsing.Machine.Parser<Input, [UInt8], MatchByte.Error> = Parsing.Machine.build { builder in
            let byte = Parsing.Machine.leaf(MatchByte(expected: 0xFF), in: &builder)
                .map({ $0 }, in: &builder)
            return Parsing.Machine.many(byte, in: &builder)
        }

        var input = Input([1, 2, 3])
        let result = try parser.parse(&input)
        #expect(result.isEmpty)
        #expect(input.remainingBytes() == [1, 2, 3]) // No consumption
    }

    @Test("Many combinator - multiple elements")
    func manyCombinatorMultiple() throws {
        let parser: Parsing.Machine.Parser<Input, [UInt8], MatchByte.Error> = Parsing.Machine.build { builder in
            let byte = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parsing.Machine.many(byte, in: &builder)
        }

        var input = Input([65, 65, 65, 66])
        let result = try parser.parse(&input)
        #expect(result == [65, 65, 65])
        #expect(input.remainingBytes() == [66])
    }

    @Test("Optional combinator - success")
    func optionalCombinatorSuccess() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8?, MatchByte.Error> = Parsing.Machine.build { builder in
            let byte = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parsing.Machine.optional(byte, in: &builder)
        }

        var input = Input([65, 66])
        let result = try parser.parse(&input)
        #expect(result == 65)
        #expect(input.remainingBytes() == [66])
    }

    @Test("Optional combinator - failure returns nil")
    func optionalCombinatorFailure() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8?, MatchByte.Error> = Parsing.Machine.build { builder in
            let byte = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parsing.Machine.optional(byte, in: &builder)
        }

        var input = Input([66, 67])
        let result = try parser.parse(&input)
        #expect(result == nil)
        #expect(input.remainingBytes() == [66, 67]) // Input restored
    }

    @Test("OneOf combinator - first succeeds")
    func oneOfCombinatorFirst() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            let a = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parsing.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parsing.Machine.oneOf([a, b], in: &builder)
        }

        var input = Input([65])
        let result = try parser.parse(&input)
        #expect(result == 65)
    }

    @Test("OneOf combinator - second succeeds")
    func oneOfCombinatorSecond() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            let a = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parsing.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parsing.Machine.oneOf([a, b], in: &builder)
        }

        var input = Input([66])
        let result = try parser.parse(&input)
        #expect(result == 66)
    }

    @Test("OneOf combinator - all fail throws")
    func oneOfCombinatorAllFail() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            let a = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parsing.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parsing.Machine.oneOf([a, b], in: &builder)
        }

        var input = Input([67])
        #expect(throws: MatchByte.Error.self) {
            _ = try parser.parse(&input)
        }
    }
}

@Suite("Machine Recursive Grammar Tests")
struct MachineRecursiveGrammarTests {
    // Parser that matches '(' and ')'
    struct OpenParen: Parsing.Parser, Sendable {
        enum Error: Swift.Error, Sendable { case expected }

        func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> Void {
            guard input.first == .ascii.leftParenthesis else { throw .expected }
            _ = input.removeFirst()
        }
    }

    struct CloseParen: Parsing.Parser, Sendable {
        enum Error: Swift.Error, Sendable { case expected }

        func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> Void {
            guard input.first == .ascii.rightParenthesis else { throw .expected }
            _ = input.removeFirst()
        }
    }

    enum TestError: Error, Sendable {
        case openParen
        case closeParen
    }

    typealias Input = Parsing.CollectionInput<[UInt8]>

    @Test("Recursive balanced parentheses - simple")
    func recursiveBalancedSimple() throws {
        // Grammar: S -> '(' S ')' | empty
        let parser: Parsing.Machine.Parser<Input, Int, TestError> = Parsing.Machine.recursive(maxDepth: 1000) { builder, selfRef in
            // base case: empty -> depth 0
            let empty = Parsing.Machine.pure(0, in: &builder)

            // recursive case: '(' S ')' -> depth + 1
            let open = Parsing.Machine.leaf(OpenParen(), mapError: { _ in TestError.openParen }, in: &builder)
            let close = Parsing.Machine.leaf(CloseParen(), mapError: { _ in TestError.closeParen }, in: &builder)
            let inner = selfRef.expression(in: &builder)

            let recursive = Parsing.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
            let withClose = Parsing.Machine.sequence(recursive, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)

            return Parsing.Machine.oneOf([withClose, empty], in: &builder)
        }

        var input = Input(Array("((()))".utf8))
        let depth = try parser.parse(&input)
        #expect(depth == 3)
        #expect(input.first == nil)
    }

    @Test("Recursive balanced parentheses - 100 levels deep")
    func recursiveBalanced100() throws {
        let parser: Parsing.Machine.Parser<Input, Int, TestError> = Parsing.Machine.recursive(maxDepth: 1000) { builder, selfRef in
            let empty = Parsing.Machine.pure(0, in: &builder)
            let open = Parsing.Machine.leaf(OpenParen(), mapError: { _ in TestError.openParen }, in: &builder)
            let close = Parsing.Machine.leaf(CloseParen(), mapError: { _ in TestError.closeParen }, in: &builder)
            let inner = selfRef.expression(in: &builder)

            let recursive = Parsing.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
            let withClose = Parsing.Machine.sequence(recursive, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)

            return Parsing.Machine.oneOf([withClose, empty], in: &builder)
        }

        // Create 100 nested parentheses
        var bytes: [UInt8] = []
        for _ in 0..<100 {
            bytes.append(.ascii.leftParenthesis)
        }
        for _ in 0..<100 {
            bytes.append(.ascii.rightParenthesis)
        }

        var input = Input(bytes)
        let depth = try parser.parse(&input)
        #expect(depth == 100)
        #expect(input.first == nil)
    }

    @Test("Deep nesting - 2000 levels without stack overflow")
    func deepNesting2000() throws {
        let parser: Parsing.Machine.Parser<Input, Int, TestError> = Parsing.Machine.recursive(maxDepth: 10000) { builder, selfRef in
            let empty = Parsing.Machine.pure(0, in: &builder)
            let open = Parsing.Machine.leaf(OpenParen(), mapError: { _ in TestError.openParen }, in: &builder)
            let close = Parsing.Machine.leaf(CloseParen(), mapError: { _ in TestError.closeParen }, in: &builder)
            let inner = selfRef.expression(in: &builder)

            let recursive = Parsing.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
            let withClose = Parsing.Machine.sequence(recursive, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)

            return Parsing.Machine.oneOf([withClose, empty], in: &builder)
        }

        // Create 2000 nested parentheses - this would overflow with recursive descent!
        var bytes: [UInt8] = []
        for _ in 0..<2000 {
            bytes.append(.ascii.leftParenthesis)
        }
        for _ in 0..<2000 {
            bytes.append(.ascii.rightParenthesis)
        }

        var input = Input(bytes)
        let depth = try parser.parse(&input)
        #expect(depth == 2000)
        #expect(input.first == nil)
    }

    @Test("Deep nesting - 5000 levels without stack overflow")
    func deepNesting5000() throws {
        let parser: Parsing.Machine.Parser<Input, Int, TestError> = Parsing.Machine.recursive(maxDepth: 10000) { builder, selfRef in
            let empty = Parsing.Machine.pure(0, in: &builder)
            let open = Parsing.Machine.leaf(OpenParen(), mapError: { _ in TestError.openParen }, in: &builder)
            let close = Parsing.Machine.leaf(CloseParen(), mapError: { _ in TestError.closeParen }, in: &builder)
            let inner = selfRef.expression(in: &builder)

            let recursive = Parsing.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
            let withClose = Parsing.Machine.sequence(recursive, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)

            return Parsing.Machine.oneOf([withClose, empty], in: &builder)
        }

        // Create 5000 nested parentheses
        var bytes: [UInt8] = []
        for _ in 0..<5000 {
            bytes.append(.ascii.leftParenthesis)
        }
        for _ in 0..<5000 {
            bytes.append(.ascii.rightParenthesis)
        }

        var input = Input(bytes)
        let depth = try parser.parse(&input)
        #expect(depth == 5000)
        #expect(input.first == nil)
    }

    // Complex type to mimic XML Element
    struct Element: Sendable, Equatable {
        var name: String
        var content: [Content]
    }

    enum Content: Sendable, Equatable {
        case element(Element)
        case text(String)
    }

    @Test("Deep nesting with complex types like XML - 1000 levels")
    func deepNestingComplexTypes100() throws {
        // Grammar: Element -> '<' Element* '>' | '<' '/' '>'
        // This mimics XML parsing with many combinator for content

        struct OpenBracket: Parsing.Parser, Sendable {
            enum Error: Swift.Error, Sendable { case expected }
            func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> Void {
                guard input.first == .ascii.lessThanSign else { throw .expected }
                _ = input.removeFirst()
            }
        }

        struct CloseBracket: Parsing.Parser, Sendable {
            enum Error: Swift.Error, Sendable { case expected }
            func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> Void {
                guard input.first == .ascii.greaterThanSign else { throw .expected }
                _ = input.removeFirst()
            }
        }

        struct SlashClose: Parsing.Parser, Sendable {
            enum Error: Swift.Error, Sendable { case expected }
            func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> Void {
                guard input.first == .ascii.slant else { throw .expected }
                _ = input.removeFirst()
                guard input.first == .ascii.greaterThanSign else { throw .expected }
                _ = input.removeFirst()
            }
        }

        let parser: Parsing.Machine.Parser<Input, Element, TestError> = Parsing.Machine.recursive(maxDepth: 2000) { builder, selfRef in
            let open = Parsing.Machine.leaf(OpenBracket(), mapError: { _ in TestError.openParen }, in: &builder)
            let close = Parsing.Machine.leaf(CloseBracket(), mapError: { _ in TestError.closeParen }, in: &builder)
            let slashClose = Parsing.Machine.leaf(SlashClose(), mapError: { _ in TestError.closeParen }, in: &builder)

            // Recursive element -> Content
            let elementContent = selfRef.expression(in: &builder)
                .map({ Content.element($0) }, in: &builder)

            // Content: many element contents
            let content = Parsing.Machine.many(elementContent, in: &builder)

            // Non-empty: '<' content '>'
            let openWithContent = Parsing.Machine.sequence(open, content, combine: { (_: Void, c: [Content]) in c }, in: &builder)
            let nonEmpty = Parsing.Machine.sequence(openWithContent, close, combine: { (contents: [Content], _: Void) in
                Element(name: "e", content: contents)
            }, in: &builder)

            // Empty: '<' '/>'
            let emptyElement = Parsing.Machine.sequence(open, slashClose, combine: { (_: Void, _: Void) in
                Element(name: "e", content: [])
            }, in: &builder)

            return Parsing.Machine.oneOf([nonEmpty, emptyElement], in: &builder)
        }

        // Create: <</>>
        // This means: element containing empty element
        // For 1000 levels: < < < ... </> > > >
        var bytes: [UInt8] = []
        for _ in 0..<1000 {
            bytes.append(.ascii.lessThanSign)
        }
        bytes.append(.ascii.slant)
        bytes.append(.ascii.greaterThanSign)
        for _ in 0..<999 {  // One less because innermost is empty
            bytes.append(.ascii.greaterThanSign)
        }

        var input = Input(bytes)
        let result = try parser.parse(&input)
        #expect(result.name == "e")
        // Check we consumed all input
        #expect(input.isEmpty)
    }

    @Test("Deep nesting with tryMap disambiguation like XML - 50 levels")
    func deepNestingWithTryMap50() throws {
        // This mimics XML's pattern of:
        // 1. Parse start tag
        // 2. Use tryMap to check if empty or non-empty
        // 3. If non-empty, parse content + end tag

        struct StartTagOutput: Sendable {
            var isEmpty: Bool
        }

        struct ParseOpen: Parsing.Parser, Sendable {
            enum Error: Swift.Error, Sendable { case expected }
            func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> StartTagOutput {
                guard input.first == .ascii.lessThanSign else { throw .expected }
                _ = input.removeFirst()
                // Check for />
                if input.first == .ascii.slant {
                    _ = input.removeFirst()
                    guard input.first == .ascii.greaterThanSign else { throw .expected }
                    _ = input.removeFirst()
                    return StartTagOutput(isEmpty: true)
                } else {
                    return StartTagOutput(isEmpty: false)
                }
            }
        }

        struct ParseClose: Parsing.Parser, Sendable {
            enum Error: Swift.Error, Sendable { case expected }
            func parse(_ input: inout Parsing.CollectionInput<[UInt8]>) throws(Error) -> Void {
                guard input.first == .ascii.greaterThanSign else { throw .expected }
                _ = input.removeFirst()
            }
        }

        let parser: Parsing.Machine.Parser<Input, Element, TestError> = Parsing.Machine.recursive(maxDepth: 100) { builder, selfRef in
            let startTag = Parsing.Machine.leaf(ParseOpen(), mapError: { _ in TestError.openParen }, in: &builder)
            let endTag = Parsing.Machine.leaf(ParseClose(), mapError: { _ in TestError.closeParen }, in: &builder)

            // Empty element: startTag.tryMap(require isEmpty)
            let emptyElement = startTag.tryMap({ (start: StartTagOutput) throws(TestError) -> Element in
                guard start.isEmpty else { throw TestError.openParen }
                return Element(name: "e", content: [])
            }, in: &builder)

            // Non-empty: startTag.tryMap(require !isEmpty) -> content -> endTag
            let openTag = startTag.tryMap({ (start: StartTagOutput) throws(TestError) -> StartTagOutput in
                guard !start.isEmpty else { throw TestError.closeParen }
                return start
            }, in: &builder)

            // Recursive element -> Content
            let elementContent = selfRef.expression(in: &builder)
                .map({ Content.element($0) }, in: &builder)

            // Content: many element contents
            let content = Parsing.Machine.many(elementContent, in: &builder)

            // sequence: openTag, content, endTag
            let withContent = Parsing.Machine.sequence(openTag, content, combine: { (_: StartTagOutput, c: [Content]) in c }, in: &builder)
            let nonEmptyElement = Parsing.Machine.sequence(withContent, endTag, combine: { (contents: [Content], _: Void) in
                Element(name: "e", content: contents)
            }, in: &builder)

            // oneOf: try empty first, then non-empty
            return Parsing.Machine.oneOf([emptyElement, nonEmptyElement], in: &builder)
        }

        // Create: < < < ... </> > > >
        // 50 nested elements
        var bytes: [UInt8] = []
        for _ in 0..<50 {
            bytes.append(.ascii.lessThanSign)
        }
        bytes.append(.ascii.slant)
        bytes.append(.ascii.greaterThanSign)
        for _ in 0..<49 {
            bytes.append(.ascii.greaterThanSign)
        }

        var input = Input(bytes)
        let result = try parser.parse(&input)
        #expect(result.name == "e")
        #expect(input.isEmpty)
    }
}

@Suite("Machine Memoization Tests")
struct MachineMemoizationTests {
    typealias Input = Parsing.CollectionInput<[UInt8]>

    struct MatchByte: Parsing.Parser, Sendable {
        let expected: UInt8

        enum Error: Swift.Error, Sendable {
            case mismatch(expected: UInt8, actual: UInt8?)
        }

        func parse(_ input: inout Input) throws(Error) -> UInt8 {
            guard let byte = input.first else {
                throw .mismatch(expected: expected, actual: nil)
            }
            guard byte == expected else {
                throw .mismatch(expected: expected, actual: byte)
            }
            _ = input.removeFirst()
            return byte
        }
    }

    @Test("Incremental context parses correctly")
    func incrementalContextParses() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65, 66, 67])
        let result = try ctx(&input)

        #expect(result == 65)
    }

    @Test("Memoization table populates during parsing")
    func memoizationTablePopulates() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental
        #expect(ctx.isEmpty)

        var input = Input([65])
        _ = try ctx(&input)

        #expect(ctx.count > 0)
    }

    @Test("Clear removes all cached entries")
    func clearRemovesCachedEntries() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65])
        _ = try ctx(&input)

        #expect(ctx.count > 0)
        ctx.clear()
        #expect(ctx.isEmpty)
    }

    @Test("Invalidate from position clears entries at or after")
    func invalidateFromPosition() throws {
        let parser: Parsing.Machine.Parser<Input, (UInt8, UInt8), MatchByte.Error> = Parsing.Machine.build { builder in
            let first = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
            let second = Parsing.Machine.leaf(MatchByte(expected: 66), in: &builder)
            return Parsing.Machine.sequence(first, second, combine: { ($0, $1) }, in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65, 66])
        _ = try ctx(&input)

        let countBefore = ctx.count
        #expect(countBefore > 0)

        // Invalidate from position 1 (should clear entries at position >= 1)
        ctx.invalidate(from: 1)

        // Some entries should remain (those at position 0)
        // Some entries should be cleared (those at position >= 1)
        #expect(ctx.count < countBefore)
    }

    @Test("Incremental re-parsing produces same result")
    func incrementalReparsingProducesSameResult() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental

        // First parse
        var input1 = Input([65])
        let result1 = try ctx(&input1)

        // Second parse with same input (should use cache)
        var input2 = Input([65])
        let result2 = try ctx(&input2)

        #expect(result1 == result2)
    }

    @Test("Invalidate with edit descriptor")
    func invalidateWithEditDescriptor() throws {
        let parser: Parsing.Machine.Parser<Input, (UInt8, UInt8, UInt8), MatchByte.Error> = Parsing.Machine.build { builder in
            let a = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
            let b = Parsing.Machine.leaf(MatchByte(expected: 66), in: &builder)
            let c = Parsing.Machine.leaf(MatchByte(expected: 67), in: &builder)
            let ab = Parsing.Machine.sequence(a, b, combine: { ($0, $1) }, in: &builder)
            return Parsing.Machine.sequence(ab, c, combine: { ($0.0, $0.1, $1) }, in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65, 66, 67])
        _ = try ctx(&input)

        let countBefore = ctx.count

        // Simulate edit: insert at position 1
        let edit = Parsing.Machine.Memoization.Edit<Int>(start: 1, oldEnd: 1, newEnd: 2)
        ctx.invalidate(edit)

        // Entries overlapping the edit should be cleared
        #expect(ctx.count < countBefore)
    }

    @Test("OneOf with memoization caches failed alternatives")
    func oneOfCachesFailedAlternatives() throws {
        let parser: Parsing.Machine.Parser<Input, UInt8, MatchByte.Error> = Parsing.Machine.build { builder in
            let a = Parsing.Machine.leaf(MatchByte(expected: 65), in: &builder)
            let b = Parsing.Machine.leaf(MatchByte(expected: 66), in: &builder)
            let c = Parsing.Machine.leaf(MatchByte(expected: 67), in: &builder)
            return Parsing.Machine.oneOf([a, b, c], in: &builder)
        }

        var ctx = parser.parse.incremental

        // Parse input that matches third alternative (first two fail)
        var input = Input([67])
        let result = try ctx(&input)

        #expect(result == 67)
        // Cache should contain entries for the failed alternatives too
        #expect(ctx.count >= 3) // At least root + failed alternatives + success
    }

    @Test("Recursive grammar with memoization")
    func recursiveGrammarWithMemoization() throws {
        struct OpenParen: Parsing.Parser, Sendable {
            enum Error: Swift.Error, Sendable { case expected }
            func parse(_ input: inout Input) throws(Error) -> Void {
                guard input.first == .ascii.leftParenthesis else { throw .expected }
                _ = input.removeFirst()
            }
        }

        struct CloseParen: Parsing.Parser, Sendable {
            enum Error: Swift.Error, Sendable { case expected }
            func parse(_ input: inout Input) throws(Error) -> Void {
                guard input.first == .ascii.rightParenthesis else { throw .expected }
                _ = input.removeFirst()
            }
        }

        enum TestError: Error, Sendable {
            case openParen
            case closeParen
        }

        let parser: Parsing.Machine.Parser<Input, Int, TestError> = Parsing.Machine.recursive(maxDepth: 100) { builder, selfRef in
            let empty = Parsing.Machine.pure(0, in: &builder)
            let open = Parsing.Machine.leaf(OpenParen(), mapError: { _ in TestError.openParen }, in: &builder)
            let close = Parsing.Machine.leaf(CloseParen(), mapError: { _ in TestError.closeParen }, in: &builder)
            let inner = selfRef.expression(in: &builder)

            let recursive = Parsing.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
            let withClose = Parsing.Machine.sequence(recursive, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)

            return Parsing.Machine.oneOf([withClose, empty], in: &builder)
        }

        var ctx = parser.parse.incremental

        var input = Input(Array("((()))".utf8))
        let depth = try ctx(&input)

        #expect(depth == 3)
        #expect(ctx.count > 0) // Memoization table should be populated
    }

    @Test("Edit convenience initializers")
    func editConvenienceInitializers() {
        // Insert
        let insert = Parsing.Machine.Memoization.Edit<Int>.insert(at: 10, length: 3)
        #expect(insert.start == 10)
        #expect(insert.oldEnd == 10)
        #expect(insert.newEnd == 13)

        // Delete
        let delete = Parsing.Machine.Memoization.Edit<Int>.delete(from: 10, to: 15)
        #expect(delete.start == 10)
        #expect(delete.oldEnd == 15)
        #expect(delete.newEnd == 10)
    }
}
