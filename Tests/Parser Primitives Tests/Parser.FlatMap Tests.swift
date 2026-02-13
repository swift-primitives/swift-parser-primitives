//import Testing
//import Parser_Primitives_Test_Support
//
//// MARK: - Test Suite Structure
//
//@Suite("Parser.FlatMap")
//struct ParserFlatMapTests {
//    @Suite struct Unit {}
//    @Suite struct EdgeCase {}
//}
//
//// MARK: - Unit Tests
//
//extension ParserFlatMapTests.Unit {
//    @Test
//    func `chains parsers where second depends on first output`() throws {
//        let parser = Parser.First.Element<ByteInput>()
//            .flatMap { count -> Parser.Consume.Exactly<ByteInput> in
//                Parser.Consume.Exactly(Int(count))
//            }
//        var input = ByteInput([0x03, 0x0A, 0x0B, 0x0C, 0xFF])
//
//        let result = try parser.parse(&input)
//
//        #expect(result.count == 3)
//        #expect(input.first == 0xFF)
//    }
//}
//
//// MARK: - Edge Case Tests
//
//extension ParserFlatMapTests.EdgeCase {
//    @Test
//    func `upstream failure prevents downstream execution`() {
//        let parser = Parser.First.Element<ByteInput>()
//            .flatMap { _ in Parser.Always<ByteInput, Int>(0) }
//        var input = ByteInput([])
//
//        #expect(throws: (any Error).self) {
//            try parser.parse(&input)
//        }
//    }
//
//    @Test
//    func `downstream failure propagates as right error`() {
//        let parser = Parser.Always<ByteInput, UInt8>(5)
//            .flatMap { count -> Parser.Consume.Exactly<ByteInput> in
//                Parser.Consume.Exactly(Int(count))
//            }
//        var input = ByteInput([0x01, 0x02])
//
//        #expect(throws: (any Error).self) {
//            try parser.parse(&input)
//        }
//    }
//}
