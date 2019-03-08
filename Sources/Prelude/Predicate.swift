//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

public struct Predicate<A> {
    public let contains: (A) -> Bool
}

// MARK: - set algebra

public extension Predicate {
    func intersection(_ other: Predicate) -> Predicate {
        return .init { self.contains($0) && other.contains($0) }
    }

    func subtracting(_ other: Predicate) -> Predicate {
        return intersection(other.complement)
    }

    func symmetricDifference(_ other: Predicate) -> Predicate {
        return self.subtracting(other).union(other.subtracting(self))
    }

    func union(_ other: Predicate) -> Predicate {
        return .init { self.contains($0) || other.contains($0) }
    }
}

public extension Predicate {
    var complement: Predicate<A> {
        return .init { !self.contains($0) }
    }

    func pullback<B>(_ transform: @escaping (B) -> A) -> Predicate<B> {
        return .init { self.contains(transform($0)) }
    }
}

// MARK: - Monoid

extension Predicate: Monoid {
    public static var empty: Predicate {
        return .init { _ in true }
    }

    public static func <>(_ lhs: Predicate, _ rhs: Predicate) -> Predicate {
        return lhs.intersection(rhs)
    }
}
