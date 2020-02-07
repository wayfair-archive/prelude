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

// MARK: - DispatchAsync

public extension Laters {
    struct DispatchAsync<L: Later> {
        fileprivate let queue: DispatchQueue
        fileprivate let upstream: L
    }
}
extension Laters.DispatchAsync: Later {
    public typealias Output = L.Output

    public func run(_ next: @escaping (L.Output) -> Void) {
        upstream.run { value in
            self.queue.async { next(value) }
        }
    }

    public func dispatchAsync(on queue: DispatchQueue) -> Laters.DispatchAsync<L> {
        // overload for when two `dispatchAsync`s are in a row. We only need the last one (there’s no need to dispatch twice)
        .init(queue: queue, upstream: upstream)
    }
}
public extension Later {
    func dispatchAsync(on queue: DispatchQueue) -> Laters.DispatchAsync<Self> {
        .init(queue: queue, upstream: self)
    }
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

// MARK: - Fold

public extension Laters {
    struct Fold<A, B, L, E> where L: Later, L.Output == Result<A, E> {
        fileprivate let transformValue: (A) -> B
        fileprivate let transformError: (E) -> B
        fileprivate let upstream: L
    }
}
extension Laters.Fold: Later {
    public typealias Output = B

    public func run(_ next: @escaping (B) -> Void) {
        upstream.run { result in
            let nextValue: B
            switch result {
            case .failure(let error):
                nextValue = self.transformError(error)
            case .success(let value):
                nextValue = self.transformValue(value)
            }
            next(nextValue)
        }
    }
}
public extension Later {
    func fold<A, B, E>(transformValue: @escaping (A) -> B, transformError: @escaping (E) -> B) -> Laters.Fold<A, B, Self, E> {
        .init(transformValue: transformValue, transformError: transformError, upstream: self)
    }

    func replaceError<A, E>(_ replaceError: @autoclosure @escaping () -> A) -> Laters.Fold<A, A, Self, E> {
        .init(transformValue: id, transformError: { _ in replaceError() }, upstream: self)
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

// MARK: - MapSuccess

public extension Laters {
    struct MapSuccess<A, B, L, E> where L: Later, L.Output == Result<A, E> {
        fileprivate let transform: (A) -> B
        fileprivate let upstream: L
    }
}
extension Laters.MapSuccess: Later {
    public typealias Output = Result<B, E>
    public func run(_ next: @escaping (Result<B, E>) -> Void) {
        upstream.run { result in
            let nextValue = result.map(self.transform)
            next(nextValue)
        }
    }
}
public extension Later {
    func mapSuccess<A, B, E>(_ transform: @escaping (A) -> B) -> Laters.MapSuccess<A, B, Self, E> where Output == Result<A, E> {
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

// MARK: - TryMapSuccess

public extension Laters {
    struct TryMapSuccess<A, B, L> where L: Later, L.Output == Result<A, Error> {
        fileprivate let transform: (A) throws -> B
        fileprivate let upstream: L
    }
}
extension Laters.TryMapSuccess: Later {
    public typealias Output = Result<B, Error>

    public func run(_ next: @escaping (Result<B, Error>) -> Void) {
        upstream.run { result in
            let nextValue = result.flatMap { value in Result { try self.transform(value) } }
            next(nextValue)
        }
    }
}
public extension Later {
    func tryMapSuccess<A, B>(_ transform: @escaping (A) throws -> B) -> Laters.TryMapSuccess<A, B, Self> where Output == Result<A, Error> {
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
    fileprivate let upstream: (@escaping (A) -> Void) -> Void
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
public extension AnyLater where A == Void {
    init(_ upstream: @escaping (@escaping () -> Void) -> Void) {
        // Q: When calling this function in Swift 4 or later, you must pass a '()' tuple; did you mean for the input type to be '()'?
        // A: No
        func f(_ v: @escaping (Void) -> Void) {
            upstream { v(()) }
        }
        self.upstream = f
    }
}
public extension AnyLater {
    init(_ upstream: @escaping (@escaping (A) -> Void) -> Void) {
        self.upstream = upstream
    }

    init<T, U>(_ upstream: @escaping (@escaping (T, U) -> Void) -> Void) where A == (T, U) {
        func f(_ tuple: @escaping ((T, U)) -> Void) {
            upstream { first, second in tuple((first, second)) }
        }
        self.upstream = f
    }

    init<T, U, V>(_ upstream: @escaping (@escaping (T, U, V) -> Void) -> Void) where A == (T, U, V) {
        func f(_ triple: @escaping ((T, U, V)) -> Void) {
            upstream { first, second, third in triple((first, second, third)) }
        }
        self.upstream = f
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

        public init(request: URLRequest, session: URLSession) {
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
