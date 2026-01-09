//
//  Parsing.swift
//  swift-standards
//
//  Generic, zero-copy parsing primitives for Swift.
//
//  ## Design Philosophy
//
//  This module provides combinator-based parsing that is:
//  - **Generalized**: Works with any input type, not just String or UTF8
//  - **Zero-copy**: Leverages Span<T> and index-based consumption
//  - **Non-allocating**: No heap allocations in the hot path
//  - **Swift Embedded compatible**: No Foundation dependencies
//
//  ## Architecture
//
//  The core abstraction is `Parser<Input, Output>`:
//  - Input: The type being consumed (e.g., Span<UInt8>, [UInt8], Substring)
//  - Output: The parsed result
//
//  Parsers consume from the front of a mutable input reference:
//  ```swift
//  func parse(_ input: inout Input) throws(Error) -> Output
//  ```
//
//  This mutation-based approach enables:
//  - Zero-copy slicing (just advance an index)
//  - Natural composition (each parser picks up where the last left off)
//  - Backtracking when needed (save/restore the input state)
//
//  ## Input Protocol
//
//  The `ParserInput` protocol abstracts over input types:
//  - `Span<UInt8>` - Zero-copy view (preferred)
//  - `[UInt8]` - Byte arrays
//  - `Substring` / `Substring.UTF8View` - String parsing
//  - Custom types implementing the protocol
//
//  ## Relationship to Binary Module
//
//  Parsing complements serialization:
//  - `Binary.Serializable`: Type → bytes (infallible, into buffer)
//  - `Parsing.Parser`: bytes → Type (fallible, from input)
//
//  The `Binary.ASCII.Serializable` protocol already defines parsing via
//  `init(ascii:in:)`. This module provides the combinator infrastructure
//  for building complex parsers from simple primitives.
//
//  ## Example
//
//  ```swift
//  // Parse a key-value pair: "key=value"
//  let keyValue = Parse {
//      Prefix { $0 != UInt8(ascii: "=") }  // key
//      "="
//      Rest()                               // value
//  }
//
//  var input: Span<UInt8> = ...
//  let (key, value) = try keyValue.parse(&input)
//  ```
//

/// Namespace for parsing primitives and combinators.
public enum Parsing {}
