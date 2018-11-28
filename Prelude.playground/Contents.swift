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

// use `contramap` to make it so existing reducers can chomp other types of values
let people = [
    Person(firstName: "foo", lastName: "bar"),
    Person(firstName: "baz", lastName: "qux")
]
let reduceFirstNames = bigReducer.contramap { (person: Person) in person.firstName }
people.reduce(into: [], reduceFirstNames)

//
// Use both together!
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
