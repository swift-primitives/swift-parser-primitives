import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Builder — var body declarative composition")
struct ParserBuilderTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Test Parsers (Leaf)

/// Parses one ASCII digit, returns its integer value.
struct Digit<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

// Hoisted out of the generic `Digit<Input>` so the typed-throws error type is
// NON-generic: the error never used `Input`, and the accidental generality
// `DigitError` triggered a FunctionSignatureOpts crash under -O
// (catalog § A13). De-genericizing is behaviour-preserving.
enum DigitError: Swift.Error, Sendable, Equatable {
    case expectedDigit
}

extension Digit: Parser.`Protocol` {
    typealias Output = UInt8
    typealias Failure = DigitError

    func parse(_ input: inout Input) throws(Failure) -> UInt8 {
        guard input.startIndex < input.endIndex else { throw .expectedDigit }
        let byte = input[input.startIndex]
        guard byte >= 0x30, byte <= 0x39 else { throw .expectedDigit }
        input = input[input.index(after: input.startIndex)...]
        return byte - 0x30
    }
}

/// Parses one specific ASCII byte, returns Void.
struct Expect<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
    let byte: UInt8
    init(_ byte: UInt8) { self.byte = byte }
}

enum ExpectError: Swift.Error, Sendable, Equatable {
    case expected(UInt8)
}

extension Expect: Parser.`Protocol` {
    typealias Output = Void
    typealias Failure = ExpectError

    func parse(_ input: inout Input) throws(Failure) {
        guard input.startIndex < input.endIndex,
            input[input.startIndex] == byte
        else { throw .expected(byte) }
        input = input[input.index(after: input.startIndex)...]
    }
}

/// Skips ASCII spaces, returns Void, never fails.
struct Whitespace<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

extension Whitespace: Parser.`Protocol` {
    typealias Output = Void
    typealias Failure = Never

    func parse(_ input: inout Input) {
        while input.startIndex < input.endIndex,
            input[input.startIndex] == 0x20
        {
            input = input[input.index(after: input.startIndex)...]
        }
    }
}

/// Consumes all remaining input, returns byte count. Never fails.
struct CountRest<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

extension CountRest: Parser.`Protocol` {
    typealias Output = Int
    typealias Failure = Never

    func parse(_ input: inout Input) -> Int {
        var count = 0
        while input.startIndex < input.endIndex {
            input = input[input.index(after: input.startIndex)...]
            count += 1
        }
        return count
    }
}

// MARK: - Declarative Parsers (var body)

// ────────────────────────────────────────────────────────────
// Pattern 1: Single parser pass-through
//
//     var body: some Parser.Protocol<Input, UInt8, Error> {
//         Digit<Input>()
//     }
//
// The builder sees one expression, passes it through unchanged.
// Default parse(_:) delegates to body — no explicit func parse.
// ────────────────────────────────────────────────────────────

struct SingleDigit<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

extension SingleDigit: Parser.`Protocol` {
    typealias Output = UInt8
    typealias Failure = DigitError

