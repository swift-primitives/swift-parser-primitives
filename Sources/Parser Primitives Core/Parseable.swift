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
public protocol Parseable {
    /// The canonical parser type for this value.
    associatedtype Parser: Parser_Primitives_Core.Parser.`Protocol`

    /// The canonical parser instance.
    static var parser: Parser { get }
}

// MARK: - Byte Input Convenience

extension Parseable
where Parser.Input == Parser_Primitives_Core.Parser.Input.Bytes,
      Parser.Output == Self
{
    /// Creates a value by parsing ASCII bytes using the canonical parser.
    ///
    /// - Parameter ascii: The ASCII bytes to parse.
    /// - Throws: `Parser.Failure` if parsing fails.
    @inlinable
    public init(ascii: Swift.Array<UInt8>) throws(Parser.Failure) {
        var input = Parser_Primitives_Core.Parser.Input.Bytes(ascii)
        self = try Self.parser.parse(&input)
    }
}
