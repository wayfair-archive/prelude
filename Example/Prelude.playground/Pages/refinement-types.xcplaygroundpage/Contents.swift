//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Prelude

//
// Refinement types
//

enum GreaterThanZero: Refinement {
    typealias RefinedType = Double
    static func isValid(_ value: Double) -> Bool {
        return value > 0.0
    }
}

GreaterThanZero.of(1)

GreaterThanZero.of(-99)

enum NotTwentyTwo: Refinement {
    typealias RefinedType = Double
    static func isValid(_ value: Double) -> Bool {
        return value != 22.0
    }
}

Both<GreaterThanZero, NotTwentyTwo>.of(22)

Both<GreaterThanZero, NotTwentyTwo>.of(-99)

Both<GreaterThanZero, NotTwentyTwo>.of(100)

typealias MyRefinedDouble = Refined<Double, Both<GreaterThanZero, NotTwentyTwo>>

try MyRefinedDouble.init(9)

//try MyRefinedDouble.init(22) // will `throw`

let myDouble = MyRefinedDouble.init(9)

left(myDouble)

let anotherDouble = OneOf<GreaterThanZero, NotTwentyTwo>.of(22)!

both(anotherDouble)

left(anotherDouble)

right(anotherDouble)
