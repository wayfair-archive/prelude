//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

public protocol Nat {
    static var intValue: Int { get }
}

public enum Succ<N: Nat>: Nat {
    public static var intValue: Int { return N.intValue + 1 }
}

public enum Zero: Nat {
    public static var intValue: Int { return 0 }
}

public typealias One = Succ<Zero>

public typealias Two = Succ<Succ<Zero>>
