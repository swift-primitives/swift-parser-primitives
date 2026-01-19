//
//  Parser.Either.swift
//  swift-parser-primitives
//
//  Binary sum type for composing heterogeneous errors.
//

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

// MARK: - Either

extension Parser.Error {
    /// Binary sum type for composing heterogeneous errors.
    ///
    /// Used by combinators like `OneOf` and `FlatMap` to compose errors from
    /// parsers with different failure types without requiring existentials.
    ///
    /// ## Error Composition
    ///
    /// When `OneOf` combines parsers with different error types:
    /// ```swift
    /// let parser = OneOf.Two(parserA, parserB)
    /// // Failure = Parser.Error.Either<ParserA.Failure, ParserB.Failure>
    /// ```
    ///
    /// For more than two parsers, Either chains nest:
    /// ```swift
    /// // Either<A.Failure, Either<B.Failure, C.Failure>>
    /// ```
    ///
    /// ## Chain Accessors
    ///
    /// For nested chains, use positional accessors:
    /// ```swift
    /// error.first   // Left?
    /// error.second  // Right.Left? (for nested Either)
    /// error.third   // Right.Right.Left? (for doubly-nested)
    /// ```
    ///
    /// ## Never Elimination
    ///
    /// When one side is `Never` (infallible), the error simplifies:
    /// - `Either<Never, R>` → use `.error` to extract `R`
    /// - `Either<L, Never>` → use `.error` to extract `L`
    public enum Either<Left: Swift.Error & Sendable, Right: Swift.Error & Sendable>:
        Swift.Error, Sendable {
        case left(Left)
        case right(Right)
    }
}

// MARK: - Equatable

extension Parser.Error.Either: Equatable where Left: Equatable, Right: Equatable {}

// MARK: - _EitherChain Conformance

extension Parser.Error.Either: _EitherChain {
    @inlinable
    public var _left: Left? { left }

    @inlinable
    public var _right: Right? { right }
}

// MARK: - Basic Accessors

extension Parser.Error.Either {
    /// Extract left error if present.
    @inlinable
    public var left: Left? {
        if case .left(let e) = self { return e }
        return nil
    }

    /// Extract right error if present.
    @inlinable
    public var right: Right? {
        if case .right(let e) = self { return e }
        return nil
    }
}

// MARK: - Chain Accessors (Embedded-Compatible)

extension Parser.Error.Either {
    /// First case in chain (alias for left).
    @inlinable
    public var first: Left? { left }
}

extension Parser.Error.Either where Right: _EitherChain {
    /// Second case in chain.
    @inlinable
    public var second: Right._Left? { right?._left }
}

extension Parser.Error.Either where Right: _EitherChain, Right._Right: _EitherChain {
    /// Third case in chain.
    @inlinable
    public var third: Right._Right._Left? { right?._right?._left }
}

extension Parser.Error.Either
where Right: _EitherChain,
      Right._Right: _EitherChain,
      Right._Right._Right: _EitherChain
{
    /// Fourth case in chain.
    @inlinable
    public var fourth: Right._Right._Right._Left? { right?._right?._right?._left }
}

extension Parser.Error.Either
where Right: _EitherChain,
      Right._Right: _EitherChain,
      Right._Right._Right: _EitherChain,
      Right._Right._Right._Right: _EitherChain
{
    /// Fifth case in chain.
    @inlinable
    public var fifth: Right._Right._Right._Right._Left? { right?._right?._right?._right?._left }
}

extension Parser.Error.Either
where Right: _EitherChain,
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

// MARK: - Backwards Compatibility

extension Parser {
    /// Backwards compatibility alias. Use `Parser.Error.Either` instead.
    @available(*, deprecated, renamed: "Parser.Error.Either")
    public typealias Either<L: Swift.Error & Sendable, R: Swift.Error & Sendable> = Parser.Error.Either<L, R>
}

// MARK: - Never Elimination

extension Parser.Error.Either where Left == Never {
    /// When left is `Never`, extract the right error unconditionally.
    @inlinable
    public var error: Right {
        switch self {
        case .right(let e): return e
        }
    }
}

extension Parser.Error.Either where Right == Never {
    /// When right is `Never`, extract the left error unconditionally.
    @inlinable
    public var error: Left {
        switch self {
        case .left(let e): return e
        }
    }
}

// MARK: - Located Error Utilities

extension Parser.Error.Either: Parser.Error.LocatedError
where Left: Parser.Error.LocatedError, Right: Parser.Error.LocatedError {
    /// The byte offset of this composed error.
    ///
    /// Returns the offset of whichever branch is active.
    @inlinable
    public var offset: Int {
        switch self {
        case .left(let e): return e.offset
        case .right(let e): return e.offset
        }
    }
}

extension Parser.Error.Either
where Left: Parser.Error.LocatedError, Right: Parser.Error.LocatedError {
    /// Returns the earliest offset from either branch.
    ///
    /// Useful for finding the "first" error position in a chain
    /// of alternatives that all failed.
    @inlinable
    public var earliestOffset: Int {
        offset
    }
}
