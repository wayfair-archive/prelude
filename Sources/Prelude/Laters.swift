//
// This source file is part of Prelude, an open source project by Wayfair
//
// Copyright (c) 2018 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

/// wrapper for an asynchronous computation, similar to a promise, but lighter-weight. To execute a `Later`, call `run(_:)` and pass a callback function. To extend a `Later` with an additional synchronous step, use `map(_:)`. To extend a `Later` with an additional asynchronous step, use `flatMap(_:)`.
///
/// `Later`s differ from promises and some other async programming constructs in a few key ways:
///   * `Later`s are always lazy: a `Later` never executes any work until its `run(_:)` function is called. This makes their behavior with respect to side-effects more predictable and more controllable by the programmer.
///   * the implementation of `Later` does not include any use of shared memory. This means that execution is simple and more transparent to the programmer: the built-in operators never take any locks, dispatch to any queue “under the hood”, or perform any shenanigans with respect to threads unless specifically instructed by the programmer to do so. On the other hand, this prevents any “combining” or “zipping” operators from being implemented safely.
///   * `Later`s are implemented in a “non-type-erasing” way, similar in style to Apple’s recent Swift framework releases (like SwiftUI and Combine). This means that they should be fast (none of the built in operators require allocating any memory eg. for closures), and that we can perform some optimizations “statically” (for example, we can avoid `DispatchQueue.async`ing twice where it is not needed)
///   * laws! With some hand-waving to account for Swift implementation details, `Later`s form a lawful _monad_ (specifically, the continuation monad), which means that numerous other constructs are trivially implementable on top of these base operators (for example, `>>` or `sequence_` to execute a series of `Later`s serially while discarding their results, `>=>` to compose flatMap-able transformation functions in the absence of a `Later` value to apply them to, and more)
public protocol Later {
    associatedtype Output
    /// execute the work represented by this `Later` and receive the value some time in the future via a callback function
    /// - Parameter next: the callback which will eventually receive a value of type `Output`
    func run(_ next: @escaping (Output) -> Void)
}
/// namespace for various `Later`-related types
public enum Laters {
}

// MARK: - DispatchAsync

/// protocol that represents a type that can return a `DispatchQueue`. We want to be able to distinguish between different queues based on the type that provides them — specifically, we want to be able to statically determine if we are going to call back on the main queue or not. To do so, we’ll define one canonical conformance to this protocol (see `Laters.MainQueue` below) which we know always points to the main queue. Then when we use generic functions that are tagged with `Laters.MainQueue`, we can be sure at compile time that we will be using the main queue
public protocol TaggedQueue {
    func getQueue() -> DispatchQueue
}

public extension Laters {
    struct DispatchAsync<L: Later, T: TaggedQueue> {
        fileprivate let taggedQueue: T
        fileprivate let upstream: L
    }

    /// struct, that conforms to `TaggedQueue`, that contains a `DispatchQueue` value provided at runtime. We can’t make any static guarantees about which queue it will be.
    struct AnyQueue: TaggedQueue {
        private let queue: DispatchQueue

        fileprivate init(queue: DispatchQueue) {
            self.queue = queue
        }

        public func getQueue() -> DispatchQueue {
            queue
        }
    }

    /// struct, that conforms to `TaggedQueue`, that we always know will be pointing at the main queue
    struct MainQueue: TaggedQueue {
        public func getQueue() -> DispatchQueue {
            .main
        }
    }
}
extension Laters.DispatchAsync: Later {
    public typealias Output = L.Output

    public func run(_ next: @escaping (L.Output) -> Void) {
        upstream.run { value in
            self.taggedQueue.getQueue().async { next(value) }
        }
    }

    // MARK: - `DispatchAsync` overloads which flatten two queues into one

    /// given a `Later` (`self`) which performs some work, return a `Later` which performs the same work, but then dispatches asynchronously onto the provided `queue` prior to calling its callback
    /// - Parameter queue: a `DispatchQueue`
    func dispatchAsync(on queue: DispatchQueue) -> Laters.DispatchAsync<L, Laters.AnyQueue> {
        dispatchAsync(taggedQueue: Laters.AnyQueue(queue: queue))
    }

