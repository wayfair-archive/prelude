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

final class LatersOperationTests: XCTestCase {
    private var operationQueue: OperationQueue!

    override func setUp() {
        super.setUp()

        self.operationQueue = .init()
    }

    override func tearDown() {
        operationQueue.cancelAllOperations()
        operationQueue = nil

        super.tearDown()
    }

    func testOneOperation() {
        let expect = expectation(description: "op")
        var testValue = false

        let myOperation = sendTrue()
            .tap { testValue = $0 }
            .map { _ in () }
            .tap { _ in expect.fulfill() }
            .asOperation()
        operationQueue.addOperation(myOperation)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertTrue(testValue)
    }

    // the following test is broken on Linux because `NSOperation` dependencies are broken on Linux on < Swift 5.2. We can re-enable the test once we get onto 5.2. see https://bugs.swift.org/browse/SR-12138
    #if os(Linux)
    func testThreeOperationsWithDependencies() {
    }
    #else
    func testThreeOperationsWithDependencies() {
        let expect = expectation(description: "op")

        var testValue = ""

        let appendFoo = sendTrue()
            .map { _ in () }
            .tap { testValue += "foo" }
            .asOperation()

        let appendBar = sendTrue()
            .map { _ in () }
            .tap { testValue += "bar" }
            .asOperation()
        appendBar.addDependency(appendFoo)

        let fulfillExpectation = sendTrue()
            .map { _ in () }
            .tap { expect.fulfill() }
            .asOperation()
        fulfillExpectation.addDependency(appendBar)

        operationQueue.addOperations([fulfillExpectation, appendBar, appendFoo], waitUntilFinished: false)

        waitForExpectations(timeout: 2, handler: nil)

        XCTAssertEqual("foobar", testValue)
    }
    #endif
}

private func sendTrue() -> Laters.After<Bool> {
    .init(deadline: .now() + 0.1, queue: .main, value: true)
}
