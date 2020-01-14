//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Prelude

//
// Functions
//

// currying

func appendPunctuation(_ character: Character, toText text: String) -> String {
    return "\(text)\(character)"
}
appendPunctuation("!", toText: "foo")

let appendQuestionMark = curry(appendPunctuation(_:toText:))("?")
appendQuestionMark("bar")

// function composition

func countCharacters(_ stringValue: String) -> Int {
    return stringValue.count
}

let countQuestionCharacters = appendQuestionMark >>> countCharacters
countQuestionCharacters <| "hello"

"world" |> appendQuestionMark >>> countCharacters

countCharacters(appendQuestionMark(appendQuestionMark("123")))
countCharacters <<< appendQuestionMark <<< appendQuestionMark <| "123"

countCharacters
    <<< appendQuestionMark
    <<< appendQuestionMark
    <| "1234"

//
// Monoids
//

[1, 2, 3] <> [4, 5, 6]
Array.empty <> [1, 2, 3] <> [4, 5, 6] <> .empty <> [7, 8, 9]

([1, 2, 3], ["a", "b"]) <> ([4, 5, 6], ["c", "d"])
([1, 2, 3], "ab", Last(value: 1.99)) <> ([4, 5, 6], "cd", Last(value: 99.99))

["a", "b", "c"].concat()

//
// use all the operators to make sure they play well together zone
//

struct M<A, B> { let run: (A) throws -> B }

func >>-<A, B, C>(_ lhs: M<A, B>, _ rhs: @escaping (B) -> M<A, C>) -> M<A, C> {
    return .init { input in
        let firstValue = try lhs.run(input)
        let nextStep = rhs(firstValue)
        return try nextStep.run(input)
    }
}

extension M {
    func map<C>(_ transform: @escaping (B) -> C) -> M<A, C> {
        return .init { input in
            try self.run(input) |> transform
        }
    }
}

typealias IO<B> = M<Void, B>

import Foundation

extension Date {
    static var current: IO<Date> {
        return .init { Date() }
    }
}
extension DateFormatter {
    static var myFormatter: IO<DateFormatter> {
        return .init {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }
    }
}
func doFormat(forDate date: Date) -> IO<String> {
    return DateFormatter.myFormatter.map { $0.string(from: date) }
}

let x = Date.current >>- doFormat(forDate:)
x.run(())

func >-><A, B, C, D>(
    _ lhs: @escaping (B) -> M<A, C>,
    _ rhs: @escaping (C) -> M<A, D>) -> (B) -> M<A, D> {
    return { value in lhs(value) >>- rhs }
}

func doPrint(_ stringValue: String) -> IO<Void> {
    return .init { Swift.print(stringValue |> appendQuestionMark) }
}

let y = doFormat(forDate:) >-> doPrint
(Date.current >>- y).run(())
