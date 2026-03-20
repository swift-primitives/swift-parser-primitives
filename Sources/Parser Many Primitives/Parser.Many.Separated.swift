//
//  Parser.Many.Separated.swift
//  swift-standards
//
//  Repetition parser with separators.
//

extension Parser.Many {
    /// A parser that applies another parser repeatedly with separators.
    ///
    /// `Separated` collects results into an array. It always succeeds (possibly with
    /// an empty array) unless a minimum count is specified.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Comma-separated values
    /// let csv = Parser.Many.Separated {
    ///     Field()
    /// } separator: {
    ///     ","
    /// }
    ///
    /// // One or more with separator
    /// let list = Parser.Many.Separated(1...) {
    ///     Int.parser()
    /// } separator: {
    ///     ","
    /// }
    /// ```
    public struct Separated<Input: Parser.Input.`Protocol`, Element: Parser.`Protocol`, Separator: Parser.`Protocol`>: Sendable
    where Element: Sendable, Separator: Sendable,
          Element.Input == Input, Separator.Input == Input {
        @usableFromInline
        let element: Element

        @usableFromInline
        let separator: Separator

        @usableFromInline
        let minimum: Int

        /// `Int.max` means no maximum.
        @usableFromInline
        let maximum: Int

        @inlinable
        public init(
            _ range: PartialRangeFrom<Int>,
            @Parser.Take.Builder<Input> element: () -> Element,
            @Parser.Take.Builder<Input> separator: () -> Separator
        ) {
            self.element = element()
            self.separator = separator()
            self.minimum = range.lowerBound
            self.maximum = .max
        }

        @inlinable
        public init(
            _ range: ClosedRange<Int>,
            @Parser.Take.Builder<Input> element: () -> Element,
            @Parser.Take.Builder<Input> separator: () -> Separator
        ) {
            self.element = element()
            self.separator = separator()
            self.minimum = range.lowerBound
            self.maximum = range.upperBound
        }

        @inlinable
        public init(
            @Parser.Take.Builder<Input> element: () -> Element,
            @Parser.Take.Builder<Input> separator: () -> Separator
        ) {
            self.element = element()
            self.separator = separator()
            self.minimum = 0
            self.maximum = .max
        }
    }
}

extension Parser.Many.Separated: Parser.`Protocol` {
    public typealias Output = [Element.Output]
    public typealias Failure = Parser.Many.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        var results: [Element.Output] = []
        if maximum < .max {
            results.reserveCapacity(maximum)
        } else if minimum > 0 {
            results.reserveCapacity(minimum)
        }

        // Parse first element
        do {
            let first = try element.parse(&input)
            results.append(first)
        } catch {
            if minimum > 0 {
                throw Failure.countTooLow(expected: minimum, got: 0)
            }
            return results
        }

        // Parse remaining elements (with separator)
        while results.count < maximum {
            let checkpoint = input.checkpoint

            // Try separator
            do {
                _ = try separator.parse(&input)
            } catch {
                input.restore.to(__unchecked: (), checkpoint)
                break
            }

            // Try next element
            do {
                let next = try element.parse(&input)
                results.append(next)
            } catch {
                input.restore.to(__unchecked: (), checkpoint)
                break
            }
        }

        // Check minimum
        if results.count < minimum {
            throw Failure.countTooLow(expected: minimum, got: results.count)
        }

        return results
    }
}

// MARK: - Printer Conformance

extension Parser.Many.Separated: Parser.Printer
where Element: Parser.Printer, Separator: Parser.Printer, Separator.Output == Void {
    @inlinable
    public func print(_ output: [Element.Output], into input: inout Input) throws(Failure) {
        // Validate count constraints
        if output.count < minimum {
            throw Failure.countTooLow(expected: minimum, got: output.count)
        }
        if maximum < .max, output.count > maximum {
            throw Failure.countTooHigh(expected: maximum, got: output.count)
        }

        // Print in reverse order with separators between elements.
        // Note: Element and separator printing failures cause early termination
        // but are not propagated - this printer only throws count constraint errors.
        var isFirst = true
        for item in output.reversed() {
            if !isFirst {
                do {
                    try separator.print((), into: &input)
                } catch {
                    break
                }
            }
            do {
                try element.print(item, into: &input)
            } catch {
                break
            }
            isFirst = false
        }
    }
}
