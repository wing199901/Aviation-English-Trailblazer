//
//  SpriteType.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 1/11/2021.
//

extension CGFloat {
    func degreesToRadians() -> CGFloat {
        self * CGFloat.pi / 180
    }
}

import SpriteKit

enum SpriteType: String {
    case player = "plane"
    case npc = "npc plane"
}

extension SpriteType {
    var node: SKSpriteNode {
        SKSpriteNode(imageNamed: rawValue)
    }

    var zPosition: CGFloat {
        switch self {
        case .player, .npc:
            return 2
        }
    }

    var zRotation: CGFloat {
        switch self {
        case .player, .npc:
            return CGFloat(80).degreesToRadians()
        }
    }

    var size: CGSize {
        switch self {
        case .player, .npc:
            return CGSize(width: 60, height: 75.9)
        }
    }

    var anchorPoint: CGPoint {
        switch self {
        case .player, .npc:
            return CGPoint(x: 0.5, y: 0.55)
        }
    }

//    func position(frame: CGRect) -> CGPoint {
//        switch self {
//        case .plane, .npc:
//            return CGPoint(x: frame.width/2, y: frame.height/2)
//        }
//    }
}
