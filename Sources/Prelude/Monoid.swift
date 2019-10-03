//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

/// a type that supports “combining” (the `<>(_:_:)` operator) in an associativity-agnostic way (that is, the parentheses don’t matter). For a type to be a legitimate `Semigroup`, it must obey certain laws. See https://wiki.haskell.org/Typeclassopedia#Semigroup for more information
public protocol Semigroup {
    static func <>(_ lhs: Self, _ rhs: Self) -> Self
}

/// a type that supports “combining” (the `<>(_:_:)` operator) in an associativity-agnostic way (that is, the parentheses don’t matter), and also has a known identity element. For a type to be a legitimate `Monoid`, it must obey certain laws. See https://wiki.haskell.org/Typeclassopedia#Monoid for more information
public protocol Monoid: Semigroup {
    /// the identity element for this monoid
    static var empty: Self { get }
}

public extension Sequence where Element: Monoid {
    func concat() -> Element {
        return reduce(.empty, <>)
    }
}

// MARK: - standard library types

extension Array: Monoid {
    public static var empty: [Element] {
        return []
    }

    public static func <>(_ lhs: [Element], _ rhs: [Element]) -> [Element] {
        return lhs + rhs
    }
}

extension Dictionary: Semigroup where Value: Semigroup {
    public static func <>(_ lhs: Dictionary, _ rhs: Dictionary) -> Dictionary {
        return lhs.merging(rhs, uniquingKeysWith: <>)
    }
}

extension Dictionary: Monoid where Value: Semigroup {
    public static var empty: Dictionary {
        return [:]
    }
}

extension String: Monoid {
    public static var empty: String {
        return ""
    }

    public static func <>(_ lhs: String, _ rhs: String) -> String {
        return lhs + rhs
    }
}

extension Substring: Monoid {
    public static var empty: Substring {
        return Substring()
    }

    public static func <>(_ lhs: Substring, _ rhs: Substring) -> Substring {
        return lhs + rhs
    }
}

// MARK: - primitive semigroups

/// wrapper for any value, with a `<>` implementation that always takes the left-hand side
public struct First<A>: Semigroup {
    public let value: A

    public init(value: A) {
        self.value = value
    }

    public static func <>(_ keep: First<A>, _ discard: First<A>) -> First<A> {
        return keep
    }
}

extension First: Equatable where A: Equatable { }

/// wrapper for any value, with a `<>` implementation that always takes the right-hand side
public struct Last<A>: Semigroup {
    public let value: A

    public init(value: A) {
        self.value = value
    }

    public static func <>(_ discard: Last<A>, _ keep: Last<A>) -> Last<A> {
        return keep
    }
}

extension Last: Equatable where A: Equatable { }

// MARK: - optional

// if the type `Wrapped` is a `Semigroup`, then `Wrapped?` can always be made into a `Monoid` by using `nil` as the identity element
extension Optional: Semigroup where Wrapped: Semigroup {
    public static func <>(_ lhs: Wrapped?, _ rhs: Wrapped?) -> Wrapped? {
        if let lhs = lhs, let rhs = rhs {
            return lhs <> rhs
        } else if let lhs = lhs {
            return lhs
        } else if let rhs = rhs {
            return rhs
        } else {
            return nil
        }
    }
}

extension Optional: Monoid where Wrapped: Semigroup {
    public static var empty: Wrapped? { return nil }
}

// MARK: - tuples

// can’t actually conform tuples to protocols in Swift (yet), but we can implement the `<>` operator for a bunch of tuples of `Semigroup`s, which is kind of the same thing
public func <><M: Semigroup, N: Semigroup>(_ lhs: (M, N), _ rhs: (M, N)) -> (M, N) {
    return (lhs.0 <> rhs.0, lhs.1 <> rhs.1)
}

public func <><M: Semigroup, N: Semigroup, O: Semigroup>(_ lhs: (M, N, O), _ rhs: (M, N, O)) -> (M, N, O) {
    return (lhs.0 <> rhs.0, lhs.1 <> rhs.1, lhs.2 <> rhs.2)
}

public func <><M: Semigroup, N: Semigroup, O: Semigroup, P: Semigroup>(_ lhs: (M, N, O, P), _ rhs: (M, N, O, P)) -> (M, N, O, P) {
    return (lhs.0 <> rhs.0, lhs.1 <> rhs.1, lhs.2 <> rhs.2, lhs.3 <> rhs.3)
}

public func <><M: Semigroup, N: Semigroup, O: Semigroup, P: Semigroup, Q: Semigroup>(_ lhs: (M, N, O, P, Q), _ rhs: (M, N, O, P, Q)) -> (M, N, O, P, Q) {
    return (lhs.0 <> rhs.0, lhs.1 <> rhs.1, lhs.2 <> rhs.2, lhs.3 <> rhs.3, lhs.4 <> rhs.4)
}
