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

final class ReducersTests: XCTestCase {
    private let appendStrings = Reducer<String, String> { string, item in
        string += item
    }

    private let numbers = [1, 2, 3]

    private let strings = ["foo", "bar", "baz"]

    private let sumIntegers = Reducer<Int, Int> { sum, int in
        sum += int
    }

    func testReducerUpdate() {
        XCTAssertEqual(
            "foobarbaz",
            strings.reduce(into: "", appendStrings.updateAccumulatingResult)
        )
        XCTAssertEqual(
            6,
            numbers.reduce(into: 0, sumIntegers.updateAccumulatingResult)
        )
    }

    func testReducer_nextProducesIdenticalResults() {
        XCTAssertEqual(
            strings.reduce(into: "", appendStrings.updateAccumulatingResult),
            strings.reduce("", appendStrings.next)
        )
        XCTAssertEqual(
            numbers.reduce(into: 0, sumIntegers.updateAccumulatingResult),
            numbers.reduce(0, sumIntegers.next)
        )
    }

    func testReducer_nextPartialResultConstruction_producesIdenticalResults() {
        let appendStringsAlt: Reducer<String, String> = .nextPartialResult { acc, element in
            return acc + element
        }
        XCTAssertEqual(
            strings.reduce(into: "", appendStrings.updateAccumulatingResult),
            strings.reduce(into: "", appendStringsAlt.updateAccumulatingResult)
        )

        let sumIntegersAlt: Reducer<Int, Int> = .nextPartialResult { acc, element in
            return acc + element
        }
        XCTAssertEqual(
            numbers.reduce(into: 0, sumIntegers.updateAccumulatingResult),
            numbers.reduce(into: 0, sumIntegersAlt.updateAccumulatingResult)
        )
    }

    func testReducerFollowedBy() {
        let anotherStringReducer = Reducer<String, String> { acc, element in
            acc += (element.uppercased() + ",")
        }
        XCTAssertEqual(
            "fooFOO,barBAR,bazBAZ,",
            strings.reduce(into: "", appendStrings.followed(by: anotherStringReducer).updateAccumulatingResult)
        )
    }

    func testReducerFollowedByOperator() {
        let anotherStringReducer = Reducer<String, String> { acc, element in
            acc += (element.uppercased() + ",")
        }
        XCTAssertEqual(
            "fooFOO,foobarBAR,barbazBAZ,baz",
            strings.reduce(into: "", (appendStrings <> anotherStringReducer <> appendStrings).updateAccumulatingResult)
        )
    }

    func testReducerPullback() {
        let transform: (String) -> Int = { $0.count }
        XCTAssertEqual(
            9,
            strings.reduce(into: 0, sumIntegers.pullback(transform))
        )
    }

    func testReducerSequenceExtensions() {
        XCTAssertEqual("foobarbaz", strings.reduce(into: "", appendStrings))
        XCTAssertEqual("foobarbaz", strings.reduce("", appendStrings))
        XCTAssertEqual(6, numbers.reduce(into: 0, sumIntegers))
        XCTAssertEqual(6, numbers.reduce(0, sumIntegers))
    }
}

final class ReducersTestsSemigroup: XCTestCase {
    let myReducer1 = Reducer<[String], Int> { acc, element in
        acc += ["\(element + 1)"]
    }

    let myReducer2 = Reducer<[String], Int> { acc, element in
        acc += ["\(element + 2)"]
    }

    let myReducer3 = Reducer<[String], Int> { acc, element in
        acc += ["\(element + 3)"]
    }

    func testAssociativity3() {
        let groupFirst = (myReducer1 <> myReducer2) <> myReducer3
        let groupLast = myReducer1 <> (myReducer2 <> myReducer3)
        XCTAssertEqual(
            [100, 101, 102].reduce(["1"], groupFirst),
            [100, 101, 102].reduce(["1"], groupLast)
        )
    }
}

final class ReducersTestsMonoid: XCTestCase {
    let myReducer1 = Reducer<[String], Int> { acc, element in
        acc += ["\(element + 1)"]
    }

    func testLeftIdentity() {
        XCTAssertEqual(
            [100, 101, 102].reduce(["1"], myReducer1),
            [100, 101, 102].reduce(["1"], (Reducer.empty <> myReducer1))
        )
    }

    func testRightIdentity() {
        XCTAssertEqual(
            [100, 101, 102].reduce(["1"], myReducer1),
            [100, 101, 102].reduce(["1"], (myReducer1 <> Reducer.empty))
        )
    }
}
