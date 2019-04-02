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

func increment(_ value: Double) -> Double {
    return value + 1
}

func double(_ value: Double) -> Double {
    return value + value
}

func square(_ value: Double) -> Double {
    return value * value
}

func strAppend(_ toAppend: String) -> (String) -> String {
    return { $0 + toAppend }
}

final class PipeForwardTests: XCTestCase {

    func testDouble() {
        let incDoubleSquareFive = 5
          |> increment
          |> double
          |> square
        XCTAssertEqual(144, incDoubleSquareFive)
    }

    func testString() {
        let appendingString = " "
            |> strAppend("a")
            |> strAppend("b")
            |> strAppend("c")
        XCTAssertEqual(" abc", appendingString)
    }
}

final class ComposeTests: XCTestCase {

    let doubleThenIncrement = double >>> increment

    let incrementThenDouble = increment >>> double

    let incrementThenDoubleThenSquare = increment >>> double >>> square

    let squareThenIncrementThenDouble = square >>> increment >>> double

    func testDoubleThenIncrement() {
        XCTAssertEqual(3 * 2 + 1, doubleThenIncrement(3))
    }

    func testIncrementThenDouble() {
        XCTAssertEqual((3 + 1) * 2, incrementThenDouble(3))
    }

    func testIncrementDoubleSquare() {
        let value: Double = 3
        let incrementedValue = increment(value)
        let incrementedDoubledValue = double(incrementedValue)
        let incrementedDoubledSquaredValue = square(incrementedDoubledValue)

        XCTAssertEqual(incrementedDoubledSquaredValue, incrementThenDoubleThenSquare(value))
    }

    func testSquareIncrementDouble() {
        let value: Double = 3
        let squaredValue = square(value)
        let squaredIncrementedValue = increment(squaredValue)
        let squaredIncrementedDoubledValue = double(squaredIncrementedValue)

        XCTAssertEqual(squaredIncrementedDoubledValue, squareThenIncrementThenDouble(value))
    }

    func testPrecedenceWithPipe() {
        let fiveIncrementThenDouble = 5 |> increment >>> double

        XCTAssertEqual(fiveIncrementThenDouble, (5 + 1) * 2)
    }
}
