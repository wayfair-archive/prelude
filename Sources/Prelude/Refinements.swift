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
    associatedtype RefinedType

    /// implement this function to describe which values of type `RefinedType` should be allowed
    ///
    /// - Parameter value: a value of type `RefinedType`
    /// - Returns: `true` if this rule should allow `value`
    static func isValid(_ value: RefinedType) -> Bool
}

/// error that is thrown when a value fails a refinement. Examine `localizedDescription` to determine the details of the failure
public struct RefinementError: Error {
    public let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}

/// a container for a “refined” type. The type parameter `A` represents the underlying value (eg. `Int`). The type parameter `R` represents the “refinement” (eg. `NonZero`, `NotNegative`, `GreaterThanFifty`, etc.)
public struct Refined<A, R: Refinement> where A == R.RefinedType {
    /// the underlying refined value. This value is guaranteed to satisfy the refinement represented by `R`
    public let value: A

    /// initialize a `Refined` value with the proposed underlying value `value`. If the value satisfies the rule  represented by `R`, then this initializer will succeed. Otherwise, this initializer will throw a `RefinementError` describing the failure
    ///
    /// - Parameter value: the proposed underlying value
    /// - Throws: a `RefinementError` describing any failure
    public init(_ value: A) throws {
        guard R.isValid(value) else {
            throw RefinementError("the value “\(value)” doesn’t satisfy the refinement “\(R.self)”")
        }
        self.value = value
    }
}

extension Refined: Equatable where A: Equatable { }

extension Refined: Hashable where A: Hashable { }

public extension Refinement {
    /// convenient way initialize a value of type `Refined<RefinedType, Self>` given a proposed value. This is equivalent to calling `try? Refined<RefinedType, Self>.init(value)`, but much easier to type
    ///
    /// - Parameter value: the proposed value
    /// - Returns: a value of type `Refined<RefinedType, Self>`, or nil
    static func of(_ value: RefinedType) -> Refined<RefinedType, Self>? {
        return try? .init(value)
    }
}

// MARK: - Both

/// a refinement that can be used to combine any two other refinements (`L` and `R`), such that they both must pass
public enum Both<L: Refinement, R: Refinement>: Refinement where L.RefinedType == R.RefinedType {
    public typealias RefinedType = L.RefinedType
    public static func isValid(_ value: RefinedType) -> Bool {
        return L.isValid(value) && R.isValid(value)
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
public enum Not<R: Refinement>: Refinement {
    public typealias RefinedType = R.RefinedType
    public static func isValid(_ value: R.RefinedType) -> Bool {
        return !R.isValid(value)
    }
}

// MARK: - OneOf

/// a refinement that can be used to combine any two other refinements (`L` and `R`), such that either one or the other must pass
public enum OneOf<L: Refinement, R: Refinement>: Refinement where L.RefinedType == R.RefinedType {
    public typealias RefinedType = L.RefinedType
    public static func isValid(_ value: RefinedType) -> Bool {
        return L.isValid(value) || R.isValid(value)
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
