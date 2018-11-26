//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

public extension Sequence {
    /// given a `Sequence` (`self`), return a new sequence that, when iterated, contains `newValue` in between each of the elements of the original sequence
    ///
    /// e.g. [1, 2, 3].interspersed(999) // [1, 999, 2, 999, 3]
    ///
    /// - Parameter newValue: the value to intersperse throughout the original collection
    /// - Returns: a new `Sequence` with `newValue` interspersed between each original element
    func interspersed(_ newValue: Element) -> AnySequence<Element> {
        return AnySequence { () -> AnyIterator<Element> in
            var iterator = self.makeIterator()
            var intersperse = false
            var lastValue = iterator.next()
            return AnyIterator {
                defer { intersperse.toggle() }
                if intersperse, lastValue != nil {
                    return newValue
                } else {
                    defer { lastValue = iterator.next() }
                    return lastValue
                }
            }
        }
    }
}

#if swift(>=4.1.50)
#else
extension Bool {
    mutating func toggle() {
        self = !self
    }
}
#endif
