public import Parser_Primitives

extension Parser {
    /// Namespace for parser test-support types.
    ///
    /// Houses the test-only byte iterator (`Parser.Test.Iterator`), byte
    /// collection (`Parser.Test.Bytes`), and cursor input typealias
    /// (`Parser.Test.Input`). All three types live in the
    /// `Parser Primitives Test Support` target and are not part of the
    /// production API surface.
    public enum Test {}
}