    var body: some Parser.`Protocol`<Input, UInt8, DigitError> {
        Digit<Input>()
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 2: Two-parser composition with error mapping
//
//     Parser.Take.Sequence {
//         Digit<Input>()    // → UInt8
//         Digit<Input>()    // → UInt8
//     }                     // → (UInt8, UInt8) / Either<Digit.Error, Digit.Error>
//     .error.map { ... }    // → (UInt8, UInt8) / DomainError
//
// .error.map converts Either<Left, Right> → concrete domain Error.
// ────────────────────────────────────────────────────────────

struct TwoDigits<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

enum TwoDigitsError: Swift.Error, Sendable, Equatable {
    case first
    case second
}

extension TwoDigits: Parser.`Protocol` {
    typealias Output = (UInt8, UInt8)
    typealias Failure = TwoDigitsError

    var body: some Parser.`Protocol`<Input, (UInt8, UInt8), TwoDigitsError> {
        Parser.Take.Sequence {
            Digit<Input>()
            Digit<Input>()
        }
        .error.map { either -> TwoDigitsError in
            switch either {
            case .left: .first
            case .right: .second
            }
        }
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 3: Void-skipping — left side
//
//     Parser.Take.Sequence {
//         Whitespace<Input>()   // → Void (skipped automatically)
//         Digit<Input>()        // → UInt8
//     }                         // → UInt8 / Either<Never, Digit.Error>
//     .error.map { $0.value }   // → UInt8 / Digit.Error
//
// When a parser produces Void, the builder uses Skip.First.
// Either<Never, X>.value eliminates the Never branch (unconditional extraction).
// ────────────────────────────────────────────────────────────

struct SkipThenDigit<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

extension SkipThenDigit: Parser.`Protocol` {
    typealias Output = UInt8
    typealias Failure = DigitError

    var body: some Parser.`Protocol`<Input, UInt8, DigitError> {
        Parser.Take.Sequence {
            Whitespace<Input>()
            Digit<Input>()
        }
        .error.map { $0.value }
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 4: Void-skipping — right side
//
//     Parser.Take.Sequence {
//         Digit<Input>()        // → UInt8
//         Whitespace<Input>()   // → Void (skipped automatically)
//     }                         // → UInt8 / Either<Digit.Error, Never>
//     .error.map { $0.value }   // → UInt8 / Digit.Error
//
// When the right parser produces Void, the builder uses Skip.Second.
// Either<X, Never>.value eliminates the Never branch.
// ────────────────────────────────────────────────────────────

struct DigitThenSkip<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

extension DigitThenSkip: Parser.`Protocol` {
    typealias Output = UInt8
    typealias Failure = DigitError

    var body: some Parser.`Protocol`<Input, UInt8, DigitError> {
        Parser.Take.Sequence {
            Digit<Input>()
            Whitespace<Input>()
        }
        .error.map { $0.value }
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 5: Five-parser composition — tuple flattening + .map + .error.map
//
//     Parser.Take.Sequence {
//         Digit<Input>()            // UInt8
//         Expect<Input>(0x2E)       // Void (. delimiter)
//         Digit<Input>()            // UInt8
//         Expect<Input>(0x2E)       // Void (. delimiter)
//         Digit<Input>()            // UInt8
//     }                             // → (UInt8, UInt8, UInt8)
//     .map { Version($0, $1, $2) }  // → Version
//     .error.map { ... }            // → Version.Error
//
// Voids are skipped. Remaining values flatten via parameter packs.
// .map transforms the tuple into a domain type.
// .error.map walks the left-nested Either tree to produce domain errors.
//
// Version is non-generic (domain type), Version.Parser<Input> is generic
// (same pattern as HTTP.MediaType / HTTP.MediaType.Parser<Input>).
// ────────────────────────────────────────────────────────────

struct Version: Sendable, Equatable {
    let major: UInt8
    let minor: UInt8
    let patch: UInt8

    init(_ major: UInt8, _ minor: UInt8, _ patch: UInt8) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

extension Version {
    enum Error: Swift.Error, Sendable, Equatable {
        case expectedMajor
        case expectedDot
        case expectedMinor
        case expectedPatch
    }
}

extension Version {
    struct Parser<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
    }
}

extension Version.Parser: Parser_Primitives.Parser.`Protocol` {
    typealias Output = Version
    typealias Failure = Version.Error

    var body: some Parser_Primitives.Parser.`Protocol`<Input, Version, Version.Error> {
        Parser_Primitives.Parser.Take.Sequence {
            Digit<Input>()
            Expect<Input>(0x2E)
            Digit<Input>()
            Expect<Input>(0x2E)
            Digit<Input>()
        }
        .map { major, minor, patch in
            Version(major, minor, patch)
        }
        .error.map { either -> Version.Error in
            // Left-nested Either tree from 5 parsers (after Void-skipping):
            //   Either<Either<Either<Either<Digit.E, Expect.E>, Digit.E>, Expect.E>, Digit.E>
            // Peel from the right — each .right is the Nth parser's error.
            switch either {
            case .right:
                return .expectedPatch  // 5th: Digit

            case .left(let e4):
                switch e4 {
                case .right:
                    return .expectedDot  // 4th: Expect('.')

                case .left(let e3):
                    switch e3 {
                    case .right:
                        return .expectedMinor  // 3rd: Digit

                    case .left(let e2):
                        switch e2 {
                        case .right:
                            return .expectedDot  // 2nd: Expect('.')

                        case .left:
                            return .expectedMajor  // 1st: Digit
                        }
                    }
                }
            }
        }
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 6: Infallible declarative parser (Failure == Never)
//
//     Parser.Take.Sequence {
//         Whitespace<Input>()   // Void / Never
//         CountRest<Input>()    // Int  / Never
//     }                         // → Int / Either<Never, Never>
//     .error.map { either -> Never in
//         switch either {
//         case .left(let n):  switch n {}
//         case .right(let n): switch n {}
//         }
//     }                         // → Int / Never
//
// Both sub-parsers have Failure = Never.
// The builder produces Either<Never, Never> — uninhabited.
// .error.map proves this to the type system via exhaustive Never switches.
// ────────────────────────────────────────────────────────────

struct SkipWhitespaceCountRest<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

extension SkipWhitespaceCountRest: Parser.`Protocol` {
    typealias Output = Int
    typealias Failure = Never

    var body: some Parser.`Protocol`<Input, Int, Never> {
        Parser.Take.Sequence {
            Whitespace<Input>()
            CountRest<Input>()
        }
        .error.map { either -> Never in
            switch either {
            case .left(let never): switch never {}
            case .right(let never): switch never {}
            }
        }
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 7: Nested declarative parsers
//
//     Parser.Take.Sequence {
//         Whitespace<Input>()         // Void / Never (skipped)
//         Version.Parser<Input>()     // Version / Version.Error
//     }                               // → Version / Either<Never, Version.Error>
//     .error.map { $0.value }         // → Version / Version.Error
//
// A declarative parser can use another declarative parser in its body.
// The inner parser's Failure (Version.Error) propagates outward.
// ────────────────────────────────────────────────────────────

struct WhitespaceVersion<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

extension WhitespaceVersion: Parser.`Protocol` {
    typealias Output = Version
    typealias Failure = Version.Error

    var body: some Parser.`Protocol`<Input, Version, Version.Error> {
        Parser.Take.Sequence {
            Whitespace<Input>()
            Version.Parser<Input>()
        }
        .error.map { $0.value }
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 8: Output mapping — .map transforms the parsed tuple
//
//     Parser.Take.Sequence {
//         Digit<Input>()
//         Digit<Input>()
//     }                                                   // → (UInt8, UInt8)
//     .map { tens, ones in Int(tens) * 10 + Int(ones) }   // → Int
//     .error.map { _ in .expectedDigit }                   // → Error
//
// .map converts (UInt8, UInt8) → Int.
// .error.map flattens both Either branches to one case.
// ────────────────────────────────────────────────────────────

struct TwoDigitNumber<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
}

enum TwoDigitNumberError: Swift.Error, Sendable, Equatable {
    case expectedDigit
}

extension TwoDigitNumber: Parser.`Protocol` {
    typealias Output = Int
    typealias Failure = TwoDigitNumberError

    var body: some Parser.`Protocol`<Input, Int, TwoDigitNumberError> {
        Parser.Take.Sequence {
            Digit<Input>()
            Digit<Input>()
        }
        .map { tens, ones in Int(tens) * 10 + Int(ones) }
        .error.map { _ -> TwoDigitNumberError in .expectedDigit }
    }
}

// MARK: - Unit Tests

extension ParserBuilderTests.Unit {
    @Test
    func `leaf parser has Body == Never`() throws(any Swift.Error) {
        let parser = Digit<Parser.Test.Input>()
        var input = Parser.Test.Input([0x35])

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(type(of: parser).Body.self == Never.self)
    }

    @Test
    func `single parser pass-through via var body`() throws(any Swift.Error) {
        let parser = SingleDigit<Parser.Test.Input>()
        var input = Parser.Test.Input([0x37])

        let result = try parser.parse(&input)

        #expect(result == 7)
    }

    @Test
    func `two values compose into tuple`() throws(any Swift.Error) {
        let parser = TwoDigits<Parser.Test.Input>()
        var input = Parser.Test.Input([0x31, 0x32])

        let (a, b) = try parser.parse(&input)

        #expect(a == 1)
        #expect(b == 2)
    }

    @Test
    func `void output from first parser is skipped`() throws(any Swift.Error) {
        let parser = SkipThenDigit<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "  5")

        let result = try parser.parse(&input)

        #expect(result == 5)
    }

    @Test
    func `void output from second parser is skipped`() throws(any Swift.Error) {
        let parser = DigitThenSkip<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "5  ")

        let result = try parser.parse(&input)

        #expect(result == 5)
    }

    @Test
    func `five parsers flatten with void-skipping and tuple flattening`() throws(any Swift.Error) {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1.2.3")

        let version = try parser.parse(&input)

        #expect(version == Version(1, 2, 3))
    }

    @Test
    func `output mapping transforms parsed tuple`() throws(any Swift.Error) {
        let parser = TwoDigitNumber<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "42")

        let result = try parser.parse(&input)

        #expect(result == 42)
    }

    @Test
    func `error mapping converts Either tree to domain error`() {
        let parser = TwoDigits<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1x")

        #expect(throws: TwoDigitsError.second) {
            try parser.parse(&input)
        }
    }

    @Test
    func `infallible body produces Never failure`() {
        let parser = SkipWhitespaceCountRest<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "   hello")

        let count = parser.parse(&input)

        #expect(count == 5)
    }

    @Test
    func `nested declarative parsers compose`() throws(any Swift.Error) {
        let parser = WhitespaceVersion<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "  1.0.9")

        let version = try parser.parse(&input)

        #expect(version == Version(1, 0, 9))
    }

    @Test
    func `default parse delegates to body`() throws(any Swift.Error) {
        let parser = Version.Parser<Parser.Test.Input>()
        var input1 = Parser.Test.Input(utf8: "3.1.4")
        var input2 = Parser.Test.Input(utf8: "3.1.4")

        let fromBody = try parser.body.parse(&input1)
        let fromParse = try parser.parse(&input2)

        #expect(fromBody == fromParse)
    }

    @Test
    func `input is consumed correctly through var body`() throws(any Swift.Error) {
        let parser = SkipThenDigit<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: " 7rest")

        _ = try parser.parse(&input)

        #expect(input.first == UInt8(ascii: "r"))
    }

    @Test
    func `version parser consumes exactly five bytes`() throws(any Swift.Error) {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1.2.3 extra")

        _ = try parser.parse(&input)

        #expect(input.first == UInt8(ascii: " "))
    }

    @Test
    func `version parser boundary values`() throws(any Swift.Error) {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "0.0.0")

        let version = try parser.parse(&input)

        #expect(version == Version(0, 0, 0))
    }

    @Test
    func `version parser max single digits`() throws(any Swift.Error) {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "9.9.9")

        let version = try parser.parse(&input)

        #expect(version == Version(9, 9, 9))
    }
}

// MARK: - Edge Case Tests

extension ParserBuilderTests.EdgeCase {
    @Test
    func `single pass-through body propagates failure`() {
        let parser = SingleDigit<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "x")

        #expect(throws: DigitError.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `single pass-through body fails on empty input`() {
        let parser = SingleDigit<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        #expect(throws: DigitError.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `two digits first failure maps to domain error`() {
        let parser = TwoDigits<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "x")

        #expect(throws: TwoDigitsError.first) {
            try parser.parse(&input)
        }
    }

    @Test
    func `two digits second failure maps to domain error`() {
        let parser = TwoDigits<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1x")

        #expect(throws: TwoDigitsError.second) {
            try parser.parse(&input)
        }
    }

