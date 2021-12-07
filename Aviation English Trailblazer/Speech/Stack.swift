//
//  Stack.swift
//  helloworld
//
//  Created by Steven Siu  on 29/10/2020.
//  Copyright © 2020 Microsoft. All rights reserved.
//

struct Stack {
    private var items: [String] = []

    mutating func push(_ element: String) {
        let noPunctuation = element.components(separatedBy: .punctuationCharacters).joined(separator: "")
        /// Replace niner to 9
//            .replacingOccurrences(of: " NINER", with: "9")
//            .replacingOccurrences(of: " niner", with: "9")
//            .replacingOccurrences(of: " Niner", with: "9")
//            .replacingOccurrences(of: "one 0", with: "10")
//            .replacingOccurrences(of: "Juliet", with: "Juliett")
        /// Replace short form call sign to full form
//            .replacingTaxiway()
        /// Replace short form holding point to full form
//            .replacingOccurrences(matchingPattern: "\\b([A-Z,a-z]{1})\\s?([0-9]{1})\\b")

        items.append(noPunctuation)
    }

    mutating func pop() -> String? {
        items.popLast()
    }

    func peek() -> String? {
        items.last
    }

    mutating func popAll() {
        items.removeAll()
    }

    mutating func printAll() -> String? {
        items.joined(separator: " ")
            .replacingOccurrences(of: "expecct", with: "expect")
            .replacingOccurrences(of: "expected", with: "expect")
            .replacingOccurrences(of: "expecte", with: "expect")
            .replacingOccurrences(of: "Expecct", with: "expect")
            .replacingOccurrences(of: "Expected", with: "expect")
            .replacingOccurrences(of: "Expecte", with: "expect")
            .replacingOccurrences(of: "X packed", with: "expect")
        /// Replace short form call sign to full form
//            .replacingCallSign()
//            .replacingTaxiway()
        /// Replace short form holding point to full form
//            .replacingOccurrences(matchingPattern: "\\b([A-Z,a-z]{1})\\s?([0-9]{1})\\b")
    }
}
