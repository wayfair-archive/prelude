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

final class PipeForwardTests: XCTestCase {
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
