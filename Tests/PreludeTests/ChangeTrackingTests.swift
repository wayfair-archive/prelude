//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

@testable import Prelude
import XCTest

class ChangeTrackingTests: XCTestCase {
    func testHasChangedDefaultsToFalse() {
        XCTAssertFalse(Changeable(value: "foo").hasChanged)
    }

    // MARK: - functor

    func testMapMaps() {
        XCTAssertEqual(
            "3!",
            Changeable(value: 2)
                .map { "\($0 + 1)!" }
                .value
        )
    }

    func testMapPreservesHasChangedValue() {
        XCTAssertTrue(
            Changeable(hasChanged: true, value: "foo")
                .map { $0 + "!" }
                .hasChanged
        )
        XCTAssertFalse(
            Changeable(hasChanged: false, value: "foo")
                .map { $0 + "!" }
                .hasChanged
        )
    }

    func testMapSomeMaps() {
        let magic9Transform: (Int) -> String? = {
            switch $0 {
            case 9: return "nine!"
            default: return nil
            }
        }

        guard let result = Changeable(value: 9)
            .mapSome(magic9Transform) else {
                XCTFail("result should have been non-nil")
                return
        }
        XCTAssertEqual("nine!", result.value)

        XCTAssertNil(Changeable(value: 8).mapSome(magic9Transform))
    }

    func testMapSomePreservesHasChangedValue() {
        let magic9Transform: (Int) -> String? = {
            switch $0 {
            case 9: return "nine!"
            default: return nil
            }
        }

        guard let result1 = Changeable(hasChanged: true, value: 9)
            .mapSome(magic9Transform) else {
                XCTFail("result should have been non-nil")
                return
        }
        XCTAssertTrue(result1.hasChanged)

        guard let result2 = Changeable(hasChanged: false, value: 9)
            .mapSome(magic9Transform) else {
                XCTFail("result should have been non-nil")
                return
        }
        XCTAssertFalse(result2.hasChanged)
    }

    // MARK: - applicative

    func testPureFlagIsFalse() {
        let pureValue: Changeable<String> = pure("foo")
        XCTAssertFalse(pureValue.hasChanged)
    }

    func testApply1() {
        let incrementAndShout: (Int) -> String = { "\($0 + 1)!" }
        let value = pure(incrementAndShout) <*> pure(2)
        XCTAssertFalse(value.hasChanged)
        XCTAssertEqual("3!", value.value)
    }

    func testApply2() {
        let incrementAndShout: (Int) -> String = { "\($0 + 1)!" }
        let value = pure(incrementAndShout) <*> Changeable(hasChanged: true, value: 2)
        XCTAssertTrue(value.hasChanged)
        XCTAssertEqual("3!", value.value)
    }

    func testApply3() {
        let incrementAndShout: (Int) -> String = { "\($0 + 1)!" }
        let value = Changeable(hasChanged: true, value: incrementAndShout) <*> pure(2)
        XCTAssertTrue(value.hasChanged)
        XCTAssertEqual("3!", value.value)
    }

    func testApply4() {
        let incrementAndShout: (Int) -> String = { "\($0 + 1)!" }
        let value = Changeable(hasChanged: true, value: incrementAndShout) <*> Changeable(hasChanged: true, value: 2)
        XCTAssertTrue(value.hasChanged)
        XCTAssertEqual("3!", value.value)
    }

    func testLiftA() {
        let append: (String, String) -> String = { $0 + $1 }
        let value = liftA(append, pure("foo"), Changeable(hasChanged: true, value: "bar"))
        XCTAssertTrue(value.hasChanged)
        XCTAssertEqual("foobar", value.value)
    }

    // MARK: - monad

    func testFlatMapBothAreFalse() {
        let foo = Changeable(value: "foo")
        let transform: (String) -> Changeable<Int> = { _ in Changeable(hasChanged: false, value: 99) }
        XCTAssertFalse(foo.flatMap(transform).hasChanged)
    }

    func testFlatMapFirstIsTrue() {
        let foo = Changeable(hasChanged: true, value: "foo")
        let transform: (String) -> Changeable<Int> = { _ in Changeable(hasChanged: false, value: 99) }
        XCTAssertTrue(foo.flatMap(transform).hasChanged)
    }

    func testFlatMapSecondIsTrue() {
        let foo = Changeable(value: "foo")
        let transform: (String) -> Changeable<Int> = { _ in Changeable(hasChanged: true, value: 99) }
        XCTAssertTrue(foo.flatMap(transform).hasChanged)
    }

