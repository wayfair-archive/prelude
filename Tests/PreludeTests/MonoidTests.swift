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

final class MonoidTests: XCTestCase {
    func testOptionalConformance() {
        let value1: Last<Int>? = .init(value: 9)
        let value2: Last<Int>? = .init(value: 99)

        XCTAssertEqual(
            99,
            (value1 <> value2)?.value
        )
        XCTAssertEqual(
            9,
            (.empty <> value1)?.value
        )
        XCTAssertEqual(
            99,
            (value2 <> .empty)?.value
        )
    }
}
