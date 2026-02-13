//import Testing
//import Parser_Primitives_Test_Support
//
//// MARK: - Test Suite Structure
//
//@Suite("Parser.Consume.Exactly")
//struct ParserConsumeExactlyTests {
//    @Suite struct Unit {}
//    @Suite struct EdgeCase {}
//}
//
//// MARK: - Unit Tests
//
//extension ParserConsumeExactlyTests.Unit {
//    @Test
//    func `consumes exactly N elements`() throws {
//        let parser = Parser.Consume.Exactly<ByteInput>(3)
//        var input: ByteInput = [0x01, 0x02, 0x03, 0x04, 0x05]
//
//        let result = try parser.parse(&input)
//
//        #expect(result == [0x01, 0x02, 0x03])
//        #expect(!input.isEmpty)
//    }
//
//    @Test
//    func `consumes all when count equals input length`() throws {
//        let parser = Parser.Consume.Exactly<ByteInput>(3)
//        var input: ByteInput = [0x0A, 0x0B, 0x0C]
//
//        let result = try parser.parse(&input)
//
//        #expect(result == [0x0A, 0x0B, 0x0C])
//        #expect(input.isEmpty)
//    }
//}
//
//// MARK: - Edge Case Tests
//
//extension ParserConsumeExactlyTests.EdgeCase {
//    @Test
//    func `fails when input has fewer elements than requested`() {
//        let parser = Parser.Consume.Exactly<ByteInput>(5)
//        var input: ByteInput = [0x01, 0x02]
//
//        #expect(throws: Parser.Constraint.Error.self) {
//            try parser.parse(&input)
//        }
//    }
//
//    @Test
//    func `zero count succeeds without consuming`() throws {
//        let parser = Parser.Consume.Exactly<ByteInput>(0)
//        var input: ByteInput = [0x01]
//
//        let result = try parser.parse(&input)
//
//        #expect(result.isEmpty)
//        #expect(!input.isEmpty)
//    }
//
//    @Test
//    func `zero count succeeds on empty input`() throws {
//        let parser = Parser.Consume.Exactly<ByteInput>(0)
//        var input: ByteInput = []
//
//        let result = try parser.parse(&input)
//
//        #expect(result.isEmpty)
//    }
//}
