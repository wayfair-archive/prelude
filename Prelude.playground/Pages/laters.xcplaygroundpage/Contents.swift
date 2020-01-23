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

let t2 = Laters.DataTask(request: .init(url: myURL))
    .map { result -> Result<Int, Error> in
        switch result {
        case .success(let tuple):
            let (data, response) = tuple
            return .success((response as! HTTPURLResponse).statusCode)
        case .failure(let error):
            return .failure(error)
        }
}
    .eraseToAnyLater()

t2.run { result in
    print(result)
}
