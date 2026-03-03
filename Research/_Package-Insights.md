# Parser Primitives Insights

<!--
---
title: Parser Primitives Insights
version: 1.0.0
last_updated: 2026-01-19
applies_to: [swift-parser-primitives]
normative: false
---
-->
Design decisions, implementation patterns, and lessons learned specific to this package.

## Overview

This document captures insights that emerged during development of swift-parser-primitives. These are not API requirements—they are recorded decisions and patterns that inform future work on this package.

**Document type**: Non-normative (recorded decisions, not requirements).

**Consolidation source**: Reflection entries tagged with `[Package: swift-parser-primitives]`.

---

## Layering Discipline as Future-Proofing

**Date**: 2026-01-19

**Context**: Analysis of lifetime-dependent borrowed cursors revealed that parsing-primitives' abstraction boundary protected it from constraints affecting binary-primitives.

### The Protective Boundary

`~Escapable` is a memory/ownership concern. Parsing-primitives defines abstract parsing—input consumption, backtracking, composition. It doesn't know or care about memory ownership.

This ignorance is protective. When Swift's ownership model evolved (Swift 6.x introduced `~Escapable`), parsing-primitives didn't need to change:

- The `Parsing.Input` protocol still works
- The `Parsing.Parser` protocol still works
- The combinators still work

The concern is localized to binary-primitives, where it belongs. `Binary.Bytes.Parser` handles borrowed cursors. `Binary.Bytes.Input.View` handles `~Escapable` storage. Parsing-primitives never needed to know.

### Premature Abstraction Would Have Hurt

If parsing-primitives had tried to "generalize" for borrowed inputs early:

```swift
// Hypothetical bad design
public protocol Parser<Input, Output, Failure> {
    associatedtype Input: ~Escapable  // Can't do this in Swift 6.x
    ...
}
```

This would have blocked on Swift's limitation. The protocol would be unusable until the language caught up.

By staying abstract—`associatedtype Input` with no ownership requirements—parsing-primitives avoided painting itself into a corner. The limitation becomes binary-primitives' problem, solvable at that layer.

### The Layering Principle, Applied

Lower layers implement mechanisms. Higher layers implement policies.

| Layer | Role | Concern |
|-------|------|---------|
| **Parsing Primitives (Tier 4)** | Mechanism | "consume input, produce output, handle failure" |
| **Binary Primitives (Tier 7)** | Policy | "this is owned input; that is borrowed input; here's how to bridge them" |

The `~Escapable` constraint is policy. It belongs at the policy layer. The mechanism layer stays stable.

### Evidence in Code

The architecture anticipated this limitation before it was formally analyzed:

`Parsing.Parser.swift` lines 64-66:
```swift
/// For bytes parsing, use `Parsing.Bytes.Input` (an escapable cursor type)
/// rather than `Span<UInt8>` directly. Swift 6.2 does not allow `~Escapable`
/// constraints on protocol associated types.
```

`Parsing.Input.swift` lines 97-109:
```swift
// Note: Span<T> is ~Escapable, which requires special handling.
// For now, we provide conformances only for Escapable collection types.
// Span-based parsing will be added when lifetime annotations are stable.
```

These comments were written when the code was first designed. They transform potential confusion ("why doesn't Span conform?") into documented design ("because Swift 6.x doesn't support this, and we're deferring until it does").

**Applies to**: Protocol design decisions in `Parsing.Parser`, `Parsing.Input`, and related types.

---

## Related

- Parsing
