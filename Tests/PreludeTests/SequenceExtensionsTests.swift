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

final class SequenceExtensionsTests: XCTestCase {
    func testInterspersed_doesntAlterAnEmptySequence() {
        XCTAssertEqual(
            [Int](),
            Array([Int]().interspersed(999))
        )
    }

    func testInterspersed_doesntAlterASingletonSequence() {
        XCTAssertEqual(
            [1],
            Array([1].interspersed(999))
        )
    }

    func testInterspersed_fiveElements() {
        XCTAssertEqual(
            [1, 999, 2, 999, 3, 999, 4, 999, 5],
            Array([1, 2, 3, 4, 5].interspersed(999))
        )
    }
}
