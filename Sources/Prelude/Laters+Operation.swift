//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation

public extension Later where Output == Void {
    func asOperation() -> LaterOperation<Self> {
        LaterOperation(upstream: self)
    }
}

public final class LaterOperation<L: Later>: Operation {
    private let upstream: L

    public override var isAsynchronous: Bool {
        true
    }

    private var _isExecuting: Bool {
        willSet {
            willChangeValue(for: \.isExecuting)
        }
        didSet {
            didChangeValue(for: \.isExecuting)
        }
    }
    public override var isExecuting: Bool {
        _isExecuting
    }

    private var _isFinished: Bool {
        willSet {
            willChangeValue(for: \.isFinished)
        }
        didSet {
            didChangeValue(for: \.isFinished)
        }
    }
    public override var isFinished: Bool {
        _isFinished
    }

    fileprivate init(upstream: L) {
        self.upstream = upstream

        _isExecuting = false
        _isFinished = false
    }

    public override func start() {
        guard !isCancelled else {
            _isFinished = true
            return
        }

        _isExecuting = true
        upstream.run { _ in
            self._isExecuting = false
            self._isFinished = true
        }
    }
}
