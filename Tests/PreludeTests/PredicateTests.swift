//
//  PredicateTests.swift
//  Prelude
//
//  Created by Peter Tomaselli on 3/7/19.
//

@testable import Prelude
import XCTest

private let greaterThanTen: Predicate<Int> = .init { $0 > 10 }

private let greaterThanZero: Predicate<Int> = .init { $0 > 0 }

final class PredicateTests: XCTestCase {
    func testPredicate() {
        XCTAssertTrue(greaterThanZero.contains(1))
        XCTAssertFalse(greaterThanZero.contains(-1))
    }

    func testIntersection() {
        let myPredicate = greaterThanZero.intersection(greaterThanTen)
        XCTAssertTrue(myPredicate.contains(11))
        XCTAssertFalse(myPredicate.contains(9))
        XCTAssertFalse(myPredicate.contains(-1))
    }

    func testSubtracting() {
        let myPredicate = greaterThanZero.subtracting(greaterThanTen)
        XCTAssertTrue(myPredicate.contains(1))
        XCTAssertFalse(myPredicate.contains(11))
        XCTAssertFalse(myPredicate.contains(-1))
    }

    func testSymmetricDifference() {
        let lessThanTen: Predicate<Int> = .init { $0 < 10 }
        let myPredicate = greaterThanZero.symmetricDifference(lessThanTen)
        XCTAssertTrue(myPredicate.contains(-1))
        XCTAssertTrue(myPredicate.contains(11))
        XCTAssertFalse(myPredicate.contains(9))
    }

    func testUnion() {
        let oneToFive: Predicate<Int> = .init { 1...5 ~= $0 }
        let sevenToTen: Predicate<Int> = .init { 7...10 ~= $0 }
        let myPredicate = oneToFive.union(sevenToTen)
        XCTAssertTrue(myPredicate.contains(2))
        XCTAssertTrue(myPredicate.contains(8))
        XCTAssertFalse(myPredicate.contains(0))
        XCTAssertFalse(myPredicate.contains(6))
        XCTAssertFalse(myPredicate.contains(11))
    }

    func testInverse() {
        let myPredicate = greaterThanZero.complement
        XCTAssertTrue(myPredicate.contains(0))
        XCTAssertTrue(myPredicate.contains(-1))
        XCTAssertFalse(myPredicate.contains(1))
    }

    func testPullback() {
        let myPredicate: Predicate<String> = greaterThanZero.pullback { $0.count }
        XCTAssertTrue(myPredicate.contains("foobar"))
        XCTAssertFalse(myPredicate.contains(""))
    }

    func testIdentity() {
        XCTAssertTrue(
            (greaterThanZero <> .empty).contains(1))
        XCTAssertFalse(
            (greaterThanZero <> .empty).contains(-1))
        XCTAssertTrue(
            (.empty <> greaterThanZero).contains(1))
        XCTAssertFalse(
            (.empty <> greaterThanZero).contains(-1))
    }
}
