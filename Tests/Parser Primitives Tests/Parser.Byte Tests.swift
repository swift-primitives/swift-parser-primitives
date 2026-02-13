//import Testing
//import Parser_Primitives_Test_Support
//
//// MARK: - Test Suite Structure
//
//@Suite("Parser.Byte")
//struct ParserByteTests {
//    @Suite struct Unit {}
//    @Suite struct EdgeCase {}
//}
//
//// MARK: - Unit Tests
//
//extension ParserByteTests.Unit {
//    @Test
//    func `matches expected byte and advances input`() throws {
//        let parser = Parser.Byte<ByteInput>(0x41)
//        var input = ByteInput([0x41, 0x42, 0x43])
//
//        try parser.parse(&input)
//
//        #expect(input.first == 0x42)
//    }
//
//    @Test
//    func `consumes single byte from input`() throws {
//        let parser = Parser.Byte<ByteInput>(0xFF)
//        var input = ByteInput([0xFF])
//
//        try parser.parse(&input)
//
//        #expect(input.isEmpty)
//    }
//}
//
//// MARK: - Edge Case Tests
//
//extension ParserByteTests.EdgeCase {
//    @Test
//    func `fails on empty input with EndOfInput error`() {
//        let parser = Parser.Byte<ByteInput>(0x41)
//        var input = ByteInput([])
//
//        #expect {
//            try parser.parse(&input)
//        } throws: { error in
//            guard let either = error as? Parser.Error.Either<Parser.EndOfInput.Error, Parser.Match.Error> else {
//                return false
//            }
//            return either.left != nil
//        }
//    }
//
//    @Test
//    func `fails on wrong byte with Match error`() {
//        let parser = Parser.Byte<ByteInput>(0x41)
//        var input = ByteInput([0x42])
//
//        #expect {
//            try parser.parse(&input)
//        } throws: { error in
//            guard let either = error as? Parser.Error.Either<Parser.EndOfInput.Error, Parser.Match.Error> else {
//                return false
//            }
//            return either.right != nil
//        }
//    }
//}
