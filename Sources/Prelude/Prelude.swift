//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

// MARK: - utility

public func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { b in f(a, b) } }
}

public func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { a in { b in { c in f(a, b, c) } } }
}

public func curry<A, B, C, D, E>(_ f: @escaping (A, B, C, D) -> E) -> (A) -> (B) -> (C) -> (D) -> E {
    return { a in { b in { c in { d in f(a, b, c, d) } } } }
}

public func const<A, B>(_ lhs: A, _ rhs: B) -> A { return lhs }

public func flip<A, B, C>(_ f: @escaping (A, B) -> C) -> (B, A) -> C {
    return { b, a in f(a, b) }
}

/// The pipe forward operator "|>" provides an infix notation for function application.
/// It is similar in usage to unix pipes.
/// See the following for source and discussion:
/// https://martinmitrevski.com/2018/02/16/forward-pipe-operator-in-swift/
public func |><A, B>(lhs: A, rhs: (A) -> B) -> B {
    return rhs(lhs)
}
