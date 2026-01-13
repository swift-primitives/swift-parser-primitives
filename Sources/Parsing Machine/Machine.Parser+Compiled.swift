//
//  Machine.Parser+Compiled.swift
//  swift-parsing-primitives
//
//  Extension providing compiled() method on parsers.
//

extension Parsing.Parser
where Input: Parsing.Input & Sendable,
      Output: Sendable,
      Failure: Sendable
{
    /// Creates a compiled version of this parser using the given witness.
    ///
    /// The returned parser lazily compiles on first use and caches
    /// the compiled program for subsequent parses.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var compiled = myParser.compiled(using: .leaf)
    /// let result = try compiled.parse(&input)
    /// ```
    ///
    /// - Parameter witness: The compilation witness that defines how to
    ///   compile this parser into a Machine expression.
    /// - Returns: A compiled parser wrapper.
    @inlinable
    public func compiled(
        using witness: Parsing.Machine.Compile.Witness<Self>
    ) -> Parsing.Machine.Compiled<Self> {
        Parsing.Machine.Compiled(source: self, witness: witness)
    }
}

// MARK: - Convenience for Sendable Parsers

extension Parsing.Parser
where Self: Sendable,
      Input: Parsing.Input & Sendable,
      Output: Sendable,
      Failure: Sendable
{
    /// Creates a compiled version of this parser using leaf compilation.
    ///
    /// This is a convenience that uses `.leaf` as the witness, which wraps
    /// the parser's `parse` method directly as an opaque Machine operation.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var compiled = myParser.compiled()
    /// let result = try compiled.parse(&input)
    /// ```
    ///
    /// - Returns: A compiled parser wrapper.
    @inlinable
    public func compiled() -> Parsing.Machine.Compiled<Self> {
        compiled(using: .leaf)
    }
}
