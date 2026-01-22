//
//  Machine.Parser+Compiled.swift
//  swift-parser-primitives
//
//  Parse accessor extensions for Machine compilation.
//

// MARK: - Compilation Variants

extension Parser.Parse
where P.Input: Parser_Primitives.Parser.Input & Sendable,
      P.Output: Sendable,
      P.Failure: Sendable
{
    /// Creates a lazily-compiled version of this parser.
    ///
    /// The returned parser compiles on first use and caches the program
    /// for subsequent parses. It is NOT `Sendable`.
    ///
    /// For cross-task sharing, use `prepared(using:)` instead.
    ///
    /// - Parameter witness: The compilation witness.
    /// - Returns: A lazy-compiling parser wrapper.
    @inlinable
    public func compiled(
        using witness: Parser.Machine.Compile.Witness<P>
    ) -> Parser.Machine.Compiled<P> {
        Parser.Machine.Compiled(source: parser, witness: witness)
    }

    /// Creates an eagerly-compiled, immutable parser.
    ///
    /// The returned parser is fully compiled and conditionally `Sendable`.
    /// Use this when you need to share a compiled parser across tasks.
    ///
    /// - Parameter witness: The compilation witness.
    /// - Returns: An immutable prepared parser.
    @inlinable
    public func prepared(
        using witness: Parser.Machine.Compile.Witness<P>
    ) -> Parser.Machine.Prepared<P> {
        Parser.Machine.Prepared(source: parser, witness: witness)
    }
}

// MARK: - Convenience for Sendable Parsers

extension Parser.Parse
where P: Sendable,
      P.Input: Parser_Primitives.Parser.Input & Sendable,
      P.Output: Sendable,
      P.Failure: Sendable
{
    /// Creates a lazily-compiled version using leaf compilation.
    ///
    /// Convenience that uses `.leaf` as the witness. The returned parser
    /// is NOT `Sendable`. For cross-task sharing, use `prepared()`.
    ///
    /// - Returns: A lazy-compiling parser wrapper.
    @inlinable
    public func compiled() -> Parser.Machine.Compiled<P> {
        compiled(using: .leaf)
    }

    /// Creates an eagerly-compiled, immutable parser using leaf compilation.
    ///
    /// Convenience that uses `.leaf` as the witness. The returned parser
    /// is `Sendable` and safe for cross-task sharing.
    ///
    /// - Returns: An immutable prepared parser.
    @inlinable
    public func prepared() -> Parser.Machine.Prepared<P> {
        prepared(using: .leaf)
    }
}
