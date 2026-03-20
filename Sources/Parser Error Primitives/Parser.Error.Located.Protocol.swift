//
//  Parser.Error.Located.Protocol.swift
//  swift-parser-primitives
//
//  Protocol for errors that carry location information.
//

// WORKAROUND: Protocol hoisted to module level because self-referential
//   conformance (`Located: Located.Protocol`) creates a circular reference.
//   The typealias on `Located` provides the canonical access path.
// WHY: Consumers need `Parser.Error.Located.Protocol` for generic constraints
//   and conformance declarations on composed error types (e.g., `Either`).
// WHEN TO REMOVE: When Swift resolves self-referential typealias conformance.
// TRACKING: Swift language limitation — no specific evolution proposal.

/// Protocol for errors that carry location information.
///
/// Used to enable location-aware utilities on `Either` compositions
/// of parser errors.
///
/// - Important: Use `Parser.Error.Located.Protocol` to refer to this
///   protocol. Do not reference the hoisted name directly.
public protocol __ParserErrorLocatedProtocol: Swift.Error {
    /// The byte offset where this error occurred.
    var offset: Int { get }
}

// MARK: - Typealias

extension Parser.Error.Located {
    /// Protocol for errors that carry location information.
    ///
    /// Access via `Parser.Error.Located.Protocol`.
    public typealias `Protocol` = __ParserErrorLocatedProtocol
}

// MARK: - Conformance

// Uses hoisted name directly (avoids self-referential cycle).
// Consumers should use `Parser.Error.Located.Protocol` instead.
extension Parser.Error.Located: __ParserErrorLocatedProtocol {}