    func testFlatMapBothAreTrue() {
        let foo = Changeable(hasChanged: true, value: "foo")
        let transform: (String) -> Changeable<Int> = { _ in Changeable(hasChanged: true, value: 99) }
        XCTAssertTrue(foo.flatMap(transform).hasChanged)
    }

    func testFlatMapTransformsValueReturnsTrue() {
        let foo = Changeable(value: 99)
        let transform: (Int) -> Changeable<String> = { Changeable(hasChanged: true, value: "\($0)") }
        XCTAssertTrue(foo.flatMap(transform).hasChanged)
        XCTAssertEqual("99", foo.flatMap(transform).value)
    }

    func testFlatMapTransformsValueReturnsFalse() {
        let foo = Changeable(value: 99)
        let transform: (Int) -> Changeable<String> = { Changeable(hasChanged: false, value: "\($0)") }
        XCTAssertFalse(foo.flatMap(transform).hasChanged)
        XCTAssertEqual("99", foo.flatMap(transform).value)
    }

    // MARK: - key paths

    struct MyStruct {
        var favoriteFood: String
        var name: String
    }

    func testWriteWithEquatableDoesNotWriteWhenValuesAreEqual() {
        let hamburgers = "hamburgers"
        let writeHamburgers: (MyStruct) -> Changeable<MyStruct> = Changeable.write(hamburgers, at: \.favoriteFood)
        let next = Changeable(value: MyStruct(favoriteFood: hamburgers, name: "")) >>- writeHamburgers
        XCTAssertFalse(next.hasChanged)
        XCTAssertEqual(next.value.favoriteFood, hamburgers)
    }

    func testWriteWithEquatableDoesNotWriteWhenValuesAreEqual_instanceMethod() {
        let hamburgers = "hamburgers"
        var value = Changeable(value: MyStruct(favoriteFood: hamburgers, name: ""))
        value.write(hamburgers, at: \.favoriteFood)
        XCTAssertFalse(value.hasChanged)
        XCTAssertEqual(value.value.favoriteFood, hamburgers)
    }

    func testWriteWithEquatableWritesWhenValuesAreNotEqual() {
        let hamburgers = "hamburgers"
        let writeHamburgers: (MyStruct) -> Changeable<MyStruct> = Changeable.write(hamburgers, at: \.favoriteFood)
        let next = Changeable(value: MyStruct(favoriteFood: "kale", name: "")) >>- writeHamburgers
        XCTAssertTrue(next.hasChanged)
        XCTAssertEqual(next.value.favoriteFood, hamburgers)
    }

    func testWriteWithEquatableWritesWhenValuesAreNotEqual_instanceMethod() {
        let hamburgers = "hamburgers"
        var value = Changeable(value: MyStruct(favoriteFood: "kale", name: ""))
        value.write(hamburgers, at: \.favoriteFood)
        XCTAssertTrue(value.hasChanged)
        XCTAssertEqual(value.value.favoriteFood, hamburgers)
    }

    func testWriteWithShouldChangeFunctionDoesNotWriteWhenItReturnsFalse() {
        let hamburgers = "hamburgers"
        let writeHamburgers: (MyStruct) -> Changeable<MyStruct> = Changeable.write(hamburgers, at: \.favoriteFood, shouldChange: { _, _ in false })
        let next = Changeable(value: MyStruct(favoriteFood: "kale", name: "")) >>- writeHamburgers
        XCTAssertFalse(next.hasChanged)
        XCTAssertEqual(next.value.favoriteFood, "kale")
    }

    func testWriteWithShouldChangeFunctionWritesWhenItReturnsTrue() {
        let hamburgers = "hamburgers"
        let writeHamburgers: (MyStruct) -> Changeable<MyStruct> = Changeable.write(hamburgers, at: \.favoriteFood, shouldChange: { _, _ in true })
        let next = Changeable(value: MyStruct(favoriteFood: hamburgers, name: "")) >>- writeHamburgers
        XCTAssertTrue(next.hasChanged)
        XCTAssertEqual(next.value.favoriteFood, hamburgers)
    }

    func testWriteDoesNotChangeUnderlyingValueType() {
        let value = MyStruct(favoriteFood: "hamburgers", name: "foo")
        _ = Changeable(value: value)
            >>- Changeable.write("kale", at: \.favoriteFood)
            >>- Changeable.write("bar", at: \.name)
        XCTAssertEqual(value.favoriteFood, "hamburgers")
        XCTAssertEqual(value.name, "foo")
    }

    class MyClass {
        var favoriteDrink: String
        var name: String

