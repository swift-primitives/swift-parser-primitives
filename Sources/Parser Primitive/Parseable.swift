//
//  Parseable.swift
//  swift-parser-primitives
//
//  Canonical attachment protocol for parsing.
//

/// A type that has a canonical parser.
///
/// Conforming types declare their canonical ``Parser`` and provide a static
/// accessor to obtain it. This enables generic algorithms to discover the
/// parser for any `Parseable` type.
///
/// ```swift
/// extension IPv4.Address: Parseable {
///     static var parser: IPv4.Address.Parser { .init() }
/// }
/// ```
///
/// ## Byte-input convenience
///
/// The byte-domain ASCII-init convenience (`init(ascii:)` constrained to
/// `Parser.Input == Byte.Input`) lives in `swift-byte-parser-primitives`
/// per the byte-extraction arc — it's a byte-domain extension on this
/// protocol, not a parser-domain core concern.
public protocol Parseable {
    /// The canonical parser type for this value.
    associatedtype Parser: Parser_Primitive.Parser.`Protocol`

    /// The canonical parser instance.
    static var parser: Parser { get }
}
