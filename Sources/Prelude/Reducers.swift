//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

// MARK: - reducers that can return effects

public struct ReducerE<A, X, E> {
    public let updateAccumulatingResult: (inout A, X) -> E

    public init(_ updateAccumulatingResult: @escaping (inout A, X) -> E) {
        self.updateAccumulatingResult = updateAccumulatingResult
    }
}

public extension ReducerE {
    /// get this reducer’s reduction function in “immutable” form
    var next: (A, X) -> (A, E) {
        return { result, element in
            var copy = result
            let effect = self.updateAccumulatingResult(&copy, element)
            return (copy, effect)
        }
    }

    /// create a new reducer based on an “immutable” reduction function — a function where the accumulator is not mutable. When possible, create “mutable”/`inout` reducers instead, using the `ReducerE` initializer
    ///
    /// - Parameter nextPartialResult: a reduction function where the accumulator is immutable
    /// - Returns: a `Reducer` wrapping that function
    static func nextPartialResult(_ nextPartialResult: @escaping (A, X) -> (A, E)) -> ReducerE {
        .init { result, element in
            let (step, effect) = nextPartialResult(result, element)
            result = step
            return effect
        }
    }

    /// pullback (contravariant `map`) for reducers. Given a reducer that consumes values of type `X`, and a transform function `(Y) -> X`, return a new reducer that consumes values of type `Y`
    ///
    /// - Parameter transform: a transform function of the type `(Y) -> X`
    /// - Returns: a new reducer that consumes values of type `Y`
    func pullback<Y>(_ transform: @escaping (Y) -> X) -> ReducerE<A, Y, E> {
        .init { result, element in
            self.updateAccumulatingResult(&result, transform <| element)
        }
    }
}

extension ReducerE: Semigroup where E: Semigroup {
    /// `Semigroup` combine for reducers. Two reducers could be said to be combined by wrapping them in a new reducer that runs each of their reduction operations in sequence
    ///
    /// - Parameters:
    ///   - lhs: a reducer
    ///   - rhs: another reducer
    /// - Returns: a reducer that for each input, first runs `lhs`, then runs `rhs`
    public static func <>(_ lhs: ReducerE, _ rhs: ReducerE) -> ReducerE {
        .init { result, element in
            lhs.updateAccumulatingResult(&result, element)
                <> rhs.updateAccumulatingResult(&result, element)
        }
    }
}

extension ReducerE: Monoid where E: Monoid {
    /// the identity `Reducer`. This reducer ignores its parameters, performs no mutation to the accumulator, and returns the empty effect
    public static var empty: ReducerE {
        .init { _, _ in .empty }
    }
}

// MARK: - reducers without effects

/// a struct that wraps a function suitable for passing to the `updateAccumulatingResult:` parameter of `Sequence.reduce(into:_:)`
public struct Reducer<A, X> {
    fileprivate let innerReducer: ReducerE<A, X, Void>
}

public extension Reducer {
    init(_ updateAccumulatingResult: @escaping (inout A, X) -> Void) {
        self.innerReducer = .init(updateAccumulatingResult)
    }

    /// get this reducer’s reduction function in “immutable” form (for example, to pass it to `Sequence.reduce(_:_:)`)
    var next: (A, X) -> A {
        return { self.innerReducer.next($0, $1).0 }
    }

    var updateAccumulatingResult: (inout A, X) -> Void {
        innerReducer.updateAccumulatingResult
    }

    /// create a new reducer based on an “immutable” reduction function — a function where the accumulator is not mutable. When possible, create “mutable”/`inout` reducers instead, using the `Reducer` initializer
    ///
    /// - Parameter nextPartialResult: a reduction function where the accumulator is immutable
    /// - Returns: a `Reducer` wrapping that function
    static func nextPartialResult(_ nextPartialResult: @escaping (A, X) -> A) -> Reducer {
        .init { result, element in
            result = nextPartialResult(result, element)
        }
    }
}

public extension Reducer {
    /// given two reducers (`self` and `nextReducer`) of the same type, produce a new reducer that consists of running the provided two, in sequence
    ///
    /// - Parameter nextReducer: the reducer to “append” to this one
    /// - Returns: a new reducer that performs the effects of `self` and `nextReducer` in sequence
    func followed(by nextReducer: Reducer) -> Reducer {
        .init { result, element in
            self.updateAccumulatingResult(&result, element)
            nextReducer.updateAccumulatingResult(&result, element)
        }
    }

    /// pullback (contravariant `map`) for reducers. Given a reducer that consumes values of type `X`, and a transform function `(Y) -> X`, return a new reducer that consumes values of type `Y`
    ///
    /// - Parameter transform: a transform function of the type `(Y) -> X`
    /// - Returns: a new reducer that consumes values of type `Y`
    func pullback<Y>(_ transform: @escaping (Y) -> X) -> Reducer<A, Y> {
        .init(innerReducer: innerReducer.pullback(transform))
    }
}

public extension Sequence {
    func reduce<Result>(_ initialResult: Result, _ reducer: Reducer<Result, Element>) -> Result {
        return reduce(initialResult, reducer.next)
    }

    func reduce<Result>(into initialResult: Result, _ reducer: Reducer<Result, Element>) -> Result {
        return reduce(into: initialResult, reducer.updateAccumulatingResult)
    }
}

extension Reducer: Monoid {
    /// the identity `Reducer`. This reducer ignores its parameters and performs no mutation to the accumulator
    public static var empty: Reducer {
        .init { _, _ in }
    }

    /// `Semigroup` combine for reducers. Two reducers could be said to be combined by wrapping them in a new reducer that runs each of their reduction operations in sequence
    ///
    /// - Parameters:
    ///   - lhs: a reducer
    ///   - rhs: another reducer
    /// - Returns: a reducer that for each input, first runs `lhs`, then runs `rhs`
    public static func <>(_ lhs: Reducer, _ rhs: Reducer) -> Reducer {
        lhs.followed(by: rhs)
    }
}
