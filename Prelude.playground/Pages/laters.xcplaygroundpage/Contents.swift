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

//
// Laters
//

let x = Laters.After(deadline: .now() + 1, queue: .main, value: 1)
    .tap { print("first step: \($0) \(Date())") }
    .flatMap { Laters.After(deadline: .now() + $0, queue: .main, value: "hello") }
    .tryMap { "\($0) world" }
    .eraseToAnyLater()

DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
    print("starting \(Date())")
    x
        .run { print("---> \($0) \(Date())") }
})

print(Date())

import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

let myURL = URL(string: "https://httpbin.org/get")!

let t = AnyLater<Result<(Data, URLResponse), Error>> { callback in
    URLSession.shared.dataTask(with: myURL) { data, response, error in
        guard let data = data, let response = response else {
            if let error = error {
                callback(.failure(error))
                return
            } else {
                fatalError("todo")
            }
        }
        callback(.success((data, response)))
        return
    }.resume()
}

t.run { result in
    switch result {
    case .success(let tuple):
        let (data, response) = tuple
        print("response: \(response), data: \(data)")
    case .failure(let error):
        print(error)
    }
}

let t2 = Laters.DataTask(request: .init(url: myURL), session: .shared)
    .map { result -> Result<Int, Error> in
        switch result {
        case .success(let tuple):
            let (_, response) = tuple
            return .success((response as! HTTPURLResponse).statusCode)
        case .failure(let error):
            return .failure(error)
        }
}.eraseToAnyLater()

let t3 = Laters.DataTask(request: .init(url: myURL), session: .shared)
    .mapSuccess { tuple in
        (tuple.1 as! HTTPURLResponse).statusCode
}.eraseToAnyLater()

extension String: Error { }

let y = Laters.After(deadline: .now() + 1, queue: .main, value: Result<Int, String>.failure("foobar"))
    .mapSuccess { _ in fatalError("should not be called") }

y.run { value in print(value) }

let t4 = t3.tryMapSuccess { int throws -> Void in
    guard int == 200 else { throw "status code error: \(int)" }
    return ()
}.eraseToAnyLater()

type(of: t4)

let t5 = Laters.DataTask(
    request: .init(url: myURL),
    session: .shared
).tryMapSuccess { tuple throws -> (Data, HTTPURLResponse) in
    guard let response = tuple.1 as? HTTPURLResponse else {
        throw "not a response, this should never happen"
    }
    return (tuple.0, response)
}.tryMapSuccess { tuple throws -> Data in
    let (data, response) = tuple
    guard response.statusCode == 200 else {
        throw "bad status code: \(response.statusCode)"
    }
    return data
}.replaceError(Data.init()).eraseToAnyLater()

t5.run { print("t5: \($0)") }

Laters.After(deadline: .now() + 1, queue: .main, value: "x")
    .dispatchAsync(on: .global(qos: .default))
    .dispatchAsync(on: .main)

func myAsyncFunc(completion: @escaping (Void) -> Void) {
    print("doin’ thangs")
    DispatchQueue.main.async {
        completion(())
    }
}

let a = AnyLater(myAsyncFunc).run {
    print("ok")
}

func myAsyncFunc0(completion: @escaping () -> Void) {
    print("doin’ thangs")
    DispatchQueue.main.async {
        completion()
    }
}

let a0 = AnyLater(myAsyncFunc0)

func myAsyncFunc1(completion: @escaping (Bool) -> Void) {
    print("doin’ thangs")
    DispatchQueue.main.async {
        completion(true)
    }
}

let b = AnyLater(myAsyncFunc1)

func myAsyncFunc2(completion: @escaping (Bool, String) -> Void) {
    print("doin’ thangs")
    DispatchQueue.main.async {
        completion(true, "ok")
    }
}

let c = AnyLater(myAsyncFunc2) // => AnyLater<(Bool, String)>