    /// given a `Later` (`self`) which performs some work, return a `Later` which performs the same work, but then dispatches asynchronously onto the provided `TaggedQueue` prior to calling its callback
    /// - Parameter taggedQueue: an instance of a type that conforms to the `TaggedQueue` protocol
    func dispatchAsync<U: TaggedQueue>(taggedQueue: U) -> Laters.DispatchAsync<L, U> {
        .init(taggedQueue: taggedQueue, upstream: upstream)
    }

    /// given a `Later` (`self`) which performs some work, return a `Later` which performs the same work, but then dispatches asynchronously onto the main queue prior to calling its callback
    func dispatchMain() -> Laters.DispatchAsync<L, Laters.MainQueue> {
        dispatchAsync(taggedQueue: Laters.MainQueue())
    }
}
public extension Later {
    /// given a `Later` (`self`) which performs some work, return a `Later` which performs the same work, but then dispatches asynchronously onto the provided `queue` prior to calling its callback
    /// - Parameter queue: a `DispatchQueue`
    func dispatchAsync(on queue: DispatchQueue) -> Laters.DispatchAsync<Self, Laters.AnyQueue> {
        dispatchAsync(taggedQueue: Laters.AnyQueue(queue: queue))
    }

    /// given a `Later` (`self`) which performs some work, return a `Later` which performs the same work, but then dispatches asynchronously onto the provided `TaggedQueue` prior to calling its callback
    /// - Parameter taggedQueue: an instance of a type that conforms to the `TaggedQueue` protocol
    func dispatchAsync<T: TaggedQueue>(taggedQueue: T) -> Laters.DispatchAsync<Self, T> {
        .init(taggedQueue: taggedQueue, upstream: self)
    }

    /// given a `Later` (`self`) which performs some work, return a `Later` which performs the same work, but then dispatches asynchronously onto the main queue prior to calling its callback
    func dispatchMain() -> Laters.DispatchAsync<Self, Laters.MainQueue> {
        dispatchAsync(taggedQueue: Laters.MainQueue())
    }
}

extension Laters.DispatchAsync {
    public func eraseToAnyLater() -> TaggedQueueAnyLater<Output, T> {
        .init(upstream: self.run)
    }
}

// MARK: - MainQueueAnyLater

public typealias MainQueueAnyLater<A> = TaggedQueueAnyLater<A, Laters.MainQueue>

public struct TaggedQueueAnyLater<A, T: TaggedQueue> {
    fileprivate let upstream: (@escaping (A) -> Void) -> Void
}
extension TaggedQueueAnyLater: Later {
    public typealias Output = A

