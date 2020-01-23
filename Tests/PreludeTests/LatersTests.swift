//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation
@testable import Prelude
import XCTest

final class LatersTests: XCTestCase {
    func testLater() {
        let expect = expectation(description: "later")
        sendTrue().run {
            XCTAssertTrue($0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testLaterFlatMap() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .flatMap { $0 ? Laters.After(deadline: .now() + 0.1, queue: .main, value: "foo") : Laters.After(deadline: .now() + 0.1, queue: .main, value: "bar") }
            .tap { testValue = $0 }
            .run { _ in expect.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("foo", testValue)
    }

    func testLaterMap() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .map { "\($0)" }
            .tap { testValue = $0 }
            .run { _ in expect.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("true", testValue)
    }

    func testLaterTap() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tap { _ in testValue += 1 }
            .run { _ in expect.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(1, testValue)
    }


    private struct MyError: Error { }

    func testLaterTryMapNoThrow() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { "\($0)" }
            .run { result in
                guard case .success(let stringValue) = result else {
                    XCTFail()
                    return
                }
                testValue = stringValue
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("true", testValue)
    }

    func testLaterTryMapThrows() {
        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { _ in throw MyError() }
            .run { result in
                guard case .failure = result else {
                    XCTFail()
                    return
                }
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}

final class LatersErasedTests: XCTestCase {
    func testLater() {
        let expect = expectation(description: "later")
        sendTrue()
            .eraseToAnyLater()
            .run {
                XCTAssertTrue($0)
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testLaterExecute() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tap { _ in testValue += 1 }
            .eraseToAnyLater()
            .run { _ in expect.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(1, testValue)
    }

    func testLaterFlatMap() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .flatMap { $0 ? Laters.After(deadline: .now() + 0.1, queue: .main, value: "foo") : Laters.After(deadline: .now() + 0.1, queue: .main, value: "bar") }
            .tap { testValue = $0 }
            .eraseToAnyLater()
            .run { _ in expect.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("foo", testValue)
    }

    func testLaterMap() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .map { "\($0)" }
            .tap { testValue = $0 }
            .eraseToAnyLater()
            .run { _ in expect.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("true", testValue)
    }

    private struct MyError: Error { }

    func testLaterTryMapNoThrow() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { "\($0)" }
            .eraseToAnyLater()
            .run { result in
                guard case .success(let stringValue) = result else {
                    XCTFail()
                    return
                }
                testValue = stringValue
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("true", testValue)
    }

    func testLaterTryMapThrows() {
        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { _ in throw MyError() }
            .eraseToAnyLater()
            .run { result in
                guard case .failure = result else {
                    XCTFail()
                    return
                }
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}

private func sendTrue() -> Laters.After<Bool> {
    .init(deadline: .now() + 0.1, queue: .main, value: true)
}
