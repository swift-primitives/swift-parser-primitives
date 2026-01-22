// Binary.Bytes.withBorrowed.swift
// Zero-copy borrowed parsing APIs with inlined interpreter

public import Machine_Primitives
public import Serialization_Primitives
import Standard_Library_Extensions
//
// ## Design Note
//
// The interpreter is LITERALLY inlined into each `withBorrowed` overload.
// This is required because Swift 6.x's lifetime checker sees ANY function
// call with `inout Input.View` as a potential escape.
//
// CRITICAL: NO COMPUTED PROPERTY READS on Input.View inside the interpreter.
// The lifetime checker cannot reason through computed property accessors in
// complex control flow. Track position externally via local counters.
//
// Allowed operations on view:
// - removeFirst() / removeFirst(n) - mutating consumption
// - subscript(offset:) - peek without consuming
// - position = x - write for backtracking (writes appear to be okay)
//
// Forbidden operations on view inside interpreter:
// - consumedCount, count, isEmpty, first (computed properties)

// MARK: - WithBorrowed Accessor Type

extension Binary.Bytes {
    /// Accessor for zero-copy borrowed parsing.
    @inlinable
    public static var withBorrowed: WithBorrowed { WithBorrowed() }

    /// Accessor type for borrowed parsing operations.
    public struct WithBorrowed: Sendable {
        @inlinable
        public init() {}
    }
}

// MARK: - WithBorrowed Array Methods

