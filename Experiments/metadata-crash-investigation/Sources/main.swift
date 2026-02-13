// Test: Parser.Always from Parser_Primitives after full clean
import Parser_Primitives

typealias ByteInput = Input.Slice<Buffer<UInt8>.Linear>

print("Creating Parser.Always<ByteInput, Int>...")
let parser = Parser.Always<ByteInput, Int>(42)
print("output = \(parser.output)")
print("PASSED")
