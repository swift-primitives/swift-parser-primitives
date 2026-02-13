//import Testing
//import Parser_Primitives_Test_Support
//
//// MARK: - Test Suite Structure
//
//@Suite("Parser.Not")
//struct ParserNotTests {
//    @Suite struct Unit {}
//    @Suite struct EdgeCase {}
//}
//
//// MARK: - Unit Tests
//
//extension ParserNotTests.Unit {
//    @Test
//    func `succeeds when upstream fails`() throws {
//        let parser = Parser.Byte<ByteInput>(0x41).not()
//        var input = ByteInput([0x42])
//
//        try parser.parse(&input)
//
//        // Input not consumed
//        #expect(input.first == 0x42)
//    }
//
//    @Test
//    func `never consumes input on success`() throws {
//        let parser = Parser.First.Element<ByteInput>()
//            .filter { $0 == 0xFF }
//            .not()
//        var input = ByteInput([0x01, 0x02])
//
//        try parser.parse(&input)
//
//        #expect(input.first == 0x01)
//    }
//}
//
//// MARK: - Edge Case Tests
//
//extension ParserNotTests.EdgeCase {
//    @Test
//    func `fails when upstream succeeds`() {
//        let parser = Parser.Byte<ByteInput>(0x41).not()
//        var input = ByteInput([0x41])
//
//        #expect(throws: Parser.Not<Parser.Byte<ByteInput>>.Error.self) {
//            try parser.parse(&input)
//        }
//    }
//
//    @Test
//    func `never consumes input on failure`() {
//        let parser = Parser.Byte<ByteInput>(0x41).not()
//        var input = ByteInput([0x41, 0x42])
//
//        _ = try? parser.parse(&input)
//
//        #expect(input.first == 0x41)
//    }
//
//    @Test
//    func `succeeds on empty input when upstream requires elements`() throws {
//        let parser = Parser.First.Element<ByteInput>().not()
//        var input = ByteInput([])
//
//        try parser.parse(&input)
//    }
//}
