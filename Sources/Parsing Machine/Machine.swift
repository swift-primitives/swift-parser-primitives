@_exported import Parsing_Primitives
public import Identity_Primitives

extension Parsing {
    public enum Machine {}
}

extension Parsing.Machine {
    /// A parser built from a defunctionalized program that runs without recursive call-stack growth.
    public struct Parser<Input: Parsing.Input, Output, Failure: Error & Sendable>: Parsing.Parser, Sendable
    where Input: Sendable, Output: Sendable {
        @usableFromInline
        let program: Program<Input, Failure>

        @usableFromInline
        let root: Node<Input, Failure>.ID

        @usableFromInline
        init(program: Program<Input, Failure>, root: Node<Input, Failure>.ID) {
            self.program = program
            self.root = root
        }

        @inlinable
        public func parse(_ input: inout Input) throws(Failure) -> Output {
            try program.run(root: root, input: &input, as: Output.self)
        }
    }

    /// A reference to a node in the program, used for recursive grammar definitions.
    public struct Reference<Input: Parsing.Input, Failure: Error & Sendable, Output>: Sendable
    where Input: Sendable {
        @usableFromInline
        let node: Node<Input, Failure>.ID

        @usableFromInline
        init(node: Node<Input, Failure>.ID) {
            self.node = node
        }
    }

    /// A builder context for constructing machine programs.
    public struct Builder<Input: Parsing.Input, Failure: Error & Sendable>: Sendable
    where Input: Sendable {
        @usableFromInline
        var program: Program<Input, Failure>

        @usableFromInline
        init(maxDepth: Int? = nil) {
            self.program = Program<Input, Failure>(maxDepth: maxDepth)
        }

        @usableFromInline
        mutating func allocate(_ node: Node<Input, Failure>) -> Node<Input, Failure>.ID {
            program.allocate(node)
        }
    }

    /// An expression in the machine program, representing a parser that produces Output.
    public struct Expression<Input: Parsing.Input, Failure: Error & Sendable, Output>: Sendable
    where Input: Sendable {
        @usableFromInline
        let node: Node<Input, Failure>.ID

        @usableFromInline
        init(node: Node<Input, Failure>.ID) {
            self.node = node
        }
    }
}
