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
    static func <> (_ lhs: Self, _ rhs: Self) -> Self
}

/// a type that supports “combining” (the `<>(_:_:)` operator) in an associativity-agnostic way (that is, the parentheses don’t matter), and also has a known identity element. For a type to be a legitimate `Monoid`, it must obey certain laws. See https://wiki.haskell.org/Typeclassopedia#Monoid for more information
public protocol Monoid: Semigroup {
    /// the identity element for this monoid
    static var empty: Self { get }
}

/// Mark: - Common monoid extensions on standard library types

extension Array: Monoid {
    public static var empty: [Element] {
        return []
    }

    public static func <> (lhs: [Element], rhs: [Element]) -> [Element] {
        return lhs + rhs
    }
}

extension String: Monoid {
    public static var empty: String {
        return ""
    }

    public static func <> (lhs: String, rhs: String) -> String {
        return lhs + rhs
    }
}

extension Substring: Monoid {
    public static var empty: Substring {
        return Substring()
    }

    public static func <> (lhs: Substring, rhs: Substring) -> Substring {
        return lhs + rhs
    }
}
