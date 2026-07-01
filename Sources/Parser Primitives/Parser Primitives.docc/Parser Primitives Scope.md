# Parser Primitives Scope

`swift-parser-primitives` provides the **combinator-based parsing substrate** —
the generic, zero-copy `Parser` protocol family plus the combinators (map,
flatMap, oneOf, take, skip, prefix, many, …) that compose simple parsers into
complex grammars. It owns the `Parser` namespace and is input-agnostic: it
works over `Span<UInt8>`, `[UInt8]`, `Substring`, or any conforming input type,
with no Foundation dependency.

## Per-[MOD-031] shape

The package follows `[MOD-031]` per-sub-namespace decomposition. `Parser
Primitive` is the layer-invariant namespace target per `[MOD-017]` — it owns
`public enum Parser`, the core `Parser.Protocol` / `Parser.Printer` /
`Parser.Bidirectional` protocols, the `Parser.Builder` result builder, and the
`Parseable` attachment protocol, all zero-external-dependency. The `Parser.Witness`
closure conformer lives in a **dedicated `Parser Witness Primitives` target**, held
deliberately outside `Parser Primitive` (see Owner targets). Each combinator is its own sub-namespace target
(`Parser.Map`, `Parser.OneOf`, `Parser.Take`, …). The external-dependency-bearing
content that the legacy `[MOD-001]` Core funnelled splits into dedicated
sub-namespaces:

- **Parser Remaining Primitives** — the `Collection.Slice.Protocol.remainingCount`
  utility (carries `Collection_Primitives`); used by `End` / `Match` for
  remaining-element error reporting.
- **Parser Tagged Primitives** — the generic `Tagged: Parseable` conformance +
  `Tagged.UnderlyingParser` (carries `Tagged_Primitives`).

## Core target

There is no implementation-bearing `Parser Primitives Core` target. The legacy
`[MOD-001]` Core convention is deprecated; the former Core's declarations were
relocated to `Parser Primitive` (zero-dep) and the Remaining / Tagged
sub-namespaces (external-dep) during the L1 core-dissolution sweep (2026-06-23).
`Parser Primitives Core` survives only as a **transitional exports-only shim**
re-exporting the dissolved surface (root + Remaining + Tagged + the funneled
Array / Collection / Input / Sequence modules) so downstream consumers
(`swift-argument-primitives`, `swift-ascii-parser-primitives`,
`swift-byte-parser-primitives`, `swift-parser-effect-primitives`) keep compiling
until the cleanup wave repoints them to the umbrella. The shim is removed in
that wave.

## Owner targets

- **Parser Primitive** — the `public enum Parser` namespace + the core parsing
  protocols / builder / `Parseable`. Zero external deps per `[MOD-017]`.
- **Parser Remaining Primitives**, **Parser Tagged Primitives** — the
  external-dependency-bearing relocations described above.
- **Parser Witness Primitives** — the `Parser.Witness` closure-backed leaf
  conformer (`Body == Never`) + its `Parser.Protocol` conformance. Held in its
  own target, **not** in `Parser Primitive`, so the defining module contains no
  `Body == Never` conformer — otherwise the `@inlinable` leaf-default
  `var body: Never` `read` accessor is serialized into `Parser_Primitive` and
  re-emitted bodyless into consumer leaf modules, crashing SIL verification on
  Windows (+Asserts) / Embedded / `-sil-verify-all`. Mirrors the
  `swift-serializer-primitives` `Serializer Witness Primitives` split. Depends
  only on `Parser Primitive`.
- **Parser \<Combinator\> Primitives** — one target per combinator
  (`Error`, `Match`, `Map`, `FlatMap`, `Filter`, `OneOf`, `Optional`, `Skip`,
  `Take`, `Many`, `Pair`, `Consume`, `Discard`, `Prefix`, `First`, `Tracked`,
  `Spanned`, `Span`, `Locate`, `Peek`, `Not`, `Always`, `Fail`, `Rest`, `End`,
  `Lazy`, `Trace`, `Parse`, `Conformance`, `Constraint`, `EndOfInput`,
  `Conditional`). Each depends on the root plus the external modules its own
  signatures require.
- **Parser Primitives** — umbrella; re-exports the root + every sub-namespace so
  consumers needing the union write `import Parser_Primitives`. It does NOT
  re-export the `Parser Primitives Core` shim.
- **Parser Primitives Test Support** — published test-fixtures product.

## Out of scope

- **Byte / ASCII / domain parsers** — input-specialized parsers (byte-domain
  `init(ascii:)` conveniences, ASCII grammars, argument parsing) live in sibling
  packages (`swift-byte-parser-primitives`, `swift-ascii-parser-primitives`,
  `swift-argument-primitives`) that USE this substrate.
- **Serialization** — the inverse direction (Type → bytes) is
  `swift-serializer-primitives`; this package's `Parser.Printer` covers only the
  parser-printer round-trip symmetry, not one-way serialization.

## Evaluation rule

Sub-target additions are evaluated against this scope.

- A proposed addition that is a **generic, input-agnostic combinator** —
  a new way to compose parsers over any input — gets a new sub-namespace target
  here.
- A proposed addition that is **input-specialized** (byte-domain, ASCII-domain,
  a concrete grammar) extracts to the relevant sibling package, not into this one.
- A zero-external-dependency foundational declaration folds into `Parser Primitive`;
  an external-dependency-bearing one gets (or joins) its own sub-namespace target.
