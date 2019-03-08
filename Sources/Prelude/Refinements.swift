//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

/// protocol that represents a rule that can be used to “refine” values of type `RefinedType`. Implement the `static Refinement.isValid(_:)` function to describe which values are allowed.
public protocol Refinement {
    /// the type being “refined”
    associatedtype BaseType

    /// implement this function to describe which values of type `RefinedType` should be allowed
    ///
    /// - Parameter value: a proposed value of type `RefinedType`
    /// - Returns: `true` if this rule should allow `value`
    static func isValid(_ value: BaseType) -> Bool
}

fileprivate extension Refinement {
    static var predicate: Predicate<BaseType> { return .init(contains: isValid) }
}

/// error that is thrown when a value fails a refinement. Examine `localizedDescription` to determine the details of the failure
public struct RefinementError: Error {
    public let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}

/// a container for a “refined” type. The type parameter `A` represents the underlying value (eg. `Int`). The type parameter `R` represents the “refinement” (eg. `NonZero`, `NotNegative`, `GreaterThanFifty`, etc.)
public struct Refined<A, Rule: Refinement> where A == Rule.BaseType {
    /// the underlying refined value. This value is guaranteed to satisfy the refinement represented by `R`
    public let value: A

    /// initialize a `Refined` value with the proposed underlying value `value`. If the value satisfies the rule  represented by `R`, then this initializer will succeed. Otherwise, this initializer will throw a `RefinementError` describing the failure
    ///
    /// - Parameter value: the proposed underlying value
    /// - Throws: a `RefinementError` describing any failure
    public init(_ value: A) throws {
        guard Rule.isValid(value) else {
            throw RefinementError("the value “\(value)” doesn’t satisfy the refinement “\(Rule.self)”")
        }
        self.value = value
    }
}

public extension Refinement {
    /// make a function’s signature more restrictive. Given a function that takes an unrefined type as its parameter, return a function that performs the same computation, but requires a type of `Refined<RefinedType, Self>` as its parameter
    ///
    /// - Parameter f: a function that takes a value of type `RefinedType` as a parameter
    /// - Returns: the function provided, wrapped to require this refined type as a parameter
    static func narrow<A>(_ f: @escaping (BaseType) -> A) -> (Refined<BaseType, Self>) -> A {
        return { refined in f(refined.value) }
    }
    /// convenient way to initialize a value of type `Refined<RefinedType, Self>` given a proposed value. This is equivalent to calling `try? Refined<RefinedType, Self>.init(value)`, but much easier to type
    ///
    /// - Parameter value: the proposed value
    /// - Returns: a value of type `Refined<RefinedType, Self>`, or nil
    static func of(_ value: BaseType) -> Refined<BaseType, Self>? {
        return try? .init(value)
    }
}

// MARK: - Equatable

extension Refined: Equatable where A: Equatable { }

// MARK: - Hashable

extension Refined: Hashable where A: Hashable { }

// MARK: - Sequence

public extension Sequence {
    /// given a sequence of `Element`s (`self`), produce a new array of elements where each element has been refined by the rule `refinement`, and the elements that failed the rule have been discarded
    ///
    /// - Parameter refinement: the refinement to apply
    /// - Returns: the result of refining the elements of `self` by `refinement` and discarding those that did not pass
    func refineMap<Rule: Refinement>(
        _ refinement: Rule.Type = Rule.self) -> [Refined<Element, Rule>] where Element == Rule.BaseType {
        return compactMap(Rule.of)
    }
}

// MARK: - Both

/// a refinement that can be used to combine any two other refinements (`L` and `R`), such that they both must pass
public enum Both<L: Refinement, R: Refinement>: Refinement where L.BaseType == R.BaseType {
    public typealias RefinedType = L.BaseType
    public static func isValid(_ value: RefinedType) -> Bool {
        return L.predicate.intersection(R.predicate).contains(value)
    }
}

