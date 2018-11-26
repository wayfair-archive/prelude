//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

/// a struct that can be used to keep track of whether or not a wrapped value has been changed
public struct Changeable<A> {
    public let hasChanged: Bool
    public let value: A

    public init(hasChanged: Bool = false, value: A) {
        self.hasChanged = hasChanged
        self.value = value
    }
}

// MARK: - functor

public extension Changeable {
    /// `map` implementation for `Changeable`. Given a `Changeable` wrapper (`self`) and a transformation function that consumes the inner value (`A`), return a new `Changeable` value containing the transformed value and the current `hasChanged` flag, carried forward
    ///
    /// - Parameter transform: a transform function on `A` (the value contained by this instance)
    /// - Returns: a new `Changeable` value where `Changeable.getter:hasChanged` will be `true` if this instance has already changed
    func map<B>(_ transform: (A) -> B) -> Changeable<B> {
        return .init(hasChanged: hasChanged, value: transform(value))
    }

    /// given a `Changeable` wrapper (`self`) and a transformation function that consumes the inner value (`A`) which may fail, return a new `Changeable` value containing the transformed value and the current `hasChanged` flag, carried forward, or `nil`, if the transformation failed
    ///
    /// - Parameter transform: a failable transform function on `A` (the value contained by this instance)
    /// - Returns: a new `Changeable` value where `Changeable.getter:hasChanged` will be `true` if this instance has already changed, or `nil`, if the transformation failed
    func mapSome<B>(_ transform: (A) -> B?) -> Changeable<B>? {
        guard let nextValue = transform(value) else { return nil }
        return .init(hasChanged: hasChanged, value: nextValue)
    }
}

// MARK: - applicative

/// lift a value of type `A` into a `Changeable` context
///
/// - Parameter value: a value of type `A`
/// - Returns: a pure value of type `Changeable<A>`
public func pure<A>(_ value: A) -> Changeable<A> {
    return .init(hasChanged: false, value: value)
}

/// `<*>` for Changeable values. Given a transform function of type `Changeable<(A) -> B>` and a value of type `Changeable<A>`, return a new value of type `Changeable<B>`
///
/// - Parameters:
///   - transform: a function of type `Changeable<(A) -> B>`
///   - value: a value of type `Changeable<A>`
/// - Returns: a value of type `Changeable<B>`
public func <*><A, B>(_ transform: Changeable<(A) -> B>, _ value: Changeable<A>) -> Changeable<B> {
    return transform >>- { f in
        value >>- { a in
            pure(f(a))
        }
    }
}

/// `liftA` for Changeable values. Given a curried function of two arguments (`f`), and two `Changeable` parameters (`first` and `second`), return a new value that is the result of lifting the function and applying the two arguments in order
///
/// - Parameters:
///   - f: a curried function of two arguments (`A` and `B`)
///   - first: an argument of type `A`
///   - second: an argument of type `B`
/// - Returns: a value of type `Changeable<C>`
public func liftA<A, B, C>(_ f: @escaping (A) -> (B) -> C, _ first: Changeable<A>, _ second: Changeable<B>) -> Changeable<C> {
    return pure(f) <*> first <*> second
}

/// `liftA` for Changeable values, with built-in currying. Given a non-curried function of two arguments (`f`), and two `Changeable` parameters (`first` and `second`), return a new value that is the result of currying the function, lifting the result, and applying the two arguments in order
///
/// - Parameters:
///   - f: a function of two arguments (`A` and `B`)
///   - first: an argument of type `A`
///   - second: an argument of type `B`
/// - Returns: a value of type `Changeable<C>`
public func liftA<A, B, C>(_ f: @escaping (A, B) -> C, _ first: Changeable<A>, _ second: Changeable<B>) -> Changeable<C> {
    return liftA(curry(f), first, second)
}

/// `liftA` for Changeable values. Given a curried function of three arguments (`f`), and three `Changeable` parameters (`first`, `second`, and `third`), return a new value that is the result of lifting the function and applying the three arguments in order
///
/// - Parameters:
///   - f: a curried function of three arguments (`A`, `B`, and `C`)
///   - first: an argument of type `A`
///   - second: an argument of type `B`
///   - third: an argument of type `C`
/// - Returns: a value of type `Changeable<D>`
public func liftA<A, B, C, D>(_ f: @escaping (A) -> (B) -> (C) -> D, _ first: Changeable<A>, _ second: Changeable<B>, _ third: Changeable<C>) -> Changeable<D> {
    return pure(f) <*> first <*> second <*> third
}

