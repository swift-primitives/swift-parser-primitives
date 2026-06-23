// DEPRECATED — transitional shim (L1 core-dissolution sweep 2026-06-23). Re-exports the dissolved Core surface; removed in the cleanup wave.
//
// The protocol/builder/printer/witness declarations that previously lived here
// now live in the zero-dependency `Parser Primitive` root; the external-dep
// carriers split into `Parser Remaining Primitives` (Collection) and
// `Parser Tagged Primitives` (Tagged). This target survives only as an
// exports-only shim so consumers of the `Parser Primitives Core` product keep
// compiling — including the external modules Core previously funneled
// (Array / Collection / Input / Sequence) — until the cleanup wave repoints
// them to the umbrella / root.
@_exported public import Array_Primitives
@_exported public import Collection_Primitives
@_exported public import Input_Primitives
@_exported public import Parser_Primitive
@_exported public import Parser_Remaining_Primitives
@_exported public import Parser_Tagged_Primitives
@_exported public import Sequence_Primitives
