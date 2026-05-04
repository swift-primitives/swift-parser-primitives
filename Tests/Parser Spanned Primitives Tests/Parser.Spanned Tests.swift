import Parser_Primitives_Test_Support
import Testing

// MARK: - Test Suite Structure

@Suite("Parser.Spanned")
struct ParserSpannedTests {
    @Suite struct Unit {}
}

// MARK: - Unit Tests

extension ParserSpannedTests.Unit {
    @Test
    func `stores value with source span`() {
        let spanned = Parser.Spanned(42, start: 10, end: 14)

        #expect(spanned.value == 42)
        #expect(spanned.start == 10)
        #expect(spanned.end == 14)
    }

    @Test
    func `length is end minus start`() {
        let spanned = Parser.Spanned(0, start: 5, end: 15)

        #expect(spanned.length == 10)
    }

    @Test
    func `range produces correct Swift range`() {
        let spanned = Parser.Spanned(0, start: 2, end: 7)

        #expect(spanned.range == 2..<7)
    }

    @Test
    func `map transforms value preserving span`() {
        let spanned = Parser.Spanned(10, start: 0, end: 4)

        let mapped = spanned.map { $0 * 2 }

        #expect(mapped.value == 20)
        #expect(mapped.start == 0)
        #expect(mapped.end == 4)
    }
}
