import Parsing_Primitives

extension Parsing.Machine {
    @usableFromInline
    struct Program<Input: Parsing.Input, Failure: Error & Sendable>: Sendable
    where Input: Sendable {
        @usableFromInline
        var nodes: [Node<Input, Failure>]

        @usableFromInline
        let maxDepth: Int?

        @usableFromInline
        init(maxDepth: Int? = nil) {
            self.nodes = []
            self.maxDepth = maxDepth
        }

        @usableFromInline
        mutating func allocate(_ node: Node<Input, Failure>) -> Node<Input, Failure>.ID {
            let id = Node<Input, Failure>.ID(nodes.count)
            nodes.append(node)
            return id
        }

        @usableFromInline
        subscript(id: Node<Input, Failure>.ID) -> Node<Input, Failure> {
            get { nodes[id.rawValue] }
            set { nodes[id.rawValue] = newValue }
        }
    }
}
