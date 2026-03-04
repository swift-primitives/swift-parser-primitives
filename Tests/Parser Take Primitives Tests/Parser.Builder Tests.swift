import Testing
import Parser_Primitives_Test_Support

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
    init() {}
}

extension Digit {
    enum Error: Swift.Error, Sendable, Equatable {
        case expectedDigit
    }
}

extension Digit: Parser.`Protocol` {
    typealias ParseOutput = UInt8
    typealias Failure = Digit<Input>.Error

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

extension Expect {
    enum Error: Swift.Error, Sendable, Equatable {
        case expected(UInt8)
    }
}

extension Expect: Parser.`Protocol` {
    typealias ParseOutput = Void
    typealias Failure = Expect<Input>.Error

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
    init() {}
}

extension Whitespace: Parser.`Protocol` {
    typealias ParseOutput = Void
    typealias Failure = Never

    func parse(_ input: inout Input) {
        while input.startIndex < input.endIndex,
              input[input.startIndex] == 0x20 {
            input = input[input.index(after: input.startIndex)...]
        }
    }
}

/// Consumes all remaining input, returns byte count. Never fails.
struct CountRest<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
    init() {}
}

extension CountRest: Parser.`Protocol` {
    typealias ParseOutput = Int
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
    init() {}
}

extension SingleDigit: Parser.`Protocol` {
    typealias ParseOutput = UInt8
    typealias Failure = Digit<Input>.Error

    var body: some Parser.`Protocol`<Input, UInt8, Digit<Input>.Error> {
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
    init() {}
}

extension TwoDigits {
    enum Error: Swift.Error, Sendable, Equatable {
        case first
        case second
    }
}

extension TwoDigits: Parser.`Protocol` {
    typealias ParseOutput = (UInt8, UInt8)
    typealias Failure = TwoDigits<Input>.Error

    var body: some Parser.`Protocol`<Input, (UInt8, UInt8), TwoDigits<Input>.Error> {
        Parser.Take.Sequence {
            Digit<Input>()
            Digit<Input>()
        }
        .error.map { (either) -> TwoDigits<Input>.Error in
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
//     .error.map { $0.error }   // → UInt8 / Digit.Error
//
// When a parser produces Void, the builder uses Skip.First.
// Either<Never, X>.error eliminates the Never branch.
// ────────────────────────────────────────────────────────────

struct SkipThenDigit<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
    init() {}
}

extension SkipThenDigit: Parser.`Protocol` {
    typealias ParseOutput = UInt8
    typealias Failure = Digit<Input>.Error

    var body: some Parser.`Protocol`<Input, UInt8, Digit<Input>.Error> {
        Parser.Take.Sequence {
            Whitespace<Input>()
            Digit<Input>()
        }
        .error.map { $0.error }
    }
}

// ────────────────────────────────────────────────────────────
// Pattern 4: Void-skipping — right side
//
//     Parser.Take.Sequence {
//         Digit<Input>()        // → UInt8
//         Whitespace<Input>()   // → Void (skipped automatically)
//     }                         // → UInt8 / Either<Digit.Error, Never>
//     .error.map { $0.error }   // → UInt8 / Digit.Error
//
// When the right parser produces Void, the builder uses Skip.Second.
// Either<X, Never>.error eliminates the Never branch.
// ────────────────────────────────────────────────────────────

struct DigitThenSkip<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
    init() {}
}

extension DigitThenSkip: Parser.`Protocol` {
    typealias ParseOutput = UInt8
    typealias Failure = Digit<Input>.Error

