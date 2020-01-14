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
// Reducers
//

// reducers have an `inout` “state” by default
let reducer: Reducer<[String], String> = .init { arr, item in arr.append(item) }

// but can also be written with an immutable state
let reduceCaps: Reducer<[String], String> = .nextPartialResult { arr, item in
    return arr + [item.uppercased()]
}

// combine reducers with `<>` to execute them in sequence
let bigReducer = reducer <> reduceCaps
["foo", "bar", "baz"].reduce([], bigReducer)

struct Person { var firstName, lastName: String }

// use `pullback` to make it so existing reducers can chomp other types of values
let people = [
    Person(firstName: "foo", lastName: "bar"),
    Person(firstName: "baz", lastName: "qux")
]
let reduceFirstNames = bigReducer.pullback { (person: Person) in person.firstName }
people.reduce(into: [], reduceFirstNames)

//
// Use reducers and `Changeable` together!
//

/// update a `Person` by taking the first component of a tuple as the new first name
let processFirstName: Reducer<Changeable<Person>, (String, String)> = .init { person, tuple in
    let (newValue, _) = tuple
    person.write(newValue, at: \.firstName)
}

/// update a `Person` by taking the second component of a tuple as the new last name
let processLastName: Reducer<Changeable<Person>, (String, String)> = .init { person, tuple in
    let (_, newValue) = tuple
    person.write(newValue, at: \.lastName)
}

let redundantChanges = [("foo", "bar"), ("foo", "bar")]
redundantChanges.reduce(
    into: pure(Person(firstName: "foo", lastName: "bar")),
    processFirstName <> processLastName
    )
    .hasChanged // => false

let nonRedundantChanges = [("foo", "bar"), ("foo", "qux")]
nonRedundantChanges.reduce(
    into: pure(Person(firstName: "foo", lastName: "bar")),
    processFirstName <> processLastName
    )
    .hasChanged // => true
