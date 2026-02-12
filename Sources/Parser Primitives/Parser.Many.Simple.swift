//
//  Parser.Many.Simple.swift
//  swift-standards
//
//  Simple repetition parser (no separator).
//

extension Parser.Many {
    /// A parser that applies another parser repeatedly (no separator).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Zero or more digits
    /// let digits = Parser.Many.Simple { Digit() }
    ///
    /// // One or more digits
    /// let digits1 = Parser.Many.Simple(1...) { Digit() }
    ///
    /// // Exactly 4 digits
    /// let pin = Parser.Many.Simple(4...4) { Digit() }
    /// ```
    public struct Simple<Input: Parser.Input, Element: Parser.`Protocol`>: Sendable
    where Element: Sendable, Element.Input == Input {
        @usableFromInline
        let element: Element

        @usableFromInline
        let minimum: Int

        @usableFromInline
        let maximum: Int?

        @inlinable
        public init(
            _ range: PartialRangeFrom<Int>,
            @Parser.Take.Builder<Input> element: () -> Element
        ) {
            self.element = element()
            self.minimum = range.lowerBound
            self.maximum = nil
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
            self.maximum = nil
        }
    }
}

extension Parser.Many.Simple: Parser.`Protocol` {
    public typealias ParseOutput = [Element.ParseOutput]
    public typealias Failure = Parser.Many.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> ParseOutput {
        var results: [Element.ParseOutput] = []

        while maximum.map({ results.count < $0 }) ?? true {
            let saved = input

            do {
                let next = try element.parse(&input)
                results.append(next)
            } catch {
                input = saved
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

extension Parser.Many.Simple: Parser.Printer
where Element: Parser.Printer {
    @inlinable
    public func print(_ output: [Element.ParseOutput], into input: inout Input) throws(Failure) {
        // Validate count constraints
        if output.count < minimum {
            throw .countTooLow(expected: minimum, got: output.count)
        }
        if let max = maximum, output.count > max {
            throw .countTooHigh(expected: max, got: output.count)
        }

        // Print in reverse order.
        // Note: Element printing failures cause early termination but are not
        // propagated - this printer only throws count constraint errors.
        for item in output.reversed() {
            do {
                try element.print(item, into: &input)
            } catch {
                break
            }
        }
    }
}
