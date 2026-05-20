// Tagged+Parseable.swift
// swift-parser-primitives
//
// Canonical generic Parseable conformance for Tagged. Tagged<Tag, Underlying>
// is Parseable when Underlying is — its parsing delegates to the underlying
// value's canonical parser, then wraps the result in Tagged via the
// `_unchecked` initializer (parse semantics: the underlying parser produces
// a valid Underlying; tagging is a phantom-type lift, no validation).
//
// This is domain-agnostic: Tagged becomes Parseable for ANY Underlying that
// is Parseable — binary-domain (`Underlying.Parser == Binary.Parser<Underlying>`),
// text-domain, future parser flavors all work uniformly.

public import Tagged_Primitives

extension Tagged where Underlying: Parseable, Underlying.Parser.Output == Underlying {
    /// Wrapper parser that lifts `Underlying.Parser` to produce `Tagged<Tag, Underlying>`
    /// values.
    ///
    /// `parse(_:)` runs the underlying parser then wraps the result via the
    /// `_unchecked:` initializer. The Input and Failure types are inherited
    /// from the underlying's parser — Tagged adds no input-shape or error
    /// concerns of its own.
    public struct UnderlyingParser: Parser_Primitives_Core.Parser.`Protocol` {
        public typealias Input = Underlying.Parser.Input
        public typealias Output = Tagged<Tag, Underlying>
        public typealias Failure = Underlying.Parser.Failure
        public typealias Body = Never

        @inlinable
        public init() {}

        @inlinable
        public borrowing func parse(
            _ input: inout Underlying.Parser.Input
        ) throws(Underlying.Parser.Failure) -> Tagged<Tag, Underlying> {
            let underlying = try Underlying.parser.parse(&input)
            return Tagged<Tag, Underlying>(_unchecked: underlying)
        }
    }
}

extension Tagged: Parseable where
    Underlying: Parseable,
    Underlying.Parser.Output == Underlying
{
    @inlinable
    public static var parser: Tagged<Tag, Underlying>.UnderlyingParser {
        Tagged<Tag, Underlying>.UnderlyingParser()
    }
}
