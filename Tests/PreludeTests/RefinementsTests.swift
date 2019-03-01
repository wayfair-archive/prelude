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

private enum NonZero: Refinement {
    typealias RefinedType = Int
    static func isValid(_ value: Int) -> Bool {
        return value != 0
    }
}

private enum NotTwentyTwo: Refinement {
    typealias RefinedType = Int
    static func isValid(_ value: Int) -> Bool {
        return value != 22
    }
}

private enum IsPositive: Refinement {
    typealias RefinedType = Int
    static func isValid(_ value: Int) -> Bool {
        return value > 0
    }
}

private enum IsNegative: Refinement {
    typealias RefinedType = Int
    static func isValid(_ value: Int) -> Bool {
        return value < 0
    }
}

private typealias NonZeroInt = Refined<Int, NonZero>

final class RefinementsTests: XCTestCase {
    func testInitializeRefinedValue() {
        XCTAssertNoThrow(
            try NonZeroInt.init(1)
        )
    }

    func testInitializeRefinedValueThrows() {
        XCTAssertThrowsError(try NonZeroInt.init(0), "what is this parameter for anyway") { error in
            XCTAssertTrue(error is RefinementError)
        }
    }

    func testRefinementOfFunctionSucceeds() {
        XCTAssertNotNil(
            NonZero.of(1)
        )
    }

    func testRefinementOfFunctionFails() {
        XCTAssertNil(
            NonZero.of(0)
        )
    }

    // MARK: - Both

    func testRefinementOfFunctionSucceeds_both() {
        XCTAssertNotNil(
            Both<NonZero, NotTwentyTwo>.of(1)
        )
    }

    func testRefinementOfFunctionFails_both() {
        XCTAssertNil(
            Both<NonZero, NotTwentyTwo>.of(0)
        )

        XCTAssertNil(
            Both<NonZero, NotTwentyTwo>.of(22)
        )
    }

    func testRefinementBoth_leftFunctionSucceeds() {
        guard let both = Both<NonZero, NotTwentyTwo>.of(1) else {
            XCTFail("this should have succeeded")
            return
        }
        let _: Refined<Int, NonZero> = left(both)
    }

    func testRefinementBoth_rightFunctionSucceeds() {
        guard let both = Both<NonZero, NotTwentyTwo>.of(1) else {
            XCTFail("this should have succeeded")
            return
        }
        let _: Refined<Int, NotTwentyTwo> = right(both)
    }

    // MARK: - Not

    func testRefinementOfFunctionSucceeds_not() {
        XCTAssertNotNil(
            Not<NotTwentyTwo>.of(22)
        )
    }

    func testRefinementOfFunctionFails_not() {
        XCTAssertNil(
            Not<NotTwentyTwo>.of(1)
        )
    }

    // MARK: - OneOf

    func testRefinementOfFunctionSucceeds_oneOf() {
        XCTAssertNotNil(
            OneOf<IsPositive, IsNegative>.of(1)
        )

        XCTAssertNotNil(
            OneOf<IsPositive, IsNegative>.of(-1)
        )
    }

    func testRefinementOfFunctionFails_oneOf() {
        XCTAssertNil(
            OneOf<IsPositive, IsNegative>.of(0)
        )
    }

    func testRefinementOneOf_leftFunctionSucceeds() {
        guard let oneOf = OneOf<IsPositive, IsNegative>.of(1) else {
            XCTFail("this should have succeeded")
            return
        }

        XCTAssertNotNil(
            left(oneOf)
        )
    }

    func testRefinementOneOf_leftFunctionFails() {
        guard let oneOf = OneOf<IsPositive, IsNegative>.of(-1) else {
            XCTFail("this should have succeeded")
            return
        }

        XCTAssertNil(
            left(oneOf)
        )
    }

    func testRefinementOneOf_rightFunctionSucceeds() {
        guard let oneOf = OneOf<IsPositive, IsNegative>.of(-1) else {
            XCTFail("this should have succeeded")
            return
        }

        XCTAssertNotNil(
            right(oneOf)
        )
    }

    func testRefinementOneOf_rightFunctionFails() {
        guard let oneOf = OneOf<IsPositive, IsNegative>.of(1) else {
            XCTFail("this should have succeeded")
            return
        }

        XCTAssertNil(
            right(oneOf)
        )
    }

    func testRefinementOneOf_bothFunctionSucceeds() {
        guard let oneOf = OneOf<IsPositive, NotTwentyTwo>.of(1) else {
            XCTFail("this should have succeeded")
            return
        }

        XCTAssertNotNil(
            both(oneOf)
        )
    }

    func testRefinementOneOf_bothFunctionFails() {
        guard let oneOf = OneOf<IsPositive, NotTwentyTwo>.of(22) else {
            XCTFail("this should have succeeded")
            return
        }

        XCTAssertNil(
            both(oneOf)
        )
    }
}
