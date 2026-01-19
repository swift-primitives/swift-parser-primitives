//
//  Machine.Parser.Parse.swift
//  swift-parser-primitives
//
//  Parse accessor providing execution variants.
//

public import Machine_Primitives

extension Parser.Machine.Parser {
    /// Accessor for parse execution variants.
    ///
    /// Use this to access different execution modes:
    /// - `parser.parse(&input)` - direct execution
    /// - `parser.parse.incremental` - memoized execution context
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Direct parsing
    /// let result = try parser.parse(&input)
    ///
    /// // Incremental parsing
    /// var ctx = parser.parse.incremental
    /// let tree1 = try ctx(&input)
    /// ctx.invalidate(edit)
    /// let tree2 = try ctx(&input2)
    /// ```
    public struct Parse {
        @usableFromInline
        let parser: Parser.Machine.Parser<Input, Output, Failure>

        @usableFromInline
        init(parser: Parser.Machine.Parser<Input, Output, Failure>) {
            self.parser = parser
        }
    }

    /// Returns the parse accessor for execution variants.
    @inlinable
    public var parse: Parse {
        Parse(parser: self)
    }
}

// MARK: - Direct Execution

extension Parser.Machine.Parser.Parse {
    /// Parses the input directly (non-memoized).
    ///
    /// This is equivalent to calling `parser.parse(&input)` directly.
    ///
    /// - Parameter input: The input to parse.
    /// - Returns: The parsed output.
    /// - Throws: The failure error if parsing fails.
    @inlinable
    public func callAsFunction(_ input: inout Input) throws(Failure) -> Output {
        try Parser.Machine.run(program: parser.program, root: parser.root, input: &input, as: Output.self)
    }
}
