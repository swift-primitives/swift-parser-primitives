import Parsing_Primitives
import Container_Primitives
import Storage_Primitives
import Identity_Primitives

extension Parsing.Machine.Program {
    @usableFromInline
    func run<Output>(
        root: Parsing.Machine.Node<Input, Failure>.ID,
        input: inout Input,
        as outputType: Output.Type
    ) throws(Failure) -> Output {
        typealias Value = Parsing.Machine.Value
        typealias Frame = Parsing.Machine.Frame<Input, Failure>
        typealias Node = Parsing.Machine.Node<Input, Failure>
        typealias Recovery = Parsing.Machine.Failure.Recovery

        var current = root
        // Pre-allocate stack capacity based on maxDepth or reasonable default.
        // The 4x multiplier accounts for worst-case frame usage per recursion level:
        // - 1 recursiveExit frame per level
        // - Up to 3 additional frames for combinator chains (sequence, map, oneOf, etc.)
        let stackCapacity = (maxDepth ?? 10000) * 4
        var frames: Stack<Frame>
        do {
            frames = try Stack<Frame>(capacity: stackCapacity)
        } catch {
            fatalError("Failed to allocate frame stack with capacity \(stackCapacity): \(error)")
        }

        // Pre-allocate arena for intermediate values
        let arenaCapacity = stackCapacity * 2  // Generous capacity for values
        var arena: Value.Arena
        do {
            arena = try Value.Arena(capacity: arenaCapacity)
        } catch {
            fatalError("Failed to allocate value arena with capacity \(arenaCapacity): \(error)")
        }

        var depth = 0
        var pendingHandle: Value.Handle? = nil

        // DEBUG INVARIANTS
        func checkInvariants(_ label: String) {
            precondition(depth >= 0, "[\(label)] depth went negative: \(depth)")
            precondition(current.rawValue >= 0 && current.rawValue < nodes.count, "[\(label)] current node out of bounds: \(current)")
            if let limit = maxDepth {
                precondition(depth <= limit + 1, "[\(label)] depth exceeded limit: \(depth) > \(limit)")
            }
        }

        while true {
            checkInvariants("loop-start")

            if let handle = pendingHandle {
                pendingHandle = nil
                let value = arena.release(handle)

                if frames.isEmpty {
                    guard let result = value.take(Output.self) else {
                        fatalError("Type mismatch in Machine output")
                    }
                    return result
                }

                guard let frame = frames.pop() else {
                    fatalError("Internal error: expected frame on stack")
                }

                switch frame {
                case .map(let transform):
                    let transformed = transform.apply(value)
                    pendingHandle = arena.allocate(transformed)

                case .tryMap(let transform):
                    do {
                        let transformed = try transform.apply(value)
                        pendingHandle = arena.allocate(transformed)
                    } catch {
                        switch try handleFailure(
                            error: error,
                            frames: &frames,
                            arena: &arena,
                            input: &input,
                            depth: &depth
                        ) {
                        case .continueWith(let recovered):
                            current = Node.ID(recovered.rawValue)
                            checkInvariants("after-tryMap-handleFailure-continueWith")
                        case .handleReady(let recoveredHandle):
                            pendingHandle = recoveredHandle
                            checkInvariants("after-tryMap-handleFailure-handleReady")
                        case .propagate:
                            throw error
                        }
                    }

                case .flatMap(let next):
                    let erasedID = next.next(value)
                    current = Node.ID(erasedID.rawValue)

                case .sequence(.second(let b, let combine)):
                    let firstHandle = arena.allocate(value)
                    try! frames.push(.sequence(.combine(firstHandle: firstHandle, combine: combine)))
                    current = b

                case .sequence(.combine(let firstHandle, let combine)):
                    let first = arena.release(firstHandle)
                    let combined = combine.combine(first, value)
                    pendingHandle = arena.allocate(combined)

                case .oneOf:
                    pendingHandle = arena.allocate(value)

                case .many(let child, _, var resultHandles, let finalize):
                    let handle = arena.allocate(value)
                    resultHandles.append(handle)
                    let checkpoint = input.checkpoint
                    try! frames.push(.many(child: child, savedCheckpoint: checkpoint, resultHandles: resultHandles, finalize: finalize))
                    current = child

                case .optional(_, let wrapSome, let noneHandle):
                    // Release the pre-allocated none value since we have a result
                    _ = arena.release(noneHandle)
                    let wrapped = wrapSome.apply(value)
                    pendingHandle = arena.allocate(wrapped)

                case .recursiveExit:
                    depth -= 1
                    checkInvariants("after-recursiveExit-return")
                    pendingHandle = arena.allocate(value)

                case .memoization:
                    fatalError("Memoization frame in non-memoized execution")
                }

                continue
            }

            let node = self[current]

            switch node {
            case .leaf(let leaf):
                do {
                    let value = try leaf.run(&input)
                    pendingHandle = arena.allocate(value)
                } catch {
                    switch try handleFailure(
                        error: error,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth
                    ) {
                    case .continueWith(let recovered):
                        current = Node.ID(recovered.rawValue)
                        checkInvariants("after-leaf-handleFailure-continueWith")
                    case .handleReady(let handle):
                        pendingHandle = handle
                        checkInvariants("after-leaf-handleFailure-handleReady")
                    case .propagate:
                        throw error
                    }
                }

            case .pure(let value):
                pendingHandle = arena.allocate(value)

            case .map(let child, let transform):
                try! frames.push(.map(transform: transform))
                current = child

            case .tryMap(let child, let transform):
                try! frames.push(.tryMap(transform: transform))
                current = child

            case .flatMap(let child, let next):
                try! frames.push(.flatMap(next: next))
                current = child

            case .sequence(let a, let b, let combine):
                try! frames.push(.sequence(.second(b: b, combine: combine)))
                current = a

            case .oneOf(let alternatives):
                guard !alternatives.isEmpty else {
                    fatalError("Empty oneOf")
                }
                let checkpoint = input.checkpoint
                if alternatives.count > 1 {
                    try! frames.push(.oneOf(
                        alternatives: alternatives,
                        index: 1,
                        savedCheckpoint: checkpoint
                    ))
                }
                current = alternatives[0]

            case .many(let child, let finalize):
                let checkpoint = input.checkpoint
                try! frames.push(.many(child: child, savedCheckpoint: checkpoint, resultHandles: [], finalize: finalize))
                current = child

            case .optional(let child, let wrapSome, let noneValue):
                let checkpoint = input.checkpoint
                // Pre-allocate the none value in the arena
                let noneHandle = arena.allocate(noneValue)
                try! frames.push(.optional(savedCheckpoint: checkpoint, wrapSome: wrapSome, noneHandle: noneHandle))
                current = child

            case .ref(let target):
                if let limit = maxDepth, depth >= limit {
                    let error = Parsing.Machine.Runtime.Error.depthExceeded(limit: limit)
                    switch try handleFailure(
                        error: error,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth
                    ) {
                    case .continueWith(let recovered):
                        current = Node.ID(recovered.rawValue)
                    case .handleReady(let handle):
                        pendingHandle = handle
                    case .propagate:
                        fatalError("Depth exceeded with no handler")
                    }
                } else {
                    depth += 1
                    try! frames.push(.recursiveExit)
                    current = target
                    checkInvariants("after-ref-enter")
                }

            case .hole:
                fatalError("Unpatched hole in program")
            }
        }
    }

