//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

// MARK: - left associative

/// in Haskell: `infixl 4`
precedencegroup WayfairApply {
    associativity: left
    higherThan: WayfairBind
}

infix operator <*>: WayfairApply

infix operator <*: WayfairApply

infix operator *>: WayfairApply

/// in Haskell: `infixl 1`
precedencegroup WayfairBind {
    associativity: left
    higherThan: AssignmentPrecedence
}

infix operator >>-: WayfairBind

/// in Haskell: `infixl 3`
precedencegroup WayfairAlternative {
    associativity: left
    higherThan: WayfairBind
}

infix operator <|>: WayfairAlternative

precedencegroup WayfairPipe {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
}

/// Definition can be found in /Sources/Prelude.swift
infix operator |>: WayfairPipe

// MARK: - right associative

/// in Haskell: `infixr 6`
precedencegroup WayfairSemigroupCombine {
    associativity: right
    higherThan: WayfairApply
    lowerThan: AdditionPrecedence
}

infix operator <>: WayfairSemigroupCombine