/// `liftA` for Changeable values, with built-in currying. Given a non-curried function of two arguments (`f`), and three `Changeable` parameters (`first`, `second`, and `third`), return a new value that is the result of currying the function, lifting the result, and applying the three arguments in order
///
/// - Parameters:
///   - f: a function of three arguments (`A`, `B`, and `C`)
///   - first: an argument of type `A`
///   - second: an argument of type `B`
///   - third: an argument of type `C`
/// - Returns: a value of type `Changeable<D>`
public func liftA<A, B, C, D>(_ f: @escaping (A, B, C) -> D, _ first: Changeable<A>, _ second: Changeable<B>, _ third: Changeable<C>) -> Changeable<D> {
    return liftA(curry(f), first, second, third)
}

// MARK: - monad

public extension Changeable {
    /// `flatMap` implementation for `Changeable`. Given a `Changeable` wrapper (`self`) and a transformation that itself can change the contained value, return a new `Changeable` value containing the transformed value and the two `hasChanged` flags in question, coalesced
    ///
    /// - Parameter transform: a transform function on `A` (the value contained by this instance)
    /// - Returns: a new `Changeable` value where `Changeable.getter:hasChanged` will be `true` if this instance has already changed, or if the transformation itself changes the value
    func flatMap<B>(_ transform: (A) -> Changeable<B>) -> Changeable<B> {
        let next = transform(value)
        return .init(hasChanged: hasChanged || next.hasChanged, value: next.value)
    }
}

/// `>>-` (pronounced: “bind”) implemented for `Changeable` values. `>>-` is just an infix version of `flatMap` that results in less syntactic noise when chaining transformations together
///
/// - Parameters:
///   - lhs: a `Changeable` value on `A`
///   - rhs: a transform function on `A` (the value contained by `lhs`)
/// - Returns: the result of calling `flatMap` on `lhs` with `rhs`
public func >>-<A, B>(_ lhs: Changeable<A>, _ rhs: (A) -> Changeable<B>) -> Changeable<B> {
    return lhs.flatMap(rhs)
}

// MARK: - key paths

public extension Changeable {
    /// generate a transform function for a value of type `A`. The function will use `!=` to determine whether or not to write a `newValue` of type `V` at the keyPath `keyPath` in a receiver.
    /// This can be considered a generator of functions suitable for passing to `Changeable.flatMap(_:)`, so that the programmer may chain many transformations together, keeping track of whether or not changes are made as the chain of transformations are applied.
    ///
    /// - Parameters:
    ///   - newValue: the value to potentially write. This value will be written if `!=` returns `true` when evaluated with the current value of the receiver at `keyPath`, and `newValue`, as arguments
    ///   - keyPath: the keyPath at which to potentially write a new value
    /// - Returns: a function that when applied, produces a `Changeable` value where the `Changeable.getter:hasChanged` property reflects whether or not `newValue` was written, and `Changeable.getter:value` contains the potentially transformed receiver
    static func write<V>(
        _ newValue: V,
        at keyPath: WritableKeyPath<A, V>) -> (A) -> Changeable<A> where V: Equatable {
        return write(newValue, at: keyPath, shouldChange: !=)
    }

    /// generate a transform function for a value of type `A`. The function will use the binary function `shouldChange` to determine whether or not to write a `newValue` of type `V` at the keyPath `keyPath` in a receiver.
    /// This can be considered a generator of functions suitable for passing to `Changeable.flatMap(_:)`, so that the programmer may chain many transformations together, keeping track of whether or not changes are made as the chain of transformations are applied.
    ///
    /// - Parameters:
    ///   - newValue: the value to potentially write. This value will be written if `shouldChange` returns `true` when evaluated with the current value of the receiver at `keyPath`, and `newValue`, as arguments
    ///   - keyPath: the keyPath at which to potentially write a new value
    ///   - shouldChange: a binary function to determine whether `newValue` should be written. `newValue` will be written if this function returns `true` when evaluated with the current value of the receiver at `keyPath`, and `newValue`, as arguments
    /// - Returns: a function that when applied, produces a `Changeable` value where the `Changeable.getter:hasChanged` property reflects whether or not `newValue` was written, and `Changeable.getter:value` contains the potentially transformed receiver
    static func write<V>(
        _ newValue: V,
        at keyPath: WritableKeyPath<A, V>,
        shouldChange: @escaping (V, V) -> Bool) -> (A) -> Changeable<A> {
        return { receiver in
            guard shouldChange(receiver[keyPath: keyPath], newValue) else {
                return .init(hasChanged: false, value: receiver)
            }
            var next = receiver
            next[keyPath: keyPath] = newValue
            return .init(hasChanged: true, value: next)
        }
    }
}

public extension Changeable {
    mutating func write<V>(_ newValue: V, at keyPath: WritableKeyPath<A, V>) where V: Equatable {
        self = flatMap(
            Changeable.write(
                newValue,
                at: keyPath))
    }

    mutating func write<V>(
        _ newValue: V,
        at keyPath: WritableKeyPath<A, V>,
        shouldChange: @escaping (V, V) -> Bool) {
        self = flatMap(
            Changeable.write(
                newValue,
                at: keyPath,
                shouldChange: shouldChange))
    }
}
