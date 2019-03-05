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

Int.GreaterThanZero.of(1)

Int.GreaterThanZero.of(-99)

Int.GreaterThanZero.of(1) == Int.GreaterThanZero.of(1)

let foo: [Refined<Int, Int.GreaterThanZero>] = [-1, 0, 1, 2, 3].refineMap()

let bar = [-1, 0, 1, 2, 3].refineMap(Int.GreaterThanZero.self)

foo == bar

String.NonEmpty.of("foo")

String.NonEmpty.of("")
