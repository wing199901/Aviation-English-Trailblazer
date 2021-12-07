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
    case plane
    case npc
}

extension SpriteType {
    var node: SKSpriteNode {
        SKSpriteNode(imageNamed: rawValue)
    }

    var zPosition: CGFloat {
        switch self {
        case .plane, .npc:
            return 2
        }
    }

    var size: CGSize {
        switch self {
        case .plane, .npc:
            return CGSize(width: 60, height: 75.9)
        }
    }

    var anchorPoint: CGPoint {
        switch self {
        case .plane, .npc:
            return CGPoint(x: 0.5, y: 0.55)
        default:
            return CGPoint(x: 0.5, y: 0.5)
        }
    }

    var zRotation: CGFloat {
        switch self {
        case .plane, .npc:
            return CGFloat(80).degreesToRadians()
        }
    }

//    func position(frame: CGRect) -> CGPoint {
//        switch self {
//        case .plane, .npc:
//            return CGPoint(x: frame.width/2, y: frame.height/2)
//        }
//    }
}
