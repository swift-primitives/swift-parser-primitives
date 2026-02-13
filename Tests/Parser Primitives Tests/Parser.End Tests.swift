//import Testing
//import Parser_Primitives_Test_Support
//
//// MARK: - Test Suite Structure
//
//@Suite("Parser.End")
//struct ParserEndTests {
//    @Suite struct Unit {}
//    @Suite struct EdgeCase {}
//}
//
//// MARK: - Unit Tests
//
//extension ParserEndTests.Unit {
//    @Test
//    func `succeeds on empty input`() throws {
//        let parser = Parser.End<ByteInput>()
//        var input: ByteInput = []
//
//        try parser.parse(&input)
//    }
//}
//
//// MARK: - Edge Case Tests
//
//extension ParserEndTests.EdgeCase {
//    @Test
//    func `fails with remaining input`() {
//        let parser = Parser.End<ByteInput>()
//        var input: ByteInput = [0x01, 0x02]
//
//        #expect(throws: Parser.Match.Error.self) {
//            try parser.parse(&input)
//        }
//    }
//
//    @Test
//    func `fails with single remaining byte`() {
//        let parser = Parser.End<ByteInput>()
//        var input: ByteInput = [0xFF]
//
//        #expect(throws: Parser.Match.Error.self) {
//            try parser.parse(&input)
//        }
//    }
//}
