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
// Refinement types
//

// let’s create a very basic `Person` type
struct Person { var firstName, lastName: String }

// there are some values of this type (eg. both names empty, only a defined `firstName`, etc.) that we probably want to consider invalid data or garbage in some way

// we’ll write a `Refinement` to `Person` that expresses the fact that the names can’t be empty
enum ValidName: Refinement {
    typealias BaseType = Person
    static func isValid(_ value: Person) -> Bool {
        return !value.firstName.isEmpty && !value.lastName.isEmpty
    }
}

// now, let’s put our refinement “rule” and the `Person` type itself into a box to create a new type that enforces our rules:
typealias ValidPerson = Refined<Person, ValidName>

// here’s a value of type `Person`. Let’s pretend we got it from somewhere else in our application, so we’re not sure whether it’s valid or not…
let person = Person(firstName: "", lastName: "foo")

// the `ValidPerson` initializer will only successfully `init` if the rule is satisfied:
try? ValidPerson.init(person) // => nil

try? ValidPerson.init(Person(firstName: "a", lastName: "b")) // => ok

// let’s pretend we have a function that does Important Business Logic with persons
func doImportantBusinessLogic(with person: Person) {
    // ensure the person is valid
    if person.firstName.isEmpty || person.lastName.isEmpty {
        fatalError("Person data was invalid! I can’t do my important thing")
    }
    // do important thing with a valid person here
}

// we can now refactor this function and the compiler will enforce our rule for us (no more `fatalError` needed)!
func doImportantBusinessLogic2(with person: ValidPerson) {
    // names are guaranteed to be valid; do important thing with person here
}

// just to be clear about that: the following line does not compile…
//doImportantBusinessLogic2(with: person) // => error: cannot convert value of type 'Person' to expected argument type 'ValidPerson' (aka 'Refined<Person, ValidName>')

// we’ve taken what was a runtime error (`fatalError`), and made it into a compile-time error!

// in a real app, this means fewer “Oops!” boxes, less bailing out of functions when data isn’t right, and less need to document invariants in code comments. Those things go away and are replaced with checks in the type system.

// there’s a problem though. Our rule doesn’t hold for all possible users of our application. What about people who legitimately only have one name? We need another refinement:
enum PersonIsPrince: Refinement {
    typealias BaseType = Person
    static func isValid(_ value: Person) -> Bool {
        return value.firstName == "Prince" && value.lastName.isEmpty // RIP
    }
}

// as long as the `BaseType`s match, we can compose refinements on the fly. The `OneOf` wrapper type creates a refinement that will let a value pass if either the left- **or** right-side refinement passes:
typealias ValidName2 = OneOf<ValidName, PersonIsPrince>

// now Prince can order a couch again. I won’t bother to write another typealias, here’s the full type inline:
func doImportantBusinessLogic3(with person: Refined<Person, ValidName2>) {
    // I hope some purple couches are in stock
}

// here are some of the basic refinements that are already in the library
Int.GreaterThanZero.of(1) // => ok

Int.GreaterThan<One>.of(-99) // => nil

String.NonEmpty.of("foo") // => ok

String.NonEmpty.of("") // => nil

// conditional conformance of refined types works as expected
Int.GreaterThanZero.of(1) == Int.GreaterThanZero.of(1) // => true

// to `compactMap` **and** refine at the same time, use `refineMap`
let bar = [-1, 0, 1, 2, 3].refineMap(Int.GreaterThanZero.self) // => (3 values)

// you can also write it like this
let foo: [Refined<Int, Int.GreaterThanZero>] = [-1, 0, 1, 2, 3].refineMap()

foo == bar // => true
