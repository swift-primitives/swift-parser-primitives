//import Testing
//import Parser_Primitives_Test_Support
//
//// MARK: - Test Suite Structure
//
//@Suite("Parser.Prefix.UpTo")
//struct ParserPrefixUpToTests {
//    @Suite struct Unit {}
//    @Suite struct EdgeCase {}
//}
//
//// MARK: - Unit Tests
//
//extension ParserPrefixUpToTests.Unit {
//    @Test
//    func `consumes up to delimiter without including it`() {
//        let parser = Parser.Prefix.UpTo<ByteInput>([UInt8(ascii: ",")])
//        var input = ByteInput(utf8: "hello,world")
//
//        let result = parser.parse(&input)
//
//        #expect(result == ByteInput(utf8: "hello"))
//        #expect(input.first == UInt8(ascii: ","))
//    }
//
//    @Test
//    func `handles multi-byte delimiter`() {
//        let parser = Parser.Prefix.UpTo<ByteInput>(Swift.Array("-->".utf8))
//        var input = ByteInput(utf8: "content-->rest")
//
//        let result = parser.parse(&input)
//
//        #expect(result == ByteInput(utf8: "content"))
//    }
//}
//
//// MARK: - Edge Case Tests
//
//extension ParserPrefixUpToTests.EdgeCase {
//    @Test
//    func `consumes all when delimiter not found`() {
//        let parser = Parser.Prefix.UpTo<ByteInput>([0xFF])
//        var input: ByteInput = [0x01, 0x02, 0x03]
//
//        let result = parser.parse(&input)
//
//        #expect(result == [0x01, 0x02, 0x03])
//    }
//
//    @Test
//    func `returns empty when delimiter at start`() {
//        let parser = Parser.Prefix.UpTo<ByteInput>([UInt8(ascii: "x")])
//        var input = ByteInput(utf8: "xyz")
//
//        let result = parser.parse(&input)
//
//        #expect(result.isEmpty)
//        #expect(input.first == UInt8(ascii: "x"))
//    }
//
//    @Test
//    func `empty input returns empty result`() {
//        let parser = Parser.Prefix.UpTo<ByteInput>([0x00])
//        var input: ByteInput = []
//
//        let result = parser.parse(&input)
//
//        #expect(result.isEmpty)
//    }
//}
