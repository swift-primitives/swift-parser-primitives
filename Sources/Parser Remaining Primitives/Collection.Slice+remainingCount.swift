//
//  Collection.Slice+remainingCount.swift
//  swift-parser-primitives
//
//  Remaining-count utility on Collection.Slice.Protocol.
//
//  This `Collection.Slice.Protocol` extension carries an external dependency
//  (`Collection_Primitives`), so per [MOD-031] it lives in its own
//  sub-namespace target rather than the zero-dependency `Parser Primitive`
//  root. Parser combinators that report "expected end of input" (e.g. `End`,
//  `Match`) use it to attach a remaining-element count to their errors.
//

public import Collection_Primitives

extension Collection.Slice.`Protocol` {
    /// Counts remaining elements by walking indices.
    ///
    /// Used for error reporting when a typed count is not available.
    public var remainingCount: Int {
        var count = 0
        var i = startIndex
        while i < endIndex {
            i = index(after: i)
            count += 1
        }
        return count
    }
}