/// given a value that is refined by two rules (`L` and `R`), produce a value that is refined only by the rule on the left (`L`). This function will always succeed (the underlying value has already passed both rules)
///
/// - Parameter refined: a value that is refined by two rules
/// - Returns: the same value, refined only by the rule on the left
public func left<A, L, R>(_ refined: Refined<A, Both<L, R>>) -> Refined<A, L> {
    guard let result = L.of(refined.value) else {
        preconditionFailure("when calling `left(_:)`: the value “\(refined.value)” didn’t satisfy the refinement “\(L.self)”. This shouldn’t happen. Was the value mutated after refinements had already been checked?")
    }
    return result
}

/// given a value that is refined by two rules (`L` and `R`), produce a value that is refined only by the rule on the right (`R`). This function will always succeed (the underlying value has already passed both rules)
///
/// - Parameter refined: a value that is refined by two rules
/// - Returns: the same value, refined only by the rule on the right
public func right<A, L, R>(_ refined: Refined<A, Both<L, R>>) -> Refined<A, R> {
    guard let result = R.of(refined.value) else {
        preconditionFailure("when calling `right(_:)`: the value “\(refined.value)” didn’t satisfy the refinement “\(R.self)”. This shouldn’t happen. Was the value mutated after refinements had already been checked?")
    }
    return result
}

// MARK: - Not

/// a refinement that can be used to invert any other refinement
public enum Not<Rule: Refinement>: Refinement {
    public typealias RefinedType = Rule.BaseType
    public static func isValid(_ value: Rule.BaseType) -> Bool {
        return Rule.predicate.complement.contains(value)
    }
}

// MARK: - OneOf

/// a refinement that can be used to combine any two other refinements (`L` and `R`), such that either one or the other must pass
public enum OneOf<L: Refinement, R: Refinement>: Refinement where L.BaseType == R.BaseType {
    public typealias RefinedType = L.BaseType
    public static func isValid(_ value: RefinedType) -> Bool {
        return L.predicate.union(R.predicate).contains(value)
    }
}

/// given a value that is refined by a `OneOf<L, R>` (either the refinement `L`, or the refinement `R`), produce a value that is just refined by `L`. This function returns nil if the underlying value does not satisfy `L`
///
/// - Parameter refined: a value that is refined by the disjunction of two rules
/// - Returns: the same value, refined only by the rule on the left, or nil
public func left<A, L, R>(_ refined: Refined<A, OneOf<L, R>>) -> Refined<A, L>? {
    return L.of(refined.value)
}

/// given a value that is refined by a `OneOf<L, R>` (either the refinement `L`, or the refinement `R`), produce a value that is just refined by `R`. This function returns nil if the underlying value does not satisfy `R`
///
/// - Parameter refined: a value that is refined by the disjunction of two rules
/// - Returns: the same value, refined only by the rule on the right, or nil
public func right<A, L, R>(_ refined: Refined<A, OneOf<L, R>>) -> Refined<A, R>? {
    return R.of(refined.value)
}

/// given a value that is refined by a `OneOf<L, R>` (either the refinement `L`, or the refinement `R`), produce a value that is refined by both (`Both<L, R>`). This function returns nil if the underlying value does not satisfy both `L` and `R`
///
/// - Parameter refined: a value that is refined by the disjunction of two rules
/// - Returns: the same value, refined by both of the rules, or nil
public func both<A, L, R>(_ refined: Refined<A, OneOf<L, R>>) -> Refined<A, Both<L, R>>? {
    return Both<L, R>.of(refined.value)
}

// MARK: - Int

public extension Int {
    typealias GreaterThan<N: Nat> = Not<LessThan<Succ<N>>>

    typealias GreaterThanOrEqual<N: Nat> = Not<LessThan<N>>

    typealias GreaterThanZero = GreaterThan<Zero>

    enum LessThan<N: Nat>: Refinement {
        public typealias RefinedType = Int
        public static func isValid(_ value: Int) -> Bool {
            return value < N.intValue
        }
    }

    typealias LessThanOrEqual<N: Nat> = LessThan<Succ<N>>

    typealias LessThanZero = LessThan<Zero>
}

// MARK: - String

public extension String {
    enum NonEmpty: Refinement {
        public typealias RefinedType = String
        public static func isValid(_ value: String) -> Bool {
            return !value.isEmpty
        }
    }
}
