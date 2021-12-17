//
//  String+replacingOccurrences.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 14/12/2021.
//

import Foundation

let natoAlphabet = ["A": "Alpha", "B": "Bravo", "C": "Charlie", "D": "Delta", "E": "Echo", "F": "Foxtrot", "G": "Golf", "H": "Hotel", "I": "India", "J": "Juliett", "K": "Kilo", "L": "Lima", "M": "Mike", "N": "November", "O": "Oscar", "P": "Papa", "Q": "Quebec", "R": "Romeo", "S": "Sierra", "T": "Tango", "U": "Uniform", "V": "Victor", "W": "Whiskey", "X": "X-ray", "Y": "Yankee", "Z": "Zulu", "0": "0", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "6": "6", "7": "7", "8": "8", "9": "9"]

let numbers = ["0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six", "7": "seven", "8": "eight", "9": "niner"]

extension String {
    func nato(str: String) -> String {
        var newString = ""
        for char in str {
            char == " " || char.isNumber ? newString.append(char) : newString.append(natoAlphabet[String(char).uppercased()]! + " ")
        }
        return newString
    }

    func replacingOccurrences(matchingPattern pattern: String) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = expression.matches(in: self, options: [], range: NSRange(startIndex ..< endIndex, in: self))
        return matches.reversed().reduce(into: self) { current, result in
            let range = Range(result.range, in: current)!
            let token = String(current[range])
            let replacement = nato(str: token)
            current.replaceSubrange(range, with: replacement)
        }
    }

    func replacingOccurrences(matchingPattern pattern: String, replacementProvider: (String) -> String?) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = expression.matches(in: self, options: [], range: NSRange(startIndex ..< endIndex, in: self))
        return matches.reversed().reduce(into: self) { current, result in
            let range = Range(result.range, in: current)!
            let token = String(current[range])
            guard let replacement = replacementProvider(token) else { return }
            current.replaceSubrange(range, with: " " + replacement)
        }
    }
}