    public func run(_ next: @escaping (A) -> Void) {
        upstream(next)
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
    /// given a `Later` (`self`) that performs some work, produce a new `Later` that performs the original work, plus the additional asynchronous work given by the function `transform`
    /// - Parameter transform: a function that describes the additional work
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
    /// given a `Later` (`self`) that performs some work that may fail (by returning a `Result`), “recover” from the failure by providing two functions that transform a possible next value or error into a third downstream type
    /// - Parameters:
    ///   - transformValue: a function to transform `.success` values into some downstream type
    ///   - transformError: a function to transform `.failure` values into some downstream type
    func fold<A, B, E>(transformValue: @escaping (A) -> B, transformError: @escaping (E) -> B) -> Laters.Fold<A, B, Self, E> {
        .init(transformValue: transformValue, transformError: transformError, upstream: self)
    }

    /// given a `Later` (`self`) that performs some work that may fail (by returning a `Result`), replace any errors produced with a `.success` value instead
    /// - Parameter replaceError: a value to be used in place of any errors that occur
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
    /// given a `Later` (`self`) that performs some work, produce a new `Later` that performs the original work, plus the additional synchronous work given by the function `transform`
    /// - Parameter transform: a function that describes the additional work
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
    /// given a `Later` (`self`) that performs some work that may fail (by returning a `Result`), transform just the `.success` values that may be produced using the given `transform` function. `.failure` values produced will pass through unaffected
    /// - Parameter transform: a transform function
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
    /// given a `Later` (`self`) that performs some work, execute the provided `execute` function with the eventual `Output` of the `Later`, which still passing the value along to subsequent callbacks
    /// - Parameter execute: a function that performs some action with the eventual `Output`
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
    /// given a `Later` (`self`) that performs some work, produce a new `Later` that performs the original work, plus the additional synchronous, possibly failable work given by the throwing function `transform`
    /// - Parameter transform: a function that describes the additional work and that may `throw`
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
    /// given a `Later` (`self`) that performs some work that may fail (by returning a `Result`), transform just the `.success` values that may be produced using the given `transform` function, which itself may `throw`. `.failure` values produced will pass through unaffected
    /// - Parameter transform: a transform function that may `throw`
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

        /// kick-start a `Later` by waiting until the provided `deadline`, then passing the provided `value` out to the callback, on the provided `queue`
        /// - Parameters:
        ///   - deadline: the `deadline` passed to the `queue`’s `asyncAfter(deadline:execute:)` function. This value is evaluated lazily at the time the `run(_:)` function is called (ie. `DispatchTime.now()` will work the way you are expecting it to)
        ///   - queue: a `DispatchQueue`
        ///   - value: a value
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
    func assertEraseToMainQueueAnyLater() -> MainQueueAnyLater<Output> {
        let asserting = tap { _ in
            assert(Thread.isMainThread, "`Laters` assertion failure: this is not actually the main thread")
        }
        return .init(upstream: asserting.run)
    }

    /// erase the type of a `Later` so that it may be more concise and interoperable
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

        /// construct a `Later` which wraps a `URLSessionDataTask` vended by the provided `URLSession`
        /// - Parameters:
        ///   - request: a `URLRequest` used to construct the data task
        ///   - session: the `URLSession` which will vend the task
        public init(request: URLRequest, session: URLSession) {
            self.request = request
            self.session = session
        }
    }
}
/// perform the cursed conversion from a `URLSession` `dataTask` callback into something nicer. The intent is to handle the callback like this:
///   * `data` and `response` are non-nil ==> return `.success((data, response))`
///   * `response` and `error` are non-nil ==> return `.failure(error)` and potentially stash response info inside a custom `Error` (TODO)
///   * `data` is nil but `response` is non-nil ==> force an empty `Data` and return `.success((emptyData, response))`
///   * `error` is non-nil ==> return `.failure(error)`
///   * anything else ==> `preconditionFailure` (see below about notes on `throws`)
///
/// wait… huh? Why do we need this?? Read here:
///   * https://oleb.net/2020/urlsession-publisher/
///   * https://oleb.net/blog/2018/03/making-illegal-states-unrepresentable/
///
/// Re: `throws` … the list above is indeed the intent for how we want to handle the cursed URLSession callback. However, to make this function itself total and make sure all cases are testable, we will instead throw an `NSError` for the “anything else” case, with the understanding that at the call site, in actual use, this function (which is `internal` to this library) will be invoked with `try!`
///
/// phew … hoping to never have to do this again
/// - Parameters:
///   - data: cursed `URLSession` optional `Data`
///   - response: cursed `URLSession` optional `URLResponse`
///   - error: cursed `URLSession` optional `Error`
func process(data: Data?, response: URLResponse?, error: Error?) throws -> Result<(Data, URLResponse), Error> {
    switch (data, response, error) {
    case (.some(let data), .some(let response), .none):
        return .success((data, response))
    case (.none, .some(let response), .none):
        return .success((emptyData, response))
    case (.none, .some(_), .some(let error)):
        // TODO: figure out where to stash the response
        return .failure(error)
    case (.none, .none, .some(let error)):
        return .failure(error)
    default:
        let errorDescription = """
Laters: processing URLSession callback: hit a case which should never happen:
data: \(String(describing: data)), response: \(String(describing: response)), error: \(String(describing: error))
"""
        let internalError = NSError(domain: "com.wayfair.prelude.laters.ErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: errorDescription])
        throw internalError
    }
}
private let emptyData = Data()
extension Laters.DataTask: Later {
    public typealias Output = Result<(Data, URLResponse), Error>

    public func run(_ next: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            let result = try! process(data: data, response: response, error: error)
            next(result)
            return
        }.resume()
    }
}
