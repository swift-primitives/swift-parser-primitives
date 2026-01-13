//
//  Machine.Parser+Compiled.swift
//  swift-parsing-primitives
//
//  Extension providing compiled() and prepared() methods on parsers.
//

// MARK: - Lazy Compilation (compiled)

extension Parsing.Parser
where Input: Parsing.Input & Sendable,
      Output: Sendable,
      Failure: Sendable
{
    /// Creates a lazily-compiled version of this parser.
    ///
    /// The returned parser compiles on first use and caches the program
    /// for subsequent parses. It is NOT `Sendable`.
    ///
    /// For cross-task sharing, use `prepared(using:)` instead, or call
    /// `compiled(using:).prepared()` to get a `Sendable` wrapper.
    ///
    /// - Parameter witness: The compilation witness.
    /// - Returns: A lazy-compiling parser wrapper.
    @inlinable
    public func compiled(
        using witness: Parsing.Machine.Compile.Witness<Self>
    ) -> Parsing.Machine.Compiled<Self> {
        Parsing.Machine.Compiled(source: self, witness: witness)
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
        using witness: Parsing.Machine.Compile.Witness<Self>
    ) -> Parsing.Machine.Prepared<Self> {
        Parsing.Machine.Prepared(source: self, witness: witness)
    }
}

// MARK: - Convenience for Sendable Parsers

extension Parsing.Parser
where Self: Sendable,
      Input: Parsing.Input & Sendable,
      Output: Sendable,
      Failure: Sendable
{
    /// Creates a lazily-compiled version using leaf compilation.
    ///
    /// Convenience that uses `.leaf` as the witness. The returned parser
    /// is NOT `Sendable`. For cross-task sharing, use `prepared()`.
    ///
    /// - Returns: A lazy-compiling parser wrapper.
    @inlinable
    public func compiled() -> Parsing.Machine.Compiled<Self> {
        compiled(using: .leaf)
    }

    /// Creates an eagerly-compiled, immutable parser using leaf compilation.
    ///
    /// Convenience that uses `.leaf` as the witness. The returned parser
    /// is `Sendable` and safe for cross-task sharing.
    ///
    /// - Returns: An immutable prepared parser.
    @inlinable
    public func prepared() -> Parsing.Machine.Prepared<Self> {
        prepared(using: .leaf)
    }
}
