//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

/// wrapper for an asynchronous computation that eventually returns a value of type `A`; similar to a promise, but more lightweight. The argument to `next` represents the “continuation” of the computation, to be called once the asynchronous portion returns an `A`.
/// To extend an asynchronous computation with an additional synchronous computation, use `Cont.map(_:)`. To extend an asynchronous computation with an additional asynchronous computation, use `Cont.flatMap(_:)`.
public struct Cont<A> {
    let next: (@escaping (A) -> Void) -> Void
}

public extension Cont {
    func run() {
        next { _ in }
    }
}

// MARK: - functor

public extension Cont {
    func map<B>(_ transform: @escaping (A) -> B) -> Cont<B> {
        return .init { callback in
            self.next { value in
                callback(transform(value))
            }
        }
    }
}

// MARK: - applicative

public func pure<A>(_ value: A) -> Cont<A> {
    return .init { $0(value) }
}

public func <*><A, B>(_ transform: Cont<(A) -> B>, _ value: Cont<A>) -> Cont<B> {
    return transform >>- { f in
        value >>- { a in
            pure(f(a))
        }
    }
}

public func <*<A, B>(_ lhs: Cont<A>, _ rhs: Cont<B>) -> Cont<A> {
    return pure(curry(const)) <*> lhs <*> rhs
}

public func *><A, B>(_ lhs: Cont<A>, _ rhs: Cont<B>) -> Cont<B> {
    return pure(curry(flip(const))) <*> lhs <*> rhs
}

public func liftA<A, B, C>(_ f: @escaping (A) -> (B) -> C, _ first: Cont<A>, _ second: Cont<B>) -> Cont<C> {
    return pure(f) <*> first <*> second
}

public func liftA<A, B, C>(_ f: @escaping (A, B) -> C, _ first: Cont<A>, _ second: Cont<B>) -> Cont<C> {
    return liftA(curry(f), first, second)
}

public func liftA<A, B, C, D>(_ f: @escaping (A) -> (B) -> (C) -> D, _ first: Cont<A>, _ second: Cont<B>, _ third: Cont<C>) -> Cont<D> {
    return pure(f) <*> first <*> second <*> third
}

public func liftA<A, B, C, D>(_ f: @escaping (A, B, C) -> D, _ first: Cont<A>, _ second: Cont<B>, _ third: Cont<C>) -> Cont<D> {
    return liftA(curry(f), first, second, third)
}

// MARK: - monad

public extension Cont {
    func flatMap<B>(_ transform: @escaping (A) -> Cont<B>) -> Cont<B> {
        return .init { callback in
            self.next { value in
                transform(value).next { innerValue in
                    callback(innerValue)
                }
            }
        }
    }
}

public func >>-<A, B>(_ lhs: Cont<A>, _ rhs: @escaping (A) -> Cont<B>) -> Cont<B> {
    return lhs.flatMap(rhs)
}
