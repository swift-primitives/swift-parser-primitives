//
//  Machine.Run.Memoization.swift
//  swift-parser-primitives
//
//  Memoized program execution.
//

import Parser_Primitives
public import Stack_Primitives
public import Slab_Primitives
public import Identity_Primitives
public import Machine_Primitives

extension Parser.Machine {
    /// Executes the program with memoization.
    ///
    /// Caches parse results at each (position, node) pair,
    /// enabling linear-time parsing and incremental re-parsing.
    @usableFromInline
    static func run<Input, Output, Failure>(
        program: Program<Input, Failure>,
        root: Node<Input, Failure>.ID,
        input: inout Input,
        memoization: inout Memoization.Table<Input.Checkpoint>,
        as outputType: Output.Type
    ) throws(Failure) -> Output
    where Input: Parser.Input & Sendable,
          Input.Checkpoint: Hashable,
          Failure: Error & Sendable
    {
        typealias Value = Parser.Machine.Value
        typealias Frame = Parser.Machine.Frame<Input, Failure>
        typealias Node = Parser.Machine.Node<Input, Failure>
        typealias Recovery = Parser.Machine.Failure.Recovery
        typealias MemoKey = Parser.Machine.Memoization.Key<Input.Checkpoint>
        typealias MemoEntry = Parser.Machine.Memoization.Entry<Input.Checkpoint>

        var current = root
        // Pre-allocate stack capacity based on maxDepth or reasonable default.
        // The 4x multiplier accounts for worst-case frame usage per recursion level:
        // - 1 recursiveExit frame per level
        // - Up to 3 additional frames for combinator chains (sequence, map, oneOf, etc.)
        let stackCapacity = (program.maxDepth ?? 10000) * 4
        var frames: Stack<Frame>
        do {
            frames = try Stack<Frame>(capacity: stackCapacity)
        } catch {
            fatalError("Failed to allocate frame stack with capacity \(stackCapacity): \(error)")
        }

        let arenaCapacity = stackCapacity * 2
        var arena: Value.Arena
        do {
            arena = try Value.Arena(capacity: arenaCapacity)
        } catch {
            fatalError("Failed to allocate value arena with capacity \(arenaCapacity): \(error)")
        }

        var depth = 0
        var pendingHandle: Value.Handle? = nil

        func handleMemoizedFailure<E: Error>(
            error: E,
            frames: inout Stack<Frame>,
            arena: inout Value.Arena,
            input: inout Input,
            depth: inout Int,
            memoization: inout Memoization.Table<Input.Checkpoint>
        ) throws(Failure) -> Recovery {
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
                        return .continueWith(Recovery.ID(rawValue: alternatives[index].rawValue))
                    }

                case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                    input.restore(to: savedCheckpoint)
                    var results: [Value] = []
                    results.reserveCapacity(resultHandles.count)
                    for handle in resultHandles {
                        results.append(arena.release(handle))
                    }
                    let finalValue = finalize.finalize(results)
                    let handle = arena.allocate(finalValue)
                    return .handleReady(handle)

                case .optional(let savedCheckpoint, _, let noneHandle):
                    input.restore(to: savedCheckpoint)
                    return .handleReady(noneHandle)

                case .recursiveExit:
                    depth -= 1

                case .extra(.memoization(let node, let startPosition)):
                    let key = MemoKey(position: startPosition, node: node)
                    memoization.store(.failure, for: key)

                case .map, .tryMap, .flatMap, .sequence:
                    continue
                }
            }
            return .propagate
        }

        while true {
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
                        switch try handleMemoizedFailure(
                            error: error,
                            frames: &frames,
                            arena: &arena,
                            input: &input,
                            depth: &depth,
                            memoization: &memoization
                        ) {
                        case .continueWith(let recovered):
                            current = Node.ID(recovered.rawValue)
                        case .handleReady(let recoveredHandle):
                            pendingHandle = recoveredHandle
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
                    _ = arena.release(noneHandle)
                    let wrapped = wrapSome.apply(value)
                    pendingHandle = arena.allocate(wrapped)

                case .recursiveExit:
                    depth -= 1
                    pendingHandle = arena.allocate(value)

                case .extra(.memoization(let node, let startPosition)):
                    // Cache the successful result
                    let key = MemoKey(position: startPosition, node: node)
                    let entry = MemoEntry.success(output: value, end: input.checkpoint)
                    memoization.store(entry, for: key)
                    pendingHandle = arena.allocate(value)
                }

                continue
            }

            // Check memoization before executing node
            let memoKey = MemoKey(position: input.checkpoint, node: current.rawValue)
            if let cached = memoization.lookup(memoKey) {
                switch cached {
                case .success(let output, let endPosition):
                    // Cache hit: use cached result
                    input.restore(to: endPosition)
                    pendingHandle = arena.allocate(output)
                    continue
                case .failure:
                    // Cached failure: propagate through failure handling
                    switch try handleMemoizedFailure(
                        error: Parser.Machine.Runtime.Error.cachedFailure,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth,
                        memoization: &memoization
                    ) {
                    case .continueWith(let recovered):
                        current = Node.ID(recovered.rawValue)
                        continue
                    case .handleReady(let handle):
                        pendingHandle = handle
                        continue
                    case .propagate:
                        fatalError("Cached failure with no recovery")
                    }
                }
            }

            // Cache miss: push memoization frame and execute
            try! frames.push(.extra(.memoization(node: current.rawValue, startPosition: input.checkpoint)))

            let node = program[current]

            switch node {
            case .leaf(let leaf):
                do {
                    let value = try leaf.run(&input)
                    pendingHandle = arena.allocate(value)
                } catch {
                    switch try handleMemoizedFailure(
                        error: error,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth,
                        memoization: &memoization
                    ) {
                    case .continueWith(let recovered):
                        current = Node.ID(recovered.rawValue)
                    case .handleReady(let handle):
                        pendingHandle = handle
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
                let noneHandle = arena.allocate(noneValue)
                try! frames.push(.optional(savedCheckpoint: checkpoint, wrapSome: wrapSome, noneHandle: noneHandle))
                current = child

            case .ref(let target):
                if let limit = program.maxDepth, depth >= limit {
                    let error = Parser.Machine.Runtime.Error.depthExceeded(limit: limit)
                    switch try handleMemoizedFailure(
                        error: error,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth,
                        memoization: &memoization
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
                }

            case .hole:
                fatalError("Unpatched hole in program")
            }
        }
    }
}
