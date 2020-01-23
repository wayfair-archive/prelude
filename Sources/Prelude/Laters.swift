//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

public protocol Later {
    associatedtype Output
    func run(_ next: @escaping (Output) -> Void)
}
public enum Laters {
}

// MARK: - FlatMap

public extension Laters {
    struct FlatMap<L: Later, B: Later> {
        fileprivate let transform: (L.Output) -> B
        fileprivate let upstream: L
    }
}
extension Laters.FlatMap: Later {
    public typealias Output = B.Output

    public func run(_ next: @escaping (B.Output) -> Void) {
        upstream.run { value in
            let nextLater = self.transform(value)
            nextLater.run { innerValue in
                next(innerValue)
            }
        }
    }
}
public extension Later {
    func flatMap<B: Later>(_ transform: @escaping (Output) -> B) -> Laters.FlatMap<Self, B> {
        .init(transform: transform, upstream: self)
    }
}

// MARK: - Map

public extension Laters {
    struct Map<L: Later, B> {
        fileprivate let transform: (L.Output) -> B
        fileprivate let upstream: L
    }
}
extension Laters.Map: Later {
    public typealias Output = B

    public func run(_ next: @escaping (B) -> Void) {
        upstream.run { value in
            let nextValue = self.transform(value)
            next(nextValue)
        }
    }
}
public extension Later {
    func map<B>(_ transform: @escaping (Output) -> B) -> Laters.Map<Self, B> {
        .init(transform: transform, upstream: self)
    }
}

// MARK: - Tap

public extension Laters {
    struct Tap<L: Later> {
        fileprivate let execute: (L.Output) -> Void
        fileprivate let upstream: L
    }
}
extension Laters.Tap: Later {
    public typealias Output = L.Output

    public func run(_ next: @escaping (L.Output) -> Void) {
        upstream.run { value in
            self.execute(value)
            next(value)
        }
    }
}
public extension Later {
    func tap(_ execute: @escaping (Output) -> Void) -> Laters.Tap<Self> {
        .init(execute: execute, upstream: self)
    }
}

// MARK: - TryMap

public extension Laters {
    struct TryMap<L: Later, B> {
        fileprivate let transform: (L.Output) throws -> B
        fileprivate let upstream: L
    }
}
extension Laters.TryMap: Later {
    public typealias Output = Result<B, Error>

    public func run(_ next: @escaping (Result<B, Error>) -> Void) {
        upstream.run { value in
            let result = Result { try self.transform(value) }
            next(result)
        }
    }
}
public extension Later {
    func tryMap<B>(_ transform: @escaping (Self.Output) throws -> B) -> Laters.TryMap<Self, B> {
        .init(transform: transform, upstream: self)
    }
}

// MARK: - After

import Foundation

public extension Laters {
    struct After<A> {
        private let deadline: () -> DispatchTime
        private let queue: DispatchQueue
        private let value: () -> A

        public init(deadline: @autoclosure @escaping () -> DispatchTime, queue: DispatchQueue, value: @autoclosure @escaping () -> A) {
            self.deadline = deadline
            self.queue = queue
            self.value = value
        }
    }
}
extension Laters.After: Later {
    public typealias Output = A

    public func run(_ next: @escaping (A) -> Void) {
        queue.asyncAfter(deadline: deadline(), execute: {
            next(self.value())
        })
    }
}

// MARK: - AnyLater

public struct AnyLater<A> {
    private let upstream: (@escaping (A) -> Void) -> Void

    public init(upstream: @escaping (@escaping (A) -> Void) -> Void) {
        self.upstream = upstream
    }
}
extension AnyLater: Later {
    public typealias Output = A

    public func run(_ next: @escaping (A) -> Void) {
        upstream(next)
    }
}
public extension Later {
    func eraseToAnyLater() -> AnyLater<Output> {
        .init(upstream: self.run)
    }
}

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - DataTask

public extension Laters {
    struct DataTask {
        private let request: URLRequest
        private let session: URLSession

        public init(request: URLRequest, session: URLSession = .shared) {
            self.request = request
            self.session = session
        }
    }
}
extension Laters.DataTask: Later {
    public typealias Output = Result<(Data, URLResponse), Error>

    public func run(_ next: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            guard let data = data, let response = response else {
                if let error = error {
                    next(.failure(error))
                    return
                } else {
                    fatalError("todo")
                }
            }
            next(.success((data, response)))
            return
        }.resume()
    }
}
