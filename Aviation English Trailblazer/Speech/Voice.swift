//
//  Voice.swift
//  ATC
//
//  Created by Steven Siu  on 28/4/2021.
//  Copyright © 2021 Steven Siu . All rights reserved.
//

enum Voice: String, CaseIterable {
//    case Natasha = "en-AU-NatashaNeural"
//    case William = "en-AU-WilliamNeural"
//    case Clara = "en-CA-ClaraNeural"
//    case Liam = "en-CA-LiamNeural"
//    case Emily = "en-IE-EmilyNeural"
//    case Connor = "en-IE-ConnorNeural"
//    case Libby = "en-GB-LibbyNeural"
//    case Mia = "en-GB-MiaNeural"
//    case Ryan = "en-GB-RyanNeural"
    case Aria = "en-US-AriaNeural"
    case Jenny = "en-US-JennyNeural"
    case Guy = "en-US-GuyNeural"
//    case Sam = "en-HK-SamNeural"
//    case Yan = "en-HK-YanNeural"
//    case Molly = "en-NZ-MollyNeural"
//    case Mitchell = "en-NZ-MitchellNeural"

    static func random<G: RandomNumberGenerator>(using generator: inout G) -> Voice {
        Voice.allCases.randomElement(using: &generator)!
    }

    static func random() -> Voice {
        var g = SystemRandomNumberGenerator()
        return Voice.random(using: &g)
    }
}
