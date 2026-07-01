//
//  Parser.Witness.swift
//  swift-parser-primitives
//
//  Closure-backed parser witness — one combinator among many.
//

extension Parser {

    /// A closure-backed parser — the canonical witness for
    /// ``Parser/Protocol``.
    ///
    /// `Parser.Witness` stores a parse closure and exposes it as the methods
    /// required by ``Parser/Protocol``. Both the struct and its conformance
    /// live in the dedicated `Parser Witness Primitives` target — deliberately
    /// **outside** the `Parser Primitive` module that defines
    /// ``Parser/Protocol`` — so the defining module holds no `Body == Never`
    /// leaf conformer (see the module's ``Parser.Witness`` relocation note).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let lengthParser = Parser.Witness<Substring, Int, Never> { input in
    ///     let length = input.count
    ///     input = ""
    ///     return length
    /// }
    /// ```
    ///
    /// ## Leaf Witness
    ///
    /// `Parser.Witness` is a leaf conformer: it implements ``parse(_:)``
    /// directly via the stored closure rather than composing through a
    /// `body`.
    ///
    /// ## Storage
    ///
    /// `_parse` is `public` so `@inlinable` methods declared in the
    /// `Parser Witness Primitives` target can inline through. The underscore
    /// signals "implementation hatch — consumers should call ``parse(_:)``
    /// rather than invoke the closure directly."
    public struct Witness<Input: ~Copyable & ~Escapable, Output, Failure: Swift.Error> {
        /// The stored parse closure. Underscore signals implementation hatch.
        public var _parse: (inout Input) throws(Failure) -> Output

        /// Creates a parser witness from a parse closure.
        ///
        /// - Parameter parse: Parses an `Output` value from the input cursor.
        @inlinable
        public init(_ parse: @escaping (inout Input) throws(Failure) -> Output) {
            self._parse = parse
        }
    }

    /// A closure-backed parser that cannot fail.
    ///
    /// `Parser.Pure<Input, Output>` is shorthand for
    /// `Parser.Witness<Input, Output, Never>`. Use it to elide the `Failure`
    /// type argument when the parser is infallible.
    ///
    /// ```swift
    /// let p = Parser.Pure<Substring, Int> { input in
    ///     let n = input.count
    ///     input = ""
    ///     return n
    /// }
    /// ```
    public typealias Pure<Input, Output> = Witness<Input, Output, Never>
        where Input: ~Copyable & ~Escapable
}
