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
// Change tracking
//

struct Person { var firstName, lastName: String }

/// return a new `Person` based on the supplied value, but with the first name changed to “hamburgers”. If the first name is already “hamburgers”, do nothing
///
/// - Parameter person: a `Person` value
/// - Returns: an updated `Person` value along with `Changeable` metadata
func changeFirstName(_ person: Person) -> Changeable<Person> {
    if person.firstName == "hamburgers" {
        return Changeable(hasChanged: false, value: person)
    } else {
        let nextValue = Person(firstName: "hamburgers", lastName: person.lastName)
        return Changeable(hasChanged: true, value: nextValue)
    }
}
changeFirstName(Person(firstName: "foo", lastName: "bar")).hasChanged // => true
changeFirstName(Person(firstName: "hamburgers", lastName: "qux")).hasChanged // => false

/// return a new `Person` based on the supplied value, but with the last name changed to “kale”. If the last name is already “kale”, do nothing
///
/// - Parameter person: a `Person` value
/// - Returns: an updated `Person` value along with `Changeable` metadata
func changeLastName(_ person: Person) -> Changeable<Person> {
    if person.lastName == "kale" {
        return Changeable(hasChanged: false, value: person)
    } else {
        let nextValue = Person(firstName: person.firstName, lastName: "kale")
        return Changeable(hasChanged: true, value: nextValue)
    }
}

// execute multiple changes in sequence using `flatMap` or `>>-`
let twoChanges = Changeable(value: Person(firstName: "foo", lastName: "bar"))
    .flatMap(changeFirstName)
    .flatMap(changeLastName)
twoChanges.hasChanged // => true

let oneChange = pure(Person(firstName: "hamburgers", lastName: "qux"))
    >>- changeFirstName
    >>- changeLastName
oneChange.hasChanged // => true

let twoNoOps = pure(Person(firstName: "hamburgers", lastName: "kale"))
    >>- changeFirstName
    >>- changeLastName
twoNoOps.hasChanged // => false

// write changes inline, declaratively, using `Changeable.write`
let twoMoreChanges = pure(Person(firstName: "foo", lastName: "bar"))
    >>- Changeable.write("hamburgers", at: \.firstName)
    >>- Changeable.write("kale", at: \.lastName)
twoMoreChanges.hasChanged // => true

// write changes inline, declaratively, in a mutable style
var mutateMe = pure(Person(firstName: "hamburgers", lastName: "kale"))
mutateMe.write("hamburgers", at: \.firstName)
mutateMe.write("kale", at: \.lastName)
mutateMe.hasChanged // => false

// combine values that already have `hasChanged` flags into a larger value using applicative operations
let hasChangedFirstName = Changeable(hasChanged: true, value: "foo")
let hasntChangedLastName = Changeable(hasChanged: false, value: "bar")
let newPerson = liftA(Person.init, hasChangedFirstName, hasntChangedLastName)
newPerson.hasChanged // => true

let anotherPerson = pure(curry(Person.init))
    <*> Changeable(hasChanged: false, value: "foo")
    <*> Changeable(hasChanged: false, value: "bar")
anotherPerson.hasChanged // => false
