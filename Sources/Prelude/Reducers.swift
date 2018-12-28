//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

/// a struct that wraps a function suitable for passing to the `updateAccumulatingResult:` parameter of `Sequence.reduce(into:_:)`
public struct Reducer<A, X> {
    public let updateAccumulatingResult: (inout A, X) -> Void

    public init(_ updateAccumulatingResult: @escaping (inout A, X) -> Void) {
        self.updateAccumulatingResult = updateAccumulatingResult
    }
}

public extension Reducer {
    /// get this reducer’s reduction function in “immutable” form (for example, to pass it to `Sequence.reduce(_:_:)`)
    public var next: (A, X) -> A {
        return { result, element in
            var copy = result
            self.updateAccumulatingResult(&copy, element)
            return copy
        }
    }

    /// create a new reducer based on an “immutable” reduction function — a function where the accumulator is not mutable. When possible, create “mutable”/`inout` reducers instead, using the `Reducer` initializer
    ///
    /// - Parameter nextPartialResult: a reduction function where the accumulator is immutable
    /// - Returns: a `Reducer` wrapping that function
    public static func nextPartialResult(_ nextPartialResult: @escaping (A, X) -> A) -> Reducer<A, X> {
        return .init { result, element in
            result = nextPartialResult(result, element)
        }
    }
}

public extension Reducer {
    /// given two reducers (`self` and `nextReducer`) of the same type, produce a new reducer that consists of running the provided two, in sequence
    ///
    /// - Parameter nextReducer: the reducer to “append” to this one
    /// - Returns: a new reducer that performs the effects of `self` and `nextReducer` in sequence
    func followed(by nextReducer: Reducer<A, X>) -> Reducer<A, X> {
        return .init { result, element in
            self.updateAccumulatingResult(&result, element)
            nextReducer.updateAccumulatingResult(&result, element)
        }
    }

    /// pullback (contravariant `map`) for reducers. Given a reducer that consumes values of type `X`, and a transform function `(Y) -> X`, return a new reducer that consumes values of type `Y`
    ///
    /// - Parameter transform: a transform function of the type `(Y) -> X`
    /// - Returns: a new reducer that consumes values of type `Y`
    func pullback<Y>(_ transform: @escaping (Y) -> X) -> Reducer<A, Y> {
        return .init { result, element in
            return self.updateAccumulatingResult(&result, transform(element))
        }
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
    public static var empty: Reducer<A, X> {
        return .init { _, _ in }
    }

    /// `Semigroup` combine for reducers. Two reducers could be said to be combined by wrapping them in a new reducer that runs each of their reduction operations in sequence
    ///
    /// - Parameters:
    ///   - lhs: a reducer
    ///   - rhs: another reducer
    /// - Returns: a reducer that for each input, first runs `lhs`, then runs `rhs`
    public static func <><A, X>(_ lhs: Reducer<A, X>, _ rhs: Reducer<A, X>) -> Reducer<A, X> {
        return lhs.followed(by: rhs)
    }
}
