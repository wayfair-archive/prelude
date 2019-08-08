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
// Functions
//

func countCharacters(_ stringValue: String) -> Int {
    return stringValue.count
}

func addingQuestionMark(_ stringValue: String) -> String {
    return stringValue + "?"
}

let countQuestionCharacters = addingQuestionMark >>> countCharacters
countQuestionCharacters <| "hello"

"world" |> addingQuestionMark >>> countCharacters

countCharacters
    <<< addingQuestionMark
    <<< addingQuestionMark
    <| "1234"
