//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

// MARK - delicious curries

public func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    { a in { b in f(a, b) } }
}

public func uncurry<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (A, B) -> C {
    { a, b in f(a)(b) }
}

public func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    { a in { b in { c in f(a, b, c) } } }
}

public func uncurry<A, B, C, D>(_ f: @escaping (A) -> (B) -> (C) -> D) -> (A, B, C) -> D {
    { a, b, c in f(a)(b)(c) }
}

public func curry<A, B, C, D, E>(_ f: @escaping (A, B, C, D) -> E) -> (A) -> (B) -> (C) -> (D) -> E {
    { a in { b in { c in { d in f(a, b, c, d) } } } }
}

public func uncurry<A, B, C, D, E>(_ f: @escaping (A) -> (B) -> (C) -> (D) -> E) -> (A, B, C, D) -> E {
    { a, b, c, d in f(a)(b)(c)(d) }
}

// MARK: - prelude

public func const<A, B>(_ lhs: A, _ rhs: B) -> A {
    lhs
}

public func flip<A, B, C>(_ f: @escaping (A, B) -> C) -> (B, A) -> C {
    { b, a in f(a, b) }
}

public func flip<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C {
    { b in { a in f(a)(b) } }
}

public func id<A>(_ value: A) -> A {
    value
}

public func zurry<A>(_ f: () -> A) -> A {
    f()
}

// MARK: - built-in operator implementations

public func <|<A, B>(_ lhs: (A) -> B, _ rhs: A) -> B {
    lhs(rhs)
}

public func |><A, B>(_ lhs: A, _ rhs: (A) -> B) -> B {
    rhs(lhs)
}

public func >>><A, B, C>(_ lhs: @escaping (A) -> B, _ rhs: @escaping (B) -> C) -> (A) -> C {
    { a in rhs(lhs(a)) }
}

public func <<<<A, B, C>(_ lhs: @escaping (B) -> C, _ rhs: @escaping (A) -> B) -> (A) -> C {
    { a in lhs(rhs(a)) }
}