    var body: some Parser.`Protocol`<Input, UInt8, Digit<Input>.Error> {
        Parser.Take.Sequence {
            Digit<Input>()
            Whitespace<Input>()
        }
        .error.map { $0.error }
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
        init() {}
    }
}

extension Version.Parser: Parser_Primitives.Parser.`Protocol` {
    typealias ParseOutput = Version
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
        .error.map { (either) -> Version.Error in
            // Left-nested Either tree from 5 parsers (after Void-skipping):
            //   Either<Either<Either<Either<Digit.E, Expect.E>, Digit.E>, Expect.E>, Digit.E>
            // Peel from the right — each .right is the Nth parser's error.
            switch either {
            case .right:
                return .expectedPatch       // 5th: Digit
            case .left(let e4):
                switch e4 {
                case .right:
                    return .expectedDot      // 4th: Expect('.')
                case .left(let e3):
                    switch e3 {
                    case .right:
                        return .expectedMinor // 3rd: Digit
                    case .left(let e2):
                        switch e2 {
                        case .right:
                            return .expectedDot   // 2nd: Expect('.')
                        case .left:
                            return .expectedMajor // 1st: Digit
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
    init() {}
}

extension SkipWhitespaceCountRest: Parser.`Protocol` {
    typealias ParseOutput = Int
    typealias Failure = Never

    var body: some Parser.`Protocol`<Input, Int, Never> {
        Parser.Take.Sequence {
            Whitespace<Input>()
            CountRest<Input>()
        }
        .error.map { (either) -> Never in
            switch either {
            case .left(let never): switch never {}
            case .right(let never): switch never {}
            @unknown default: fatalError()
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
//     .error.map { $0.error }         // → Version / Version.Error
//
// A declarative parser can use another declarative parser in its body.
// The inner parser's Failure (Version.Error) propagates outward.
// ────────────────────────────────────────────────────────────

struct WhitespaceVersion<Input: Collection.Slice.`Protocol`>: Sendable
where Input: Sendable, Input.Element == UInt8 {
    init() {}
}

extension WhitespaceVersion: Parser.`Protocol` {
    typealias ParseOutput = Version
    typealias Failure = Version.Error

    var body: some Parser.`Protocol`<Input, Version, Version.Error> {
        Parser.Take.Sequence {
            Whitespace<Input>()
            Version.Parser<Input>()
        }
        .error.map { $0.error }
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
    init() {}
}

extension TwoDigitNumber {
    enum Error: Swift.Error, Sendable, Equatable {
        case expectedDigit
    }
}

extension TwoDigitNumber: Parser.`Protocol` {
    typealias ParseOutput = Int
    typealias Failure = TwoDigitNumber<Input>.Error

    var body: some Parser.`Protocol`<Input, Int, TwoDigitNumber<Input>.Error> {
        Parser.Take.Sequence {
            Digit<Input>()
            Digit<Input>()
        }
        .map { tens, ones in Int(tens) * 10 + Int(ones) }
        .error.map { (_) -> TwoDigitNumber<Input>.Error in .expectedDigit }
    }
}

// MARK: - Unit Tests

extension ParserBuilderTests.Unit {
    @Test
    func `leaf parser has Body == Never`() throws {
        let parser = Digit<ByteInput>()
        var input = ByteInput([0x35])

        let result = try parser.parse(&input)

        #expect(result == 5)
        #expect(type(of: parser).Body.self == Never.self)
    }

    @Test
    func `single parser pass-through via var body`() throws {
        let parser = SingleDigit<ByteInput>()
        var input = ByteInput([0x37])

        let result = try parser.parse(&input)

        #expect(result == 7)
    }

    @Test
    func `two values compose into tuple`() throws {
        let parser = TwoDigits<ByteInput>()
        var input = ByteInput([0x31, 0x32])

        let (a, b) = try parser.parse(&input)

        #expect(a == 1)
        #expect(b == 2)
    }

    @Test
    func `void output from first parser is skipped`() throws {
        let parser = SkipThenDigit<ByteInput>()
        var input = ByteInput(utf8: "  5")

        let result = try parser.parse(&input)

        #expect(result == 5)
    }

    @Test
    func `void output from second parser is skipped`() throws {
        let parser = DigitThenSkip<ByteInput>()
        var input = ByteInput(utf8: "5  ")

        let result = try parser.parse(&input)

        #expect(result == 5)
    }

    @Test
    func `five parsers flatten with void-skipping and tuple flattening`() throws {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "1.2.3")

        let version = try parser.parse(&input)

        #expect(version == Version(1, 2, 3))
    }

    @Test
    func `output mapping transforms parsed tuple`() throws {
        let parser = TwoDigitNumber<ByteInput>()
        var input = ByteInput(utf8: "42")

        let result = try parser.parse(&input)

        #expect(result == 42)
    }

    @Test
    func `error mapping converts Either tree to domain error`() {
        let parser = TwoDigits<ByteInput>()
        var input = ByteInput(utf8: "1x")

        #expect(throws: TwoDigits<ByteInput>.Error.second) {
            try parser.parse(&input)
        }
    }

    @Test
    func `infallible body produces Never failure`() {
        let parser = SkipWhitespaceCountRest<ByteInput>()
        var input = ByteInput(utf8: "   hello")

        let count = parser.parse(&input)

        #expect(count == 5)
    }

    @Test
    func `nested declarative parsers compose`() throws {
        let parser = WhitespaceVersion<ByteInput>()
        var input = ByteInput(utf8: "  1.0.9")

        let version = try parser.parse(&input)

        #expect(version == Version(1, 0, 9))
    }

    @Test
    func `default parse delegates to body`() throws {
        let parser = Version.Parser<ByteInput>()
        var input1 = ByteInput(utf8: "3.1.4")
        var input2 = ByteInput(utf8: "3.1.4")

        let fromBody = try parser.body.parse(&input1)
        let fromParse = try parser.parse(&input2)

        #expect(fromBody == fromParse)
    }

    @Test
    func `input is consumed correctly through var body`() throws {
        let parser = SkipThenDigit<ByteInput>()
        var input = ByteInput(utf8: " 7rest")

        _ = try parser.parse(&input)

        #expect(input.first == UInt8(ascii: "r"))
    }

    @Test
    func `version parser consumes exactly five bytes`() throws {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "1.2.3 extra")

        _ = try parser.parse(&input)

        #expect(input.first == UInt8(ascii: " "))
    }

    @Test
    func `version parser boundary values`() throws {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "0.0.0")

        let version = try parser.parse(&input)

        #expect(version == Version(0, 0, 0))
    }

    @Test
    func `version parser max single digits`() throws {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "9.9.9")

        let version = try parser.parse(&input)

        #expect(version == Version(9, 9, 9))
    }
}

// MARK: - Edge Case Tests

extension ParserBuilderTests.EdgeCase {
    @Test
    func `single pass-through body propagates failure`() {
        let parser = SingleDigit<ByteInput>()
        var input = ByteInput(utf8: "x")

        #expect(throws: Digit<ByteInput>.Error.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `single pass-through body fails on empty input`() {
        let parser = SingleDigit<ByteInput>()
        var input = ByteInput([])

        #expect(throws: Digit<ByteInput>.Error.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `two digits first failure maps to domain error`() {
        let parser = TwoDigits<ByteInput>()
        var input = ByteInput(utf8: "x")

        #expect(throws: TwoDigits<ByteInput>.Error.first) {
            try parser.parse(&input)
        }
    }

    @Test
    func `two digits second failure maps to domain error`() {
        let parser = TwoDigits<ByteInput>()
        var input = ByteInput(utf8: "1x")

        #expect(throws: TwoDigits<ByteInput>.Error.second) {
            try parser.parse(&input)
        }
    }

    @Test
    func `two digits empty input maps to first`() {
        let parser = TwoDigits<ByteInput>()
        var input = ByteInput([])

        #expect(throws: TwoDigits<ByteInput>.Error.first) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedMajor on empty`() {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput([])

        #expect(throws: Version.Error.expectedMajor) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedDot after major`() {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "1x")

        #expect(throws: Version.Error.expectedDot) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedMinor after first dot`() {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "1.x")

        #expect(throws: Version.Error.expectedMinor) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedPatch after second dot`() {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "1.2.x")

        #expect(throws: Version.Error.expectedPatch) {
            try parser.parse(&input)
        }
    }

    @Test
    func `version parser reports expectedDot on truncated input`() {
        let parser = Version.Parser<ByteInput>()
        var input = ByteInput(utf8: "1")

        #expect(throws: Version.Error.expectedDot) {
            try parser.parse(&input)
        }
    }

    @Test
    func `nested declarative parser propagates inner errors`() {
        let parser = WhitespaceVersion<ByteInput>()
        var input = ByteInput(utf8: "  1.2.x")

        #expect(throws: Version.Error.expectedPatch) {
            try parser.parse(&input)
        }
    }

