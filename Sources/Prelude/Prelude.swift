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
    return { a in { b in f(a, b) } }
}

public func uncurry<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (A, B) -> C {
    return { a, b in f(a)(b) }
}

public func curry<A, B, C, D>(_ f: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { a in { b in { c in f(a, b, c) } } }
}

public func uncurry<A, B, C, D>(_ f: @escaping (A) -> (B) -> (C) -> D) -> (A, B, C) -> D {
    return { a, b, c in f(a)(b)(c) }
}

public func curry<A, B, C, D, E>(_ f: @escaping (A, B, C, D) -> E) -> (A) -> (B) -> (C) -> (D) -> E {
    return { a in { b in { c in { d in f(a, b, c, d) } } } }
}

public func uncurry<A, B, C, D, E>(_ f: @escaping (A) -> (B) -> (C) -> (D) -> E) -> (A, B, C, D) -> E {
    return { a, b, c, d in f(a)(b)(c)(d) }
}

// MARK: - prelude

public func const<A, B>(_ lhs: A, _ rhs: B) -> A {
    return lhs
}

public func flip<A, B, C>(_ f: @escaping (A, B) -> C) -> (B, A) -> C {
    return { b, a in f(a, b) }
}

public func flip<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C {
    return { b in { a in f(a)(b) } }
}

public func id<A>(_ value: A) -> A {
    return value
}

public func zurry<A>(_ f: () -> A) -> A {
    return f()
}

// MARK: - built-in operator implementations

public func <|<A, B>(_ lhs: (A) -> B, _ rhs: A) -> B {
    return lhs(rhs)
}

public func |><A, B>(_ lhs: A, _ rhs: (A) -> B) -> B {
    return rhs(lhs)
}

public func >>><A, B, C>(_ lhs: @escaping (A) -> B, _ rhs: @escaping (B) -> C) -> (A) -> C {
    return { a in rhs(lhs(a)) }
}

public func <<<<A, B, C>(_ lhs: @escaping (B) -> C, _ rhs: @escaping (A) -> B) -> (A) -> C {
    return { a in lhs(rhs(a)) }
}
