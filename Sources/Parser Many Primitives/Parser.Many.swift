//
//  Parser.Many.swift
//  swift-parser-primitives
//
//  Repetition — repeat a parser zero or more times.
//

extension Parser {
    /// A parser that applies another parser repeatedly (no separator).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Zero or more digits
    /// let digits = Parser.Many { Digit() }
    ///
    /// // One or more digits
    /// let digits1 = Parser.Many(1...) { Digit() }
    ///
    /// // Exactly 4 digits
    /// let pin = Parser.Many(4...4) { Digit() }
    /// ```
    ///
    /// ## Separator variant
    ///
    /// For repetition with separators between elements, see
    /// ``Parser/Many/Separated``, which inherits `Input` and `Element` from
    /// this type and adds a `Separator` parameter.
    public struct Many<Input: Parser.Input.`Protocol`, Element: Parser.`Protocol`>
    where Element.Input == Input {
        @usableFromInline
        let element: Element

        @usableFromInline
        let minimum: Int

        /// `Int.max` means no maximum.
        @usableFromInline
        let maximum: Int

        @inlinable
        public init(
            _ range: PartialRangeFrom<Int>,
            @Parser.Take.Builder<Input> element: () -> Element
        ) {
            self.element = element()
            self.minimum = range.lowerBound
            self.maximum = .max
        }

        @inlinable
        public init(
            _ range: ClosedRange<Int>,
            @Parser.Take.Builder<Input> element: () -> Element
        ) {
            self.element = element()
            self.minimum = range.lowerBound
            self.maximum = range.upperBound
        }

        @inlinable
        public init(
            @Parser.Take.Builder<Input> element: () -> Element
        ) {
            self.element = element()
            self.minimum = 0
            self.maximum = .max
        }
    }
}

extension Parser.Many: Parser.`Protocol` {
    public typealias Output = [Element.Output]
    public typealias Failure = Parser.Many<Input, Element>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        var results: [Element.Output] = []
        if maximum < .max {
            results.reserveCapacity(maximum)
        } else if minimum > 0 {
            results.reserveCapacity(minimum)
        }

        while results.count < maximum {
            let checkpoint = input.checkpoint

            do {
                let next = try element.parse(&input)
                results.append(next)
            } catch {
                input.restore.to(__unchecked: (), checkpoint)
                break
            }
        }

        if results.count < minimum {
            throw Failure.countTooLow(expected: minimum, got: results.count)
        }

        return results
    }
}

// MARK: - Printer Conformance

extension Parser.Many: Parser.Printer
where Element: Parser.Printer {
    @inlinable
    public func print(_ output: [Element.Output], into input: inout Input) throws(Failure) {
        if output.count < minimum {
            throw .countTooLow(expected: minimum, got: output.count)
        }
        if maximum < .max, output.count > maximum {
            throw .countTooHigh(expected: maximum, got: output.count)
        }

        for item in output.reversed() {
            do {
                try element.print(item, into: &input)
            } catch {
                break
            }
        }
    }
}
