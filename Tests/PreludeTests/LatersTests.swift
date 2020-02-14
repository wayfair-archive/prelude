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

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class LatersTests: XCTestCase {
    func testLater() {
        let expect = expectation(description: "later")
        sendTrue().run {
            XCTAssertTrue($0)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testLaterDispatchAsync() {
        var testValue = false

        let expect = expectation(description: "later")
        sendTrue()
            .dispatchAsync(on: .global())
            .run { value in
                // if we don’t deadlock here then the test passes 😂
                DispatchQueue.main.sync {
                    testValue = value
                    expect.fulfill()
                }
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertTrue(testValue)
    }

    func testLaterDispatchAsyncTwice() {
        var testValue = false

        let expect = expectation(description: "later")
        sendTrue()
            .dispatchAsync(on: .global())
            .dispatchAsync(on: .global())
            .run { value in
                // if we don’t deadlock here then the test passes 😂
                DispatchQueue.main.sync {
                    testValue = value
                    expect.fulfill()
                }
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertTrue(testValue)
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

    func testLaterFoldFailure() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { _ in throw NSError(domain: "later", code: 99, userInfo: nil) }
        .fold(
            transformValue: { _ -> Int in XCTFail("should not be called"); return 0 },
            transformError: { error in return (error as NSError).code }
        ).run { value in
            testValue = value
            expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(99, testValue)
    }

    func testLaterFoldSuccess() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { $0 }
        .fold(
            transformValue: { $0 ? 88 : 1 },
            transformError: { _ -> Int in XCTFail("should not be called"); return 0 }
        ).run { value in
            testValue = value
            expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(88, testValue)
    }

    func testLaterReplaceError() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { _ in throw NSError(domain: "later", code: 99, userInfo: nil) }
            .replaceError(88)
            .run { value in
                testValue = value
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(88, testValue)
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

    func testLaterMapSuccessSucceeds() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { $0 }
            .mapSuccess{ "\($0)" }
            .run { result in
                switch result {
                case .failure: XCTFail("should not be reached")
                case .success(let stringValue): testValue = stringValue
                }
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("true", testValue)
    }

    func testLaterMapSuccessFailure() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { _ in throw NSError(domain: "later", code: 99, userInfo: nil) }
            .mapSuccess{ XCTFail("should not be reached") }
            .run { result in
                switch result {
                case .failure(let error): testValue = (error as NSError).code
                case .success: XCTFail("should not be reached")
                }
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(99, testValue)
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

    func testLaterTryMapSuccessSucceeds() {
        var testValue = ""

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { !$0 }
            .tryMapSuccess { "\($0)" }
            .run { result in
                switch result {
                case .failure: XCTFail("should not be reached")
                case .success(let stringValue): testValue = stringValue
                }
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("false", testValue)
    }

    func testLaterTryMapSuccessFails() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap(id)
            .tryMapSuccess { _ in throw NSError(domain: "later", code: 99, userInfo: nil) }
            .run { result in
                switch result {
                case .failure(let error): testValue = (error as NSError).code
                case .success: XCTFail("should not be reached")
                }
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(99, testValue)
    }

    func testLaterTryMapSuccessShortCircuits() {
        var testValue = 0

        let expect = expectation(description: "later")
        sendTrue()
            .tryMap { _ in throw NSError(domain: "later", code: 99, userInfo: nil) }
            .tryMapSuccess { XCTFail("should not be reached") }
            .run { result in
                switch result {
                case .failure(let error): testValue = (error as NSError).code
                case .success: XCTFail("should not be reached")
                }
                expect.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual(99, testValue)
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

    func testLaterProcessURLSessionCallback() throws {
        let data = "test".data(using: .utf8)!
        let response = HTTPURLResponse(url: URL(string: "https://httpbin.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        let error = NSError(domain: "later", code: 99, userInfo: nil)

        let r1 = try process(data: data, response: response, error: nil)
        guard case .success(let tuple1) = r1 else {
            XCTFail()
            return
        }
        XCTAssertEqual(data, tuple1.0)
        XCTAssertEqual(response, tuple1.1)

        let r2 = try process(data: nil, response: response, error: error)
        guard case .failure(let error2) = r2 else {
            XCTFail()
            return
        }
        XCTAssertEqual(error, error2 as NSError)

        let r3 = try process(data: nil, response: response, error: nil)
        guard case .success(let tuple3) = r3 else {
            XCTFail()
            return
        }
        XCTAssertEqual(Data(), tuple3.0)
        XCTAssertEqual(response, tuple3.1)

        let r4 = try process(data: nil, response: nil, error: error)
        guard case .failure(let error4) = r4 else {
            XCTFail()
            return
        }
        XCTAssertEqual(error, error4 as NSError)

        XCTAssertThrowsError(
            try process(data: nil, response: nil, error: nil)
        )
        XCTAssertThrowsError(
            try process(data: data, response: response, error: error)
        )
    }
}

private func sendTrue() -> Laters.After<Bool> {
    .init(deadline: .now() + 0.1, queue: .main, value: true)
}
