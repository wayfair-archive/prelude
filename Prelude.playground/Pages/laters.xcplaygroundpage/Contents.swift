//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation
import Prelude

Laters.After(deadline: .now() + 1, queue: .main, value: 1)
    .execute { print("first step: \($0)") }
    .flatMap { Laters.After(deadline: .now() + $0, queue: .main, value: "hello") }
    .tryMap { "\($0) world" }
    .eraseToAnyLater()
    .run { print("---> \($0)") }

import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