    @usableFromInline
    func handleFailure<E: Error>(
        error: E,
        frames: inout Stack<Parsing.Machine.Frame<Input, Failure>>,
        arena: inout Parsing.Machine.Value.Arena,
        input: inout Input,
        depth: inout Int
    ) throws(Failure) -> Parsing.Machine.Failure.Recovery {
        typealias Recovery = Parsing.Machine.Failure.Recovery

        while let frame = frames.pop() {
            switch frame {
            case .oneOf(let alternatives, let index, let savedCheckpoint):
                if index < alternatives.count {
                    input.restore(to: savedCheckpoint)
                    try! frames.push(.oneOf(
                        alternatives: alternatives,
                        index: index + 1,
                        savedCheckpoint: savedCheckpoint
                    ))
                    return .continueWith(Recovery.ID(alternatives[index].rawValue))
                }

            case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                input.restore(to: savedCheckpoint)
                // Collect values from handles
                var results: [Parsing.Machine.Value] = []
                results.reserveCapacity(resultHandles.count)
                for handle in resultHandles {
                    results.append(arena.release(handle))
                }
                let finalValue = finalize.finalize(results)
                let handle = arena.allocate(finalValue)
                return .handleReady(handle)

            case .optional(let savedCheckpoint, _, let noneHandle):
                input.restore(to: savedCheckpoint)
                // noneHandle already contains the none value
                return .handleReady(noneHandle)

            case .recursiveExit:
                depth -= 1

            case .memoization:
                fatalError("Memoization frame in non-memoized execution")

            case .map, .tryMap, .flatMap, .sequence:
                continue
            }
        }
        return .propagate
    }
}
