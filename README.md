# Prelude

[![Build Status](https://travis-ci.org/wayfair/prelude.svg?branch=master)](https://travis-ci.org/wayfair/prelude)

`Prelude` is a library, developed at [Wayfair](https://www.wayfair.com), for functional programming in Swift. We use this library in [our apps](https://itunes.apple.com/us/developer/wayfair-llc/id525522335) to build features in a functional style.

## Installation

`Prelude` can be installed in your project via [Carthage](https://github.com/Carthage/Carthage) or [Swift Package Manager](https://swift.org/package-manager/). [CocoaPods](https://cocoapods.org) support is [forthcoming](https://github.com/wayfair/prelude/issues/5).

### Carthage customization hook

If you’re incorporating `Prelude` via Carthage and need to tweak build settings (for example, perhaps you want to build the library as a static framework instead, to [improve app launch times](https://developer.apple.com/videos/play/wwdc2016/406/)), we’ve included a reference to a [magic customization file](https://github.com/wayfair/prelude/blob/master/xcconfigs/Prelude.xcconfig#L19) which may be able to help you.

If there’s anything else we can do to support integrating Prelude into your project, please open an issue!

## Contents

* *Change Tracking*: a specialization of the Writer monad that keeps track of changes to an enclosed value
* *Reducers*: Redux-style reducers that compose together and support both `inout` and non-`inout` usage
* *Functional Glue*: a handful of the most important general functions for implementing functional features
* *Operators*: a handful of the most important functional operators, with appropriate precedences for Swift

Read on for details, or go directly to [the playground](https://github.com/wayfair/prelude/tree/master/Example/Prelude.playground)

## Change Tracking

### 1. Use `Changeable` to record when a value has changed

[`Changeable`](https://github.com/wayfair/prelude/blob/master/Sources/Prelude/ChangeTracking.swift) is a wrapper type that lets you bundle a `hasChanged` flag alongside a piece of data. Use it if you need to let someone know whether or not a value has changed:

```swift
let wasUpdated = Changeable(hasChanged: true, value: "foo")
```

### 2. Return `Changeable` from a function to signify a no-op

`Changeable` becomes more useful when used as the return value of a function. You can easily communicate to callers whether their call into you was a no-op:

```swift
struct User { var firstName: String }

/// return a new `User` value with the first name changed to "hamburgers".
/// If the first name is already "hamburgers", do nothing.
func updateFirstName(_ user: User) -> Changeable<User> {
    if user.firstName == "hamburgers" {
        return Changeable(hasChanged: false, value: user)
    } else {
        let newUser = User(firstName: "hamburgers")
        return Changeable(hasChanged: true, value: newUser)
    }
}

let myUser = User(firstName: "hamburgers")
updateFirstName(myUser) // .hasChanged => false
```

### 3. Chain these kind of functions together with `flatMap`

If you need to transform many aspects of a value, write a series of small transformation functions, chain them together with `flatMap`, and then check if anything changed at the end:

```swift
/// return a new `User` value with the first name changed to "hamburgers".
/// If the first name is already "hamburgers", do nothing.
func updateFirstName(_ user: User) -> Changeable<User> {
    /* implementation omitted */
}

/// return a new `User` value with the last name changed to "kale".
/// If the last name is already "kale", do nothing.
func updateLastName(_ user: User) -> Changeable<User> {
    /* implementation omitted */
}

let myUser = User(firstName: "hamburgers", lastName: "kale")
Changeable(value: myUser)
    .flatMap(updateFirstName)
    .flatMap(updateLastName) // .hasChanged => false

let someoneElse = User(firstName: "peter", lastName: "kale")
Changeable(value: someoneElse)
    .flatMap(updateFirstName)
    .flatMap(updateLastName) // .hasChanged => true
```

### 4. Add functional spice by using the `>>-` (“bind”) operator

`>>-` is just a synonym for `flatMap`. It works the same way, but you don’t have to type as many parentheses:

```swift
let myUser = User(firstName: "hamburgers", lastName: "kale")
Changeable(value: myUser)
    >>- updateFirstName
    >>- updateLastName // .hasChanged => false (same code as above)
```

### 5. Easily write chainable transformation functions with `Changeable.write`

Writing handmade transformation functions like `updateFirstName` can be time-consuming. For a quick update, use `Changeable.write` to generate transformation functions just like the above, built from Swift key paths.

```swift
let myUser = User(firstName: "hamburgers", lastName: "kale")
Changeable(value: myUser)
    >>- Changeable.write("hamburgers", at: \.firstName)
    >>- Changeable.write("kale", at: \.lastName) // .hasChanged => false (same overall transformation as above)
```

### 6. Incorporate domain logic into `Changeable.write` functions by closing over values

However, complex changes may require more than the simple syntax above. This snippet uses a flag from the enclosing scope to determine whether or not to write one of its changes:

```swift
let makeTheChange = true

let myUser = User(firstName: "hamburgers", lastName: "kale")
Changeable(value: myUser)
    >>- Changeable.write("peter", at: \.firstName, shouldChange: { _, _ in makeTheChange })
    >>- Changeable.write("kale", at: \.lastName)
```

### 7. Use local mutation when convenient

If your `Changeable` value is a `var`, you can `.write` directly to it instead of having to do any `flatMap`ping or `>>-`ing. This snippet also uses the functional shorthand `pure` to quickly “lift” a plain `Person` value into a `Changeable` value:

```swift
var mutateMe = pure(Person(firstName: "hamburgers", lastName: "kale"))
mutateMe.write("hamburgers", at: \.firstName)
mutateMe.write("kale", at: \.lastName)
mutateMe.hasChanged // => false
```

## Reducers

### 1. `Reducer`s give reducing functions a name

`Sequence.reduce` is a powerful function, but the functions that are passed to it are usually just written inline. Since these functions can be very useful, wrap them in a `Reducer` to give them a name, share them, and pass them around:

```swift
let sumOfIntegers: Reducer<Int, Int> = .nextPartialResult { sum, integer in
    return sum + integer
}

[1, 2, 3].reduce(0, sumOfIntegers) // => 6
```

### 2. Use `followed(by:)` to chain reducers together

If the types match, it’s possible to build larger reducers out of small ones by chaining them together. They execute sequentially:

```swift
let productOfIntegers: Reducer<Int, Int> = .nextPartialResult { product, integer in
    return product * integer
}

let bigReducer = sumOfIntegers.followed(by: productOfIntegers)

[1, 2, 3].reduce(0, bigReducer) // => 27
```

### 3. Use the `<>` operator to chain many reducers together, and don’t worry about the parens

`<>` is just a synonym for `followed(by:)`, and it can be shown that this operation is _associative_. So when you want to chain a lot of reducers together, use `<>`, and there is no need to use parentheses:

```swift
let appendIntValue: Reducer<[String], Int> = .nextPartialResult { arr, integer in arr + ["\(integer)"] }
let appendIntValuePlus1: Reducer<[String], Int> = .nextPartialResult { arr, integer in arr + ["\(integer + 1)"] }
let appendIntValuePlus2: Reducer<[String], Int> = .nextPartialResult { arr, integer in arr + ["\(integer + 2)"] }

[1, 10, 100].reduce(
    [],
    appendIntValue <> appendIntValuePlus1 <> appendIntValuePlus2
) // => ["1", "2", "3", "10", "11", "12", "100", "101", "102"]
```

### 4. Existing reducers can be adapted to new types with `pullback`

If you have a reducer that is hungry for values of type `X`, but you only have values of type `Y` on hand, write a function that transforms `Y`s into `X`s and then adapt your reducer using [`pullback`](https://www.pointfree.co/blog/posts/22-some-news-about-contramap). The adapted reducer will then be able to chomp the new values:

```swift
let appendIntValue: Reducer<[String], Int> = .nextPartialResult { arr, integer in arr + ["\(integer)"] }

func getCount(of string: String) -> Int { return string.count }

let appendCountValue = appendIntValue.pullback(getCount) // this reducer has been adapted
["a", "aa", "aaa"].reduce([], appendCountValue) // => ["1", "2", "3"]
```

### 5. `inout` Reducers

`inout` Reducers (reducers where the first parameter of the closure is mutable) can be extremely convenient. Our reducers are, in fact, *`inout` by default:*

```swift
let reducer: Reducer<[String], String> = .init { arr, item in arr.append(item) }
```

(note the usage of `.init` here instead of `.nextPartialResult` as used in previous examples)

### 6. Unified representation

Under the hood, _all_ reducers are of the `inout` flavor. This means that regardless of how a reducer was initialized, it can interoperate with all other reducers:

```swift
let reducer: Reducer<[String], String> = .init { arr, item in arr.append(item) }

let reduceCaps: Reducer<[String], String> = .nextPartialResult { arr, item in
    return arr + [item.uppercased()]
}

let bigReducer = reducer <> reduceCaps // this is ok
["foo", "bar", "baz"].reduce([], bigReducer)
```

### Functional Glue

`Prelude.swift` contains our implementations of `curry`, `const`, `flip`, and `|>`

### Operators

* `<*>`
* `<*`
* `*>`
* `>>-`
* `<|>`
* `|>`
* `<>`
