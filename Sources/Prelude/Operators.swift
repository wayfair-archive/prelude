//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

// MARK: - 0

precedencegroup wf_infixl0 {
    associativity: left
    higherThan: AssignmentPrecedence
}
precedencegroup wf_infixr0 {
    associativity: right
    higherThan: wf_infixl0
}

infix operator <|: wf_infixr0

// MARK: - 1

precedencegroup wf_infixl1 {
    associativity: left
    higherThan: wf_infixr0
}
precedencegroup wf_infixr1 {
    associativity: right
    higherThan: wf_infixl1
}

infix operator >>-: wf_infixl1

infix operator |>: wf_infixl1

infix operator >->: wf_infixr1

// MARK: - 2

precedencegroup wf_infixl2 {
    associativity: left
    higherThan: wf_infixr1
}
precedencegroup wf_infixr2 {
    associativity: right
    higherThan: wf_infixl2
}

// MARK: - 3

precedencegroup wf_infixl3 {
    associativity: left
    higherThan: wf_infixr2
}
precedencegroup wf_infixr3 {
    associativity: right
    higherThan: wf_infixl3
}

infix operator <|>: wf_infixl3

// MARK: - 4

precedencegroup wf_infixl4 {
    associativity: left
    higherThan: wf_infixr3
}
precedencegroup wf_infixr4 {
    associativity: right
    higherThan: wf_infixl4
}

infix operator <*>: wf_infixl4

infix operator <*: wf_infixl4

infix operator *>: wf_infixl4

// MARK: - 5

precedencegroup wf_infixl5 {
    associativity: left
    higherThan: wf_infixr4
}
precedencegroup wf_infixr5 {
    associativity: right
    higherThan: wf_infixl5
}

infix operator <>: wf_infixr5

// MARK: - 6

precedencegroup wf_infixl6 {
    associativity: left
    higherThan: wf_infixr5
}
precedencegroup wf_infixr6 {
    associativity: right
    higherThan: wf_infixl6
}

// MARK: - 7

precedencegroup wf_infixl7 {
    associativity: left
    higherThan: wf_infixr6
}
precedencegroup wf_infixr7 {
    associativity: right
    higherThan: wf_infixl7
}

// MARK: - 8

precedencegroup wf_infixl8 {
    associativity: left
    higherThan: wf_infixr7
}
precedencegroup wf_infixr8 {
    associativity: right
    higherThan: wf_infixl8
}

// MARK: - 9

precedencegroup wf_infixl9 {
    associativity: left
    higherThan: wf_infixr8
}
precedencegroup wf_infixr9 {
    associativity: right
    higherThan: wf_infixl9
}

infix operator >>>: wf_infixr9

infix operator <<<: wf_infixr9
