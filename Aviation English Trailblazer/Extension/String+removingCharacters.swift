//
//  String+removingCharacters.swift
//  ATC
//
//  Created by Steven Siu  on 3/11/2020.
//  Copyright © 2020 Steven Siu . All rights reserved.
//

import Foundation

extension String {
    /// This function retunres a string that removed character set
    /// - Parameter forbiddenCharacters: The charactor set to br removed
    /// - Returns: A string that removed character set
    func removingCharacters(inCharacterSet forbiddenCharacters: CharacterSet) -> String {
        var filteredString = self
        while true {
            if let forbiddenCharRange = filteredString.rangeOfCharacter(from: forbiddenCharacters) {
                filteredString.removeSubrange(forbiddenCharRange)
            } else {
                break
            }
        }
        return filteredString
    }
}