    @Test
    func `two digits empty input maps to first`() {
        let parser = TwoDigits<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        #expect(throws: TwoDigitsError.first) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedMajor on empty`() {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        #expect(throws: Version.Error.expectedMajor) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedDot after major`() {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1x")

        #expect(throws: Version.Error.expectedDot) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedMinor after first dot`() {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1.x")

        #expect(throws: Version.Error.expectedMinor) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedPatch after second dot`() {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1.2.x")

        #expect(throws: Version.Error.expectedPatch) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedDot on truncated input`() {
        let parser = Version.Parser<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "1")

        #expect(throws: Version.Error.expectedDot) {
            try parser.parse(&input)
        }
    }

    @Test
    func `nested declarative parser propagates inner errors`() {
        let parser = WhitespaceVersion<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "  1.2.x")

        #expect(throws: Version.Error.expectedPatch) {
            try parser.parse(&input)
        }
    }

    @Test
    func `nested declarative parser fails on empty after whitespace`() {
        let parser = WhitespaceVersion<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "   ")

        #expect(throws: Version.Error.expectedMajor) {
            try parser.parse(&input)
        }
    }

    @Test
    func `infallible parser returns zero on empty input`() {
        let parser = SkipWhitespaceCountRest<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        let count = parser.parse(&input)

        #expect(count == 0)
    }

    @Test
    func `infallible parser counts only non-whitespace`() {
        let parser = SkipWhitespaceCountRest<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "     ")

        let count = parser.parse(&input)

        #expect(count == 0)
    }

    @Test
    func `void-skip left with empty input delegates error`() {
        let parser = SkipThenDigit<Parser.Test.Input>()
        var input = Parser.Test.Input([])

        #expect(throws: DigitError.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `void-skip left with only whitespace delegates error`() {
        let parser = SkipThenDigit<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "   ")

        #expect(throws: DigitError.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `void-skip right preserves value with no trailing whitespace`() throws(any Swift.Error) {
        let parser = DigitThenSkip<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "9")

        let result = try parser.parse(&input)

        #expect(result == 9)
    }

    @Test
    func `output mapping fails on non-digit`() {
        let parser = TwoDigitNumber<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "x")

        #expect(throws: TwoDigitNumberError.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `output mapping fails on single digit`() {
        let parser = TwoDigitNumber<Parser.Test.Input>()
        var input = Parser.Test.Input(utf8: "4x")

        #expect(throws: TwoDigitNumberError.expectedDigit) {
            try parser.parse(&input)
        }
    }
}
