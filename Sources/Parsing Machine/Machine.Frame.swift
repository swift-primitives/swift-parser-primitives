import Parsing_Primitives

extension Parsing.Machine {
    @safe
    @usableFromInline
    enum Frame<Input: Parsing.Input, Failure: Error & Sendable>: @unchecked Sendable
    where Input: Sendable {
        @safe
        @usableFromInline
        enum Sequence: @unchecked Sendable {
            case second(b: Node<Input, Failure>.ID, combine: Combine.Erased)
            /// Stores handle to first value in arena, waiting for second value
            case combine(firstHandle: Value.Handle, combine: Combine.Erased)
        }

        case map(transform: Transform.Erased)
        case tryMap(transform: Transform.Throwing<Failure>)
        case flatMap(next: Next.Erased)
        case sequence(Sequence)
        /// Backtracking frame for oneOf - stores checkpoint instead of full input copy
        case oneOf(alternatives: [Node<Input, Failure>.ID], index: Int, savedCheckpoint: Input.Checkpoint)
        /// Accumulation frame for many - stores handles to accumulated results
        case many(child: Node<Input, Failure>.ID, savedCheckpoint: Input.Checkpoint, resultHandles: [Value.Handle], finalize: Finalize.Array)
        /// Optional frame - stores handle to none value for backtracking
        case optional(savedCheckpoint: Input.Checkpoint, wrapSome: Transform.Erased, noneHandle: Value.Handle)
        case recursiveExit
        /// Memoization frame - caches result when node completes
        case memoization(node: Int, startPosition: Input.Checkpoint)
    }
}
