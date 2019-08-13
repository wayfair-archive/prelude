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

private struct BoolAnyS { let boolValue: Bool }

extension BoolAnyS: Semigroup {
    static func <>(_ lhs: BoolAnyS, _ rhs: BoolAnyS) -> BoolAnyS {
        return BoolAnyS.init <| (lhs.boolValue || rhs.boolValue)
    }
}

final class SemigroupTests: XCTestCase {
    func testCombineOperator() {
        let myVal = BoolAnyS(boolValue: false) <> BoolAnyS(boolValue: false)
        XCTAssertEqual(
            false,
            myVal.boolValue
        )

        let anotherVal = myVal <> BoolAnyS(boolValue: false)
        XCTAssertEqual(
            false,
            anotherVal.boolValue
        )

        let lastVal = anotherVal <> .init(boolValue: true)
        XCTAssertEqual(
            true,
            lastVal.boolValue
        )
    }
}

final class FirstAndLastSemigroupTests: XCTestCase {
    func testFirstCombine() {
        XCTAssertEqual(
            1,
            (First(value: 1) <> First(value: 2) <> First(value: 99)).value
        )
    }

    func testLastCombine() {
        XCTAssertEqual(
            99,
            (Last(value: 1) <> Last(value: 2) <> Last(value: 99)).value
        )
    }
}

final class TupleOperatorsTests: XCTestCase {
    func testBigTuple() {
        let val1 = (First(value: 1), First(value: 99), Last(value: "a"))
        let val2 = (First(value: 999), First(value: -999), Last(value: "b"))
        let val3 = (First(value: 0), First(value: 0), Last(value: "hello world!"))
        let result = val1 <> val2 <> val3
        XCTAssertEqual(1, result.0.value)
        XCTAssertEqual(99, result.1.value)
        XCTAssertEqual("hello world!", result.2.value)

        let backwards = val3 <> val2 <> val1
        XCTAssertEqual(0, backwards.0.value)
        XCTAssertEqual(0, backwards.1.value)
        XCTAssertEqual("a", backwards.2.value)
    }
}

final class SemigroupMonoidConformanceTests: XCTestCase {
    private typealias MyMonoid = BoolAnyS?

    func testCombine() {
        let val1: MyMonoid = BoolAnyS(boolValue: false)
        let val2: MyMonoid = BoolAnyS(boolValue: true)

        XCTAssertEqual(
            true,
            (val1 <> val2)?.boolValue
        )
    }

    func testIdentity() {
        let myVal: MyMonoid = BoolAnyS(boolValue: true)

        XCTAssertEqual(
            myVal?.boolValue,
            (myVal <> .empty)?.boolValue
        )
        XCTAssertEqual(
            myVal?.boolValue,
            (.empty <> myVal)?.boolValue
        )
    }
}

private struct BoolAnyM { let boolValue: Bool }

extension BoolAnyM: Monoid {
    static var empty: BoolAnyM { return .init(boolValue: false) }

    static func <>(_ lhs: BoolAnyM, _ rhs: BoolAnyM) -> BoolAnyM {
        return .init(boolValue: lhs.boolValue || rhs.boolValue)
    }
}

final class MonoidTests: XCTestCase {
    func testCombine() {
        let val1 = BoolAnyM(boolValue: false)
        let val2 = BoolAnyM(boolValue: true)

        XCTAssertEqual(
            true,
            (val1 <> val2).boolValue
        )
    }

    func testIdentity() {
        let myVal = BoolAnyM(boolValue: true)

        XCTAssertEqual(
            myVal.boolValue,
            (myVal <> .empty).boolValue
        )
        XCTAssertEqual(
            myVal.boolValue,
            (.empty <> myVal).boolValue
        )
    }

    func testConcat() {
        let vals: [BoolAnyM] = [
            .init(boolValue: false),
            .empty,
            .init(boolValue: false),
            .init(boolValue: false),
            .init(boolValue: true),
            .empty
        ]

        XCTAssertEqual(
            true,
            vals.concat().boolValue
        )
    }
}