    @Test
    func `nested declarative parser fails on empty after whitespace`() {
        let parser = WhitespaceVersion<ByteInput>()
        var input = ByteInput(utf8: "   ")

        #expect(throws: Version.Error.expectedMajor) {
            try parser.parse(&input)
        }
    }

    @Test
    func `infallible parser returns zero on empty input`() {
        let parser = SkipWhitespaceCountRest<ByteInput>()
        var input = ByteInput([])

        let count = parser.parse(&input)

        #expect(count == 0)
    }

    @Test
    func `infallible parser counts only non-whitespace`() {
        let parser = SkipWhitespaceCountRest<ByteInput>()
        var input = ByteInput(utf8: "     ")

        let count = parser.parse(&input)

        #expect(count == 0)
    }

    @Test
    func `void-skip left with empty input delegates error`() {
        let parser = SkipThenDigit<ByteInput>()
        var input = ByteInput([])

        #expect(throws: Digit<ByteInput>.Error.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `void-skip left with only whitespace delegates error`() {
        let parser = SkipThenDigit<ByteInput>()
        var input = ByteInput(utf8: "   ")

        #expect(throws: Digit<ByteInput>.Error.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `void-skip right preserves value with no trailing whitespace`() throws {
        let parser = DigitThenSkip<ByteInput>()
        var input = ByteInput(utf8: "9")

        let result = try parser.parse(&input)

        #expect(result == 9)
    }

    @Test
    func `output mapping fails on non-digit`() {
        let parser = TwoDigitNumber<ByteInput>()
        var input = ByteInput(utf8: "x")

        #expect(throws: TwoDigitNumber<ByteInput>.Error.expectedDigit) {
            try parser.parse(&input)
        }
    }

    @Test
    func `output mapping fails on single digit`() {
        let parser = TwoDigitNumber<ByteInput>()
        var input = ByteInput(utf8: "4x")

        #expect(throws: TwoDigitNumber<ByteInput>.Error.expectedDigit) {
            try parser.parse(&input)
        }
    }
}