        init(favoriteDrink: String, name: String) {
            self.favoriteDrink = favoriteDrink
            self.name = name
        }
    }

    func testWriteDoesChangeUnderlyingReferenceType() {
        let referenceValue = MyClass(favoriteDrink: "coffee", name: "baz")
        _ = Changeable(value: referenceValue)
            >>- Changeable.write("tea", at: \.favoriteDrink)
            >>- Changeable.write("qux", at: \.name)
        XCTAssertEqual(referenceValue.favoriteDrink, "tea")
        XCTAssertEqual(referenceValue.name, "qux")
    }
}

/// verify to the best of our ability that `Changeable` is a well-formed monad by verifying the laws
/// see here for info on the monad laws: https://wiki.haskell.org/Typeclassopedia#Laws_3
/// ideally we’d use a QuickCheck-style test case generator to verify these laws for as many values as possible, but for now let’s just make sure we’re in the ballpark
class ChangeTrackingTestsMonadLaws: XCTestCase {
    /// left identity: constructing a `Changeable` from a value in “the default fashion” and then flatmapping a function onto that should produce the same value as just applying the function to the original value
    func testChangeableLeftIdentity() {
        let value: Int = 99
        let transform: (Int) -> Changeable<String> = { Changeable(hasChanged: true, value: "\($0)") }
        XCTAssertEqual(
            Changeable(value: value).flatMap(transform).hasChanged,
            transform(value).hasChanged
        )
        XCTAssertEqual(
            Changeable(value: value).flatMap(transform).value,
            transform(value).value
        )
    }

    func testChangeableLeftIdentityBindOperator() {
        let value: Int = 99
        let transform: (Int) -> Changeable<String> = { Changeable(hasChanged: true, value: "\($0)") }
        XCTAssertEqual(
            (Changeable(value: value) >>- transform).hasChanged,
            transform(value).hasChanged
        )
        XCTAssertEqual(
            (Changeable(value: value) >>- transform).value,
            transform(value).value
        )
    }

    /// right identity: constructing a `Changeable` from a value and then flatmapping the function that constructs a `Changeable` in “the default fashion” onto that should change nothing
    func testChangeableRightIdentity() {
        let value: Int = 99
        let transform: (Int) -> Changeable<Int> = { Changeable(value: $0) }
        XCTAssertEqual(
            Changeable(value: value).flatMap(transform).hasChanged,
            transform(value).hasChanged
        )
        XCTAssertEqual(
            Changeable(value: value).flatMap(transform).value,
            transform(value).value
        )
    }

    func testChangeableRightIdentityBindOperator() {
        let value: Int = 99
        let transform: (Int) -> Changeable<Int> = { Changeable(value: $0) }
        XCTAssertEqual(
            (Changeable(value: value) >>- transform).hasChanged,
            transform(value).hasChanged
        )
        XCTAssertEqual(
            (Changeable(value: value) >>- transform).value,
            transform(value).value
        )
    }

    /// associativity: hard mode. Flatmapping a function that consists of flatmapping another function onto a value onto a `Changeable` value should produce the same result as flatmapping `transform1` and `transform2` in sequence
    func testChangeableAssociativity() {
        let value: Int = 99
        let transform1: (Int) -> Changeable<Int> = { Changeable(hasChanged: true, value: $0 + 1) }
        let transform2: (Int) -> Changeable<String> = { Changeable(hasChanged: true, value: "\($0)") }
        XCTAssertEqual(
            Changeable(value: value).flatMap { transform1($0).flatMap(transform2) }.hasChanged,
            (Changeable(value: value).flatMap(transform1)).flatMap(transform2).hasChanged
        )
        XCTAssertEqual(
            Changeable(value: value).flatMap { transform1($0).flatMap(transform2) }.value,
            (Changeable(value: value).flatMap(transform1)).flatMap(transform2).value
        )
    }

    func testChangeableAssociativityBindOperator() {
        let value: Int = 99
        let transform1: (Int) -> Changeable<Int> = { Changeable(hasChanged: true, value: $0 + 1) }
        let transform2: (Int) -> Changeable<String> = { Changeable(hasChanged: true, value: "\($0)") }
        XCTAssertEqual(
            (Changeable(value: value) >>- { transform1($0) >>- transform2 }).hasChanged,
            ((Changeable(value: value) >>- transform1) >>- transform2).hasChanged
        )
        XCTAssertEqual(
            (Changeable(value: value) >>- { transform1($0) >>- transform2 }).value,
            ((Changeable(value: value) >>- transform1) >>- transform2).value
        )
    }
}
