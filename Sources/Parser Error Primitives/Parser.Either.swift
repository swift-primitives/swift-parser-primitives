//
//  Parser.Either.swift
//  swift-parser-primitives
//
//  Parser-specific extensions on the canonical Either type.
//

import Algebra_Primitives
public import Text_Primitives

// MARK: - Protocol for Chain Access

/// Protocol enabling static-dispatch chain accessors.
///
/// This protocol is public to support constrained extensions but should be
/// considered an implementation detail. Never use as existential.
public protocol _EitherChain {
    associatedtype _Left
    associatedtype _Right
    var _left: _Left? { get }
    var _right: _Right? { get }
}

// MARK: - _EitherChain Conformance

extension Either: _EitherChain {
    @inlinable
    public var _left: Left? { left }

    @inlinable
    public var _right: Right? { right }
}

// MARK: - Chain Accessors

extension Either {
    /// First case in chain (alias for left).
    @inlinable
    public var first: Left? { left }
}

extension Either where Right: _EitherChain {
    /// Second case in chain.
    @inlinable
    public var second: Right._Left? { right?._left }
}

extension Either where Right: _EitherChain, Right._Right: _EitherChain {
    /// Third case in chain.
    @inlinable
    public var third: Right._Right._Left? { right?._right?._left }
}

extension Either
where
    Right: _EitherChain,
    Right._Right: _EitherChain,
    Right._Right._Right: _EitherChain
{
    /// Fourth case in chain.
    @inlinable
    public var fourth: Right._Right._Right._Left? { right?._right?._right?._left }
}

extension Either
where
    Right: _EitherChain,
    Right._Right: _EitherChain,
    Right._Right._Right: _EitherChain,
    Right._Right._Right._Right: _EitherChain
{
    /// Fifth case in chain.
    @inlinable
    public var fifth: Right._Right._Right._Right._Left? { right?._right?._right?._right?._left }
}

extension Either
where
    Right: _EitherChain,
    Right._Right: _EitherChain,
    Right._Right._Right: _EitherChain,
    Right._Right._Right._Right: _EitherChain,
    Right._Right._Right._Right._Right: _EitherChain
{
    /// Sixth case in chain.
    @inlinable
    public var sixth: Right._Right._Right._Right._Right._Left? {
        right?._right?._right?._right?._right?._left
    }
}

// MARK: - Located Error Utilities

extension Either: Parser.Error.Located.`Protocol`
where Left: Parser.Error.Located.`Protocol`, Right: Parser.Error.Located.`Protocol` {
    /// The text position of this composed error.
    ///
    /// Returns the offset of whichever branch is active.
    @inlinable
    public var offset: Text.Position {
        switch self {
        case .left(let e): return e.offset
        case .right(let e): return e.offset
        }
    }
}

extension Either
where Left: Parser.Error.Located.`Protocol`, Right: Parser.Error.Located.`Protocol` {
    /// Returns the earliest offset from either branch.
    ///
    /// Useful for finding the "first" error position in a chain
    /// of alternatives that all failed.
    @inlinable
    public var earliestOffset: Text.Position {
        offset
    }
}