extension Binary.Bytes.WithBorrowed {
    /// Execute a machine parser on borrowed bytes from an array.
    @inlinable
    public func callAsFunction<Output>(
        _ bytes: [UInt8],
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> Output {
        try Binary.Bytes._withBorrowedPrefix(bytes, parser).value
    }

    /// Execute a machine parser, returning value and consumed count.
    @inlinable
    public func prefix<Output: Sendable>(
        _ bytes: [UInt8],
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> Serialization.Parsing.Prefix.Result<Output> {
        let r = try Binary.Bytes._withBorrowedPrefix(bytes, parser)
        return Serialization.Parsing.Prefix.Result(value: r.value, count: r.count)
    }

    /// Execute a machine parser, returning value and consumed count (unconstrained).
    @inlinable
    public func prefixUnchecked<Output>(
        _ bytes: [UInt8],
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> (value: Output, count: Int) {
        try Binary.Bytes._withBorrowedPrefix(bytes, parser)
    }

    /// Execute a machine parser requiring all input to be consumed.
    ///
    /// This method parses the input and verifies that no bytes remain.
    /// If any bytes remain after parsing, throws `.expectedEnd`.
    ///
    /// - Parameters:
    ///   - bytes: The bytes to parse.
    ///   - parser: The parser to execute.
    /// - Returns: The parsed value.
    /// - Throws: `Machine.Fault` if parsing fails or input remains.
    @inlinable
    public func whole<Output>(
        _ bytes: [UInt8],
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> Output {
        let total = bytes.count
        let (value, consumed) = try Binary.Bytes._withBorrowedPrefix(bytes, parser)
        let remaining = total - consumed
        guard remaining == 0 else {
            throw Binary.Bytes.Machine.Fault.expectedEnd(remaining: remaining)
        }
        return value
    }
}

// MARK: - WithBorrowed Contiguous Methods

extension Binary.Bytes.WithBorrowed {
    /// Execute a machine parser on borrowed contiguous storage.
    @inlinable
    public func callAsFunction<C: Binary.Contiguous, Output>(
        _ source: borrowing C,
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> Output where C: ~Copyable {
        try Binary.Bytes._withBorrowedPrefixContiguous(source, parser).value
    }

    /// Execute a machine parser on contiguous storage, returning value and consumed count.
    @inlinable
    public func prefix<C: Binary.Contiguous, Output: Sendable>(
        _ source: borrowing C,
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> Serialization.Parsing.Prefix.Result<Output> where C: ~Copyable {
        let r = try Binary.Bytes._withBorrowedPrefixContiguous(source, parser)
        return Serialization.Parsing.Prefix.Result(value: r.value, count: r.count)
    }

    /// Execute a machine parser on contiguous storage, returning value and consumed count (unconstrained).
    @inlinable
    public func prefixUnchecked<C: Binary.Contiguous, Output>(
        _ source: borrowing C,
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> (value: Output, count: Int) where C: ~Copyable {
        try Binary.Bytes._withBorrowedPrefixContiguous(source, parser)
    }

    /// Execute a machine parser on contiguous storage requiring all input to be consumed.
    ///
    /// This method parses the input and verifies that no bytes remain.
    /// If any bytes remain after parsing, throws `.expectedEnd`.
    ///
    /// - Parameters:
    ///   - source: The contiguous storage to parse.
    ///   - parser: The parser to execute.
    /// - Returns: The parsed value.
    /// - Throws: `Machine.Fault` if parsing fails or input remains.
    @inlinable
    public func whole<C: Binary.Contiguous, Output>(
        _ source: borrowing C,
        _ parser: Binary.Bytes.Machine.Parser<Output>
    ) throws(Binary.Bytes.Machine.Fault) -> Output where C: ~Copyable {
        let total = source.bytes.count
        let (value, consumed) = try Binary.Bytes._withBorrowedPrefixContiguous(source, parser)
        let remaining = total - consumed
        guard remaining == 0 else {
            throw Binary.Bytes.Machine.Fault.expectedEnd(remaining: remaining)
        }
        return value
    }
}

// MARK: - Borrowed APIs (Machine-based, canonical)

extension Binary.Bytes {
    /// Execute a machine parser on borrowed bytes from an array.
    @inlinable
    public static func withBorrowed<Output>(
        _ bytes: [UInt8],
        _ parser: Machine.Parser<Output>
    ) throws(Machine.Fault) -> Output {
        try _withBorrowedPrefix(bytes, parser).value
    }

    /// Internal engine returning both output and consumed count.
    @inlinable
    static func _withBorrowedPrefix<Output>(
        _ bytes: [UInt8],
        _ parser: Machine.Parser<Output>
    ) throws(Machine.Fault) -> (value: Output, count: Int) {
        try unsafe bytes.withUnsafeBufferPointer { buffer throws(Machine.Fault) -> (value: Output, count: Int) in
            let total = buffer.count
            let span = unsafe Span(
                _unsafeStart: buffer.baseAddress ?? UnsafePointer<UInt8>(bitPattern: 1)!,
                count: buffer.count
            )
            var view = Input.View(span)

            typealias Value = Machine.Value
        typealias Frame = Machine.Frame
        typealias Node = Machine.Node
        typealias Fault = Machine.Fault

        let program = parser.program
        var current = parser.root
        let stackCapacity = (program.maxDepth ?? 1000) * 4
        var frames: [Frame] = []
        frames.reserveCapacity(stackCapacity)

        var arena = Value.Arena(capacity: stackCapacity * 2)
        var depth = 0
        var pendingHandle: Value.Handle? = nil
        var instructionError: Fault? = nil

        // Track position externally - avoid reading view.consumedCount
        var consumed = 0

        interpreterLoop: while true {
            // Handle pending value
            if let handle = pendingHandle {
                pendingHandle = nil
                let value = arena.release(handle)

                if frames.isEmpty {
                    guard let result = value.take(Output.self) else {
                        fatalError("Machine output type mismatch")
                    }
                    return (value: result, count: consumed)
                }

                let frame = frames.removeLast()

                switch frame {
                case .map(let transform):
                    pendingHandle = arena.allocate(transform.apply(using: program.captures, value))

                case .tryMap(let transform):
                    do throws(Fault) {
                        pendingHandle = arena.allocate(try transform.apply(using: program.captures, value))
                    } catch {
                        instructionError = error
                    }

                case .sequence(.second(let b, let combine)):
                    frames.append(.sequence(.combine(firstHandle: arena.allocate(value), combine: combine)))
                    current = b
                    continue interpreterLoop

                case .sequence(.combine(let firstHandle, let combine)):
                    pendingHandle = arena.allocate(combine.combine(using: program.captures, arena.release(firstHandle), value))

                case .oneOf:
                    pendingHandle = arena.allocate(value)

                case .many(let child, _, var resultHandles, let finalize):
                    resultHandles.append(arena.allocate(value))
                    // Use local consumed instead of view.consumedCount
                    frames.append(.many(child: child, savedCheckpoint: consumed, resultHandles: resultHandles, finalize: finalize))
                    current = child
                    continue interpreterLoop

                case .fold(let child, _, let accHandle, let combine):
                    let acc = arena.release(accHandle)
                    let newAcc = combine.combine(using: program.captures, acc, value)
                    frames.append(.fold(child: child, savedCheckpoint: consumed, accumulatorHandle: arena.allocate(newAcc), combine: combine))
                    current = child
                    continue interpreterLoop

                case .optional(_, let wrapSome, let noneHandle):
                    _ = arena.release(noneHandle)
                    pendingHandle = arena.allocate(wrapSome.apply(using: program.captures, value))

                case .recursiveExit:
                    depth -= 1
                    pendingHandle = arena.allocate(value)

                case .flatMap(let next):
                    current = next.next(using: program.captures, value)
                    continue interpreterLoop

                case .extra(let never):
                    switch never {}
                }

                if instructionError == nil {
                    continue interpreterLoop
                }
            }

            // Handle error recovery
            if let error = instructionError {
                instructionError = nil
                var recovered = false
                while let recoveryFrame = frames.popLast() {
                    switch recoveryFrame {
                    case .oneOf(let alternatives, let index, let savedCheckpoint):
                        if index < alternatives.count {
                            // Restore position via write (writes are okay)
                            view.position = savedCheckpoint
                            consumed = savedCheckpoint
                            frames.append(.oneOf(alternatives: alternatives, index: index + 1, savedCheckpoint: savedCheckpoint))
                            current = alternatives[index]
                            recovered = true
                        }
                    case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                        view.position = savedCheckpoint
                        consumed = savedCheckpoint
                        var results: [Value] = []
                        results.reserveCapacity(resultHandles.count)
                        for h in resultHandles { results.append(arena.release(h)) }
                        pendingHandle = arena.allocate(finalize.finalize(using: program.captures, results))
                        recovered = true
                    case .fold(_, let savedCheckpoint, let accHandle, _):
                        view.position = savedCheckpoint
                        consumed = savedCheckpoint
                        pendingHandle = accHandle
                        recovered = true
                    case .optional(let savedCheckpoint, _, let noneHandle):
                        view.position = savedCheckpoint
                        consumed = savedCheckpoint
                        pendingHandle = noneHandle
                        recovered = true
                    case .recursiveExit:
                        depth -= 1
                    case .map, .tryMap, .flatMap, .sequence, .extra:
                        continue
                    }
                    if recovered { break }
                }
                if !recovered { throw error }
                continue interpreterLoop
            }

            // Execute current node
            let node = program[current]

            switch node {
            case .leaf(let instruction):
                // Compute remaining from locals (avoid view.count)
                let remaining = total - consumed

                switch instruction {
                case .take1:
                    if remaining < 1 {
                        instructionError = .insufficientBytes(need: 1, have: remaining)
                    } else {
                        let byte = view.removeFirst()
                        consumed += 1
                        pendingHandle = arena.allocate(Value.make(byte))
                    }
                case .take(let n):
                    if remaining < n {
                        instructionError = .insufficientBytes(need: n, have: remaining)
                    } else {
                        var bytes: [UInt8] = []
                        bytes.reserveCapacity(n)
                        for _ in 0..<n {
                            bytes.append(view.removeFirst())
                            consumed += 1
                        }
                        pendingHandle = arena.allocate(Value.make(bytes))
                    }
                case .skip(let n):
                    if remaining < n {
                        instructionError = .insufficientBytes(need: n, have: remaining)
                    } else {
                        view.removeFirst(n)
                        consumed += n
                        pendingHandle = arena.allocate(Value.make(()))
                    }
                case .peek:
                    // Use subscript instead of view.first
                    let byte: UInt8? = remaining > 0 ? view[offset: 0] : nil
                    pendingHandle = arena.allocate(Value.make(byte))
                case .byte(let expected):
                    if remaining < 1 {
                        instructionError = .unexpectedByte(expected: expected, found: nil)
                    } else {
                        let found = view[offset: 0]
                        if found == expected {
                            _ = view.removeFirst()
                            consumed += 1
                            pendingHandle = arena.allocate(Value.make(expected))
                        } else {
                            instructionError = .unexpectedByte(expected: expected, found: found)
                        }
                    }
                case .bytes(let expected):
                    if remaining < expected.count {
                        var found: [UInt8] = []
                        for i in 0..<remaining { found.append(view[offset: i]) }
                        instructionError = .unexpectedBytes(expected: expected, found: found)
                    } else {
                        var mismatch = false
                        for (i, expectedByte) in expected.enumerated() {
                            if view[offset: i] != expectedByte {
                                var found: [UInt8] = []
                                for j in 0..<expected.count where j < remaining { found.append(view[offset: j]) }
                                instructionError = .unexpectedBytes(expected: expected, found: found)
                                mismatch = true
                                break
                            }
                        }
                        if !mismatch {
                            view.removeFirst(expected.count)
                            consumed += expected.count
                            pendingHandle = arena.allocate(Value.make(expected))
                        }
                    }
                case .satisfy(let predicate):
                    if remaining < 1 {
                        instructionError = .insufficientBytes(need: 1, have: remaining)
                    } else {
                        let byte = view[offset: 0]
                        if predicate(byte) {
                            _ = view.removeFirst()
                            consumed += 1
                            pendingHandle = arena.allocate(Value.make(byte))
                        } else {
                            instructionError = .predicateFailed(byte: byte)
                        }
                    }
                case .takeWhile(let predicate):
                    var bytes: [UInt8] = []
                    while consumed < total {
                        let byte = view[offset: 0]
                        if predicate(byte) {
                            bytes.append(view.removeFirst())
                            consumed += 1
                        } else {
                            break
                        }
                    }
                    pendingHandle = arena.allocate(Value.make(bytes))
                case .skipWhile(let predicate):
                    while consumed < total {
                        let byte = view[offset: 0]
                        if predicate(byte) {
                            _ = view.removeFirst()
                            consumed += 1
                        } else {
                            break
                        }
                    }
                    pendingHandle = arena.allocate(Value.make(()))
                case .end:
                    if remaining == 0 {
                        pendingHandle = arena.allocate(Value.make(()))
                    } else {
                        instructionError = .expectedEnd(remaining: remaining)
                    }
                case .require(let n):
                    if remaining >= n {
                        pendingHandle = arena.allocate(Value.make(()))
                    } else {
                        instructionError = .insufficientBytes(need: n, have: remaining)
                    }
                case .u8:
                    if remaining < 1 {
                        instructionError = .insufficientBytes(need: 1, have: remaining)
                    } else {
                        let byte = view.removeFirst()
                        consumed += 1
                        pendingHandle = arena.allocate(Value.make(byte))
                    }
                case .u16le:
                    if remaining < 2 {
                        instructionError = .insufficientBytes(need: 2, have: remaining)
                    } else {
                        let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst())
                        consumed += 2
                        pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8)))
                    }
                case .u16be:
                    if remaining < 2 {
                        instructionError = .insufficientBytes(need: 2, have: remaining)
                    } else {
                        let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst())
                        consumed += 2
                        pendingHandle = arena.allocate(Value.make((b0 << 8) | b1))
                    }
                case .u32le:
                    if remaining < 4 {
                        instructionError = .insufficientBytes(need: 4, have: remaining)
                    } else {
                        let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst())
                        let b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst())
                        consumed += 4
                        pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)))
                    }
                case .u32be:
                    if remaining < 4 {
                        instructionError = .insufficientBytes(need: 4, have: remaining)
                    } else {
                        let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst())
                        let b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst())
                        consumed += 4
                        pendingHandle = arena.allocate(Value.make((b0 << 24) | (b1 << 16) | (b2 << 8) | b3))
                    }
                case .u64le:
                    if remaining < 8 {
                        instructionError = .insufficientBytes(need: 8, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        for i in 0..<8 { result |= UInt64(view.removeFirst()) << (i * 8) }
                        consumed += 8
                        pendingHandle = arena.allocate(Value.make(result))
                    }
                case .u64be:
                    if remaining < 8 {
                        instructionError = .insufficientBytes(need: 8, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        for _ in 0..<8 { result = (result << 8) | UInt64(view.removeFirst()) }
                        consumed += 8
                        pendingHandle = arena.allocate(Value.make(result))
                    }
                case .i8:
                    if remaining < 1 {
                        instructionError = .insufficientBytes(need: 1, have: remaining)
                    } else {
                        let byte = view.removeFirst()
                        consumed += 1
                        pendingHandle = arena.allocate(Value.make(Int8(bitPattern: byte)))
                    }
                case .i16le:
                    if remaining < 2 {
                        instructionError = .insufficientBytes(need: 2, have: remaining)
                    } else {
                        let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst())
                        consumed += 2
                        pendingHandle = arena.allocate(Value.make(Int16(bitPattern: b0 | (b1 << 8))))
                    }
                case .i16be:
                    if remaining < 2 {
                        instructionError = .insufficientBytes(need: 2, have: remaining)
                    } else {
                        let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst())
                        consumed += 2
                        pendingHandle = arena.allocate(Value.make(Int16(bitPattern: (b0 << 8) | b1)))
                    }
                case .i32le:
                    if remaining < 4 {
                        instructionError = .insufficientBytes(need: 4, have: remaining)
                    } else {
                        let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst())
                        let b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst())
                        consumed += 4
                        pendingHandle = arena.allocate(Value.make(Int32(bitPattern: b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))))
                    }
                case .i32be:
                    if remaining < 4 {
                        instructionError = .insufficientBytes(need: 4, have: remaining)
                    } else {
                        let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst())
                        let b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst())
                        consumed += 4
                        pendingHandle = arena.allocate(Value.make(Int32(bitPattern: (b0 << 24) | (b1 << 16) | (b2 << 8) | b3)))
                    }
                case .i64le:
                    if remaining < 8 {
                        instructionError = .insufficientBytes(need: 8, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        for i in 0..<8 { result |= UInt64(view.removeFirst()) << (i * 8) }
                        consumed += 8
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }
                case .i64be:
                    if remaining < 8 {
                        instructionError = .insufficientBytes(need: 8, have: remaining)
                    } else {
                        var result: UInt64 = 0
                        for _ in 0..<8 { result = (result << 8) | UInt64(view.removeFirst()) }
                        consumed += 8
                        pendingHandle = arena.allocate(Value.make(Int64(bitPattern: result)))
                    }
                case .uleb128:
                    var result: UInt64 = 0, shift: UInt64 = 0, overflow = false, done = false
                    while !done {
                        if consumed >= total {
                            instructionError = .insufficientBytes(need: 1, have: 0)
                            break
                        }
                        let byte = view.removeFirst()
                        consumed += 1
                        let byteValue = UInt64(byte & 0x7F)
                        if shift >= 64 || (shift == 63 && byteValue > 1) {
                            overflow = true
                            break
                        }
                        result |= byteValue << shift
                        if byte & 0x80 == 0 { done = true }
                        else { shift += 7 }
                    }
                    if overflow { instructionError = .leb128Overflow }
                    else if done { pendingHandle = arena.allocate(Value.make(result)) }
                case .sleb128:
                    var result: Int64 = 0, shift: UInt64 = 0, byte: UInt8 = 0, overflow = false, done = false
                    while !done {
                        if consumed >= total {
                            instructionError = .insufficientBytes(need: 1, have: 0)
                            break
                        }
                        byte = view.removeFirst()
                        consumed += 1
                        if shift >= 64 {
                            overflow = true
                            break
                        }
                        result |= Int64(byte & 0x7F) << shift
                        shift += 7
                        if byte & 0x80 == 0 { done = true }
                    }
                    if overflow { instructionError = .leb128Overflow }
                    else if done {
                        if shift < 64 && (byte & 0x40) != 0 { result |= -(1 << shift) }
                        pendingHandle = arena.allocate(Value.make(result))
                    }
                }

            case .pure(let value):
                pendingHandle = arena.allocate(value)

            case .map(let child, let transform):
                frames.append(.map(transform: transform))
                current = child

            case .tryMap(let child, let transform):
                frames.append(.tryMap(transform: transform))
                current = child

            case .flatMap(let child, let next):
                frames.append(.flatMap(next: next))
                current = child

            case .sequence(let a, let b, let combine):
                frames.append(.sequence(.second(b: b, combine: combine)))
                current = a

            case .oneOf(let alternatives):
                guard !alternatives.isEmpty else { fatalError("Empty oneOf") }
                if alternatives.count > 1 {
                    // Use local consumed instead of view.consumedCount
                    frames.append(.oneOf(alternatives: alternatives, index: 1, savedCheckpoint: consumed))
                }
                current = alternatives[0]

            case .many(let child, let finalize):
                frames.append(.many(child: child, savedCheckpoint: consumed, resultHandles: [], finalize: finalize))
                current = child

            case .fold(let child, let initial, let combine):
                frames.append(.fold(child: child, savedCheckpoint: consumed, accumulatorHandle: arena.allocate(initial), combine: combine))
                current = child

            case .optional(let child, let wrapSome, let noneValue):
                frames.append(.optional(savedCheckpoint: consumed, wrapSome: wrapSome, noneHandle: arena.allocate(noneValue)))
                current = child

            case .ref(let target):
                if let limit = program.maxDepth, depth >= limit {
                    instructionError = .depthExceeded(limit: limit)
                } else {
                    depth += 1
                    frames.append(.recursiveExit)
                    current = target
                }

            case .hole:
                fatalError("Unpatched hole in program")
            }
        }
        }
    }

    /// Execute a machine parser on borrowed bytes from contiguous storage.
    @inlinable
    public static func withBorrowed<C: Binary.Contiguous, Output>(
        _ source: borrowing C,
        _ parser: Machine.Parser<Output>
    ) throws(Machine.Fault) -> Output where C: ~Copyable {
        try _withBorrowedPrefixContiguous(source, parser).value
    }

    /// Internal engine for contiguous storage returning both output and consumed count.
    @inlinable
    static func _withBorrowedPrefixContiguous<C: Binary.Contiguous, Output>(
        _ source: borrowing C,
        _ parser: Machine.Parser<Output>
    ) throws(Machine.Fault) -> (value: Output, count: Int) where C: ~Copyable {
        let sourceBytes = source.bytes
        let total = sourceBytes.count
        var view = Input.View(sourceBytes)

        typealias Value = Machine.Value
        typealias Frame = Machine.Frame
        typealias Node = Machine.Node
        typealias Fault = Machine.Fault

        let program = parser.program
        var current = parser.root
        let stackCapacity = (program.maxDepth ?? 1000) * 4
        var frames: [Frame] = []
        frames.reserveCapacity(stackCapacity)

        var arena = Value.Arena(capacity: stackCapacity * 2)
        var depth = 0
        var pendingHandle: Value.Handle? = nil
        var instructionError: Fault? = nil
        var consumed = 0

        interpreterLoop: while true {
            if let handle = pendingHandle {
                pendingHandle = nil
                let value = arena.release(handle)

                if frames.isEmpty {
                    guard let result = value.take(Output.self) else {
                        fatalError("Machine output type mismatch")
                    }
                    return (value: result, count: consumed)
                }

                let frame = frames.removeLast()

                switch frame {
                case .map(let transform):
                    pendingHandle = arena.allocate(transform.apply(using: program.captures, value))

                case .tryMap(let transform):
                    do throws(Fault) {
                        pendingHandle = arena.allocate(try transform.apply(using: program.captures, value))
                    } catch {
                        instructionError = error
                    }

                case .sequence(.second(let b, let combine)):
                    frames.append(.sequence(.combine(firstHandle: arena.allocate(value), combine: combine)))
                    current = b
                    continue interpreterLoop

                case .sequence(.combine(let firstHandle, let combine)):
                    pendingHandle = arena.allocate(combine.combine(using: program.captures, arena.release(firstHandle), value))

                case .oneOf:
                    pendingHandle = arena.allocate(value)

                case .many(let child, _, var resultHandles, let finalize):
                    resultHandles.append(arena.allocate(value))
                    frames.append(.many(child: child, savedCheckpoint: consumed, resultHandles: resultHandles, finalize: finalize))
                    current = child
                    continue interpreterLoop

                case .fold(let child, _, let accHandle, let combine):
                    let acc = arena.release(accHandle)
                    let newAcc = combine.combine(using: program.captures, acc, value)
                    frames.append(.fold(child: child, savedCheckpoint: consumed, accumulatorHandle: arena.allocate(newAcc), combine: combine))
                    current = child
                    continue interpreterLoop

                case .optional(_, let wrapSome, let noneHandle):
                    _ = arena.release(noneHandle)
                    pendingHandle = arena.allocate(wrapSome.apply(using: program.captures, value))

                case .recursiveExit:
                    depth -= 1
                    pendingHandle = arena.allocate(value)

                case .flatMap(let next):
                    current = next.next(using: program.captures, value)
                    continue interpreterLoop

                case .extra(let never):
                    switch never {}
                }

                if instructionError == nil {
                    continue interpreterLoop
                }
            }

            if let error = instructionError {
                instructionError = nil
                var recovered = false
                while let recoveryFrame = frames.popLast() {
                    switch recoveryFrame {
                    case .oneOf(let alternatives, let index, let savedCheckpoint):
                        if index < alternatives.count {
                            view.position = savedCheckpoint
                            consumed = savedCheckpoint
                            frames.append(.oneOf(alternatives: alternatives, index: index + 1, savedCheckpoint: savedCheckpoint))
                            current = alternatives[index]
                            recovered = true
                        }
                    case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                        view.position = savedCheckpoint
                        consumed = savedCheckpoint
                        var results: [Value] = []
                        results.reserveCapacity(resultHandles.count)
                        for h in resultHandles { results.append(arena.release(h)) }
                        pendingHandle = arena.allocate(finalize.finalize(using: program.captures, results))
                        recovered = true
                    case .fold(_, let savedCheckpoint, let accHandle, _):
                        view.position = savedCheckpoint
                        consumed = savedCheckpoint
                        pendingHandle = accHandle
                        recovered = true
                    case .optional(let savedCheckpoint, _, let noneHandle):
                        view.position = savedCheckpoint
                        consumed = savedCheckpoint
                        pendingHandle = noneHandle
                        recovered = true
                    case .recursiveExit:
                        depth -= 1
                    case .map, .tryMap, .flatMap, .sequence, .extra:
                        continue
                    }
                    if recovered { break }
                }
                if !recovered { throw error }
                continue interpreterLoop
            }

            let node = program[current]

            switch node {
            case .leaf(let instruction):
                let remaining = total - consumed

                switch instruction {
                case .take1:
                    if remaining < 1 { instructionError = .insufficientBytes(need: 1, have: remaining) }
                    else { let b = view.removeFirst(); consumed += 1; pendingHandle = arena.allocate(Value.make(b)) }
                case .take(let n):
                    if remaining < n { instructionError = .insufficientBytes(need: n, have: remaining) }
                    else {
                        var bytes: [UInt8] = []
                        bytes.reserveCapacity(n)
                        for _ in 0..<n { bytes.append(view.removeFirst()); consumed += 1 }
                        pendingHandle = arena.allocate(Value.make(bytes))
                    }
                case .skip(let n):
                    if remaining < n { instructionError = .insufficientBytes(need: n, have: remaining) }
                    else { view.removeFirst(n); consumed += n; pendingHandle = arena.allocate(Value.make(())) }
                case .peek:
                    let byte: UInt8? = remaining > 0 ? view[offset: 0] : nil
                    pendingHandle = arena.allocate(Value.make(byte))
                case .byte(let expected):
                    if remaining < 1 { instructionError = .unexpectedByte(expected: expected, found: nil) }
                    else {
                        let found = view[offset: 0]
                        if found == expected { _ = view.removeFirst(); consumed += 1; pendingHandle = arena.allocate(Value.make(expected)) }
                        else { instructionError = .unexpectedByte(expected: expected, found: found) }
                    }
                case .bytes(let expected):
                    if remaining < expected.count {
                        var found: [UInt8] = []
                        for i in 0..<remaining { found.append(view[offset: i]) }
                        instructionError = .unexpectedBytes(expected: expected, found: found)
                    } else {
                        var mismatch = false
                        for (i, expectedByte) in expected.enumerated() {
                            if view[offset: i] != expectedByte {
                                var found: [UInt8] = []
                                for j in 0..<expected.count where j < remaining { found.append(view[offset: j]) }
                                instructionError = .unexpectedBytes(expected: expected, found: found)
                                mismatch = true
                                break
                            }
                        }
                        if !mismatch { view.removeFirst(expected.count); consumed += expected.count; pendingHandle = arena.allocate(Value.make(expected)) }
                    }
                case .satisfy(let predicate):
                    if remaining < 1 { instructionError = .insufficientBytes(need: 1, have: remaining) }
                    else {
                        let byte = view[offset: 0]
                        if predicate(byte) { _ = view.removeFirst(); consumed += 1; pendingHandle = arena.allocate(Value.make(byte)) }
                        else { instructionError = .predicateFailed(byte: byte) }
                    }
                case .takeWhile(let predicate):
                    var bytes: [UInt8] = []
                    while consumed < total {
                        let byte = view[offset: 0]
                        if predicate(byte) { bytes.append(view.removeFirst()); consumed += 1 }
                        else { break }
                    }
                    pendingHandle = arena.allocate(Value.make(bytes))
                case .skipWhile(let predicate):
                    while consumed < total {
                        let byte = view[offset: 0]
                        if predicate(byte) { _ = view.removeFirst(); consumed += 1 }
                        else { break }
                    }
                    pendingHandle = arena.allocate(Value.make(()))
                case .end:
                    if remaining == 0 { pendingHandle = arena.allocate(Value.make(())) }
                    else { instructionError = .expectedEnd(remaining: remaining) }
                case .require(let n):
                    if remaining >= n { pendingHandle = arena.allocate(Value.make(())) }
                    else { instructionError = .insufficientBytes(need: n, have: remaining) }
                case .u8:
                    if remaining < 1 { instructionError = .insufficientBytes(need: 1, have: remaining) }
                    else { let b = view.removeFirst(); consumed += 1; pendingHandle = arena.allocate(Value.make(b)) }
                case .u16le:
                    if remaining < 2 { instructionError = .insufficientBytes(need: 2, have: remaining) }
                    else { let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst()); consumed += 2; pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8))) }
                case .u16be:
                    if remaining < 2 { instructionError = .insufficientBytes(need: 2, have: remaining) }
                    else { let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst()); consumed += 2; pendingHandle = arena.allocate(Value.make((b0 << 8) | b1)) }
                case .u32le:
                    if remaining < 4 { instructionError = .insufficientBytes(need: 4, have: remaining) }
                    else { let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst()), b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst()); consumed += 4; pendingHandle = arena.allocate(Value.make(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))) }
                case .u32be:
                    if remaining < 4 { instructionError = .insufficientBytes(need: 4, have: remaining) }
                    else { let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst()), b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst()); consumed += 4; pendingHandle = arena.allocate(Value.make((b0 << 24) | (b1 << 16) | (b2 << 8) | b3)) }
                case .u64le:
                    if remaining < 8 { instructionError = .insufficientBytes(need: 8, have: remaining) }
                    else { var r: UInt64 = 0; for i in 0..<8 { r |= UInt64(view.removeFirst()) << (i * 8) }; consumed += 8; pendingHandle = arena.allocate(Value.make(r)) }
                case .u64be:
                    if remaining < 8 { instructionError = .insufficientBytes(need: 8, have: remaining) }
                    else { var r: UInt64 = 0; for _ in 0..<8 { r = (r << 8) | UInt64(view.removeFirst()) }; consumed += 8; pendingHandle = arena.allocate(Value.make(r)) }
                case .i8:
                    if remaining < 1 { instructionError = .insufficientBytes(need: 1, have: remaining) }
                    else { let b = view.removeFirst(); consumed += 1; pendingHandle = arena.allocate(Value.make(Int8(bitPattern: b))) }
                case .i16le:
                    if remaining < 2 { instructionError = .insufficientBytes(need: 2, have: remaining) }
                    else { let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst()); consumed += 2; pendingHandle = arena.allocate(Value.make(Int16(bitPattern: b0 | (b1 << 8)))) }
                case .i16be:
                    if remaining < 2 { instructionError = .insufficientBytes(need: 2, have: remaining) }
                    else { let b0 = UInt16(view.removeFirst()), b1 = UInt16(view.removeFirst()); consumed += 2; pendingHandle = arena.allocate(Value.make(Int16(bitPattern: (b0 << 8) | b1))) }
                case .i32le:
                    if remaining < 4 { instructionError = .insufficientBytes(need: 4, have: remaining) }
                    else { let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst()), b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst()); consumed += 4; pendingHandle = arena.allocate(Value.make(Int32(bitPattern: b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)))) }
                case .i32be:
                    if remaining < 4 { instructionError = .insufficientBytes(need: 4, have: remaining) }
                    else { let b0 = UInt32(view.removeFirst()), b1 = UInt32(view.removeFirst()), b2 = UInt32(view.removeFirst()), b3 = UInt32(view.removeFirst()); consumed += 4; pendingHandle = arena.allocate(Value.make(Int32(bitPattern: (b0 << 24) | (b1 << 16) | (b2 << 8) | b3))) }
                case .i64le:
                    if remaining < 8 { instructionError = .insufficientBytes(need: 8, have: remaining) }
                    else { var r: UInt64 = 0; for i in 0..<8 { r |= UInt64(view.removeFirst()) << (i * 8) }; consumed += 8; pendingHandle = arena.allocate(Value.make(Int64(bitPattern: r))) }
                case .i64be:
                    if remaining < 8 { instructionError = .insufficientBytes(need: 8, have: remaining) }
                    else { var r: UInt64 = 0; for _ in 0..<8 { r = (r << 8) | UInt64(view.removeFirst()) }; consumed += 8; pendingHandle = arena.allocate(Value.make(Int64(bitPattern: r))) }
                case .uleb128:
                    var result: UInt64 = 0, shift: UInt64 = 0, overflow = false, done = false
                    while !done {
                        if consumed >= total { instructionError = .insufficientBytes(need: 1, have: 0); break }
                        let byte = view.removeFirst(); consumed += 1
                        let byteValue = UInt64(byte & 0x7F)
                        if shift >= 64 || (shift == 63 && byteValue > 1) { overflow = true; break }
                        result |= byteValue << shift
                        if byte & 0x80 == 0 { done = true } else { shift += 7 }
                    }
                    if overflow { instructionError = .leb128Overflow }
                    else if done { pendingHandle = arena.allocate(Value.make(result)) }
                case .sleb128:
                    var result: Int64 = 0, shift: UInt64 = 0, byte: UInt8 = 0, overflow = false, done = false
                    while !done {
                        if consumed >= total { instructionError = .insufficientBytes(need: 1, have: 0); break }
                        byte = view.removeFirst(); consumed += 1
                        if shift >= 64 { overflow = true; break }
                        result |= Int64(byte & 0x7F) << shift
                        shift += 7
                        if byte & 0x80 == 0 { done = true }
                    }
                    if overflow { instructionError = .leb128Overflow }
                    else if done {
                        if shift < 64 && (byte & 0x40) != 0 { result |= -(1 << shift) }
                        pendingHandle = arena.allocate(Value.make(result))
                    }
                }

            case .pure(let value):
                pendingHandle = arena.allocate(value)

            case .map(let child, let transform):
                frames.append(.map(transform: transform))
                current = child

            case .tryMap(let child, let transform):
                frames.append(.tryMap(transform: transform))
                current = child

            case .flatMap(let child, let next):
                frames.append(.flatMap(next: next))
                current = child

            case .sequence(let a, let b, let combine):
                frames.append(.sequence(.second(b: b, combine: combine)))
                current = a

            case .oneOf(let alternatives):
                guard !alternatives.isEmpty else { fatalError("Empty oneOf") }
                if alternatives.count > 1 { frames.append(.oneOf(alternatives: alternatives, index: 1, savedCheckpoint: consumed)) }
                current = alternatives[0]

            case .many(let child, let finalize):
                frames.append(.many(child: child, savedCheckpoint: consumed, resultHandles: [], finalize: finalize))
                current = child

            case .fold(let child, let initial, let combine):
                frames.append(.fold(child: child, savedCheckpoint: consumed, accumulatorHandle: arena.allocate(initial), combine: combine))
                current = child

            case .optional(let child, let wrapSome, let noneValue):
                frames.append(.optional(savedCheckpoint: consumed, wrapSome: wrapSome, noneHandle: arena.allocate(noneValue)))
                current = child

            case .ref(let target):
                if let limit = program.maxDepth, depth >= limit { instructionError = .depthExceeded(limit: limit) }
                else { depth += 1; frames.append(.recursiveExit); current = target }

            case .hole:
                fatalError("Unpatched hole in program")
            }
        }
    }
}

// MARK: - Owned APIs (copying, pass Input)

extension Binary.Bytes {
    @inlinable
    public static func withInput<T, E: Swift.Error>(
        _ bytes: [UInt8],
        _ body: (inout Input) throws(E) -> T
    ) throws(E) -> T {
        var input = Input(bytes)
        return try body(&input)
    }

    @inlinable
    public static func withInput<Bytes, T, E: Swift.Error>(
        _ bytes: Bytes,
        _ body: (inout Input) throws(E) -> T
    ) throws(E) -> T where Bytes: Collection, Bytes.Element == UInt8 {
        var input = Input(Swift.Array(bytes))
        return try body(&input)
    }

    @inlinable
    public static func withInput<T, E: Swift.Error>(
        _ string: some StringProtocol,
        _ body: (inout Input) throws(E) -> T
    ) throws(E) -> T {
        var input = Input(Swift.Array(string.utf8))
        return try body(&input)
    }
}
