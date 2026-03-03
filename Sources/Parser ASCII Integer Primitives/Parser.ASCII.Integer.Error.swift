//
//  Parser.ASCII.Integer.Error.swift
//  swift-parser-primitives
//
//  Error types for ASCII integer parsing.
//

extension Parser.ASCII.Integer {
    public enum Error: Swift.Error, Sendable, Equatable {
        /// No digit bytes found at current position.
        case noDigits
        /// The parsed value would overflow the target integer type.
        case overflow
    }
}
