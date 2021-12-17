//
//  SpriteFactory.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 14/12/2021.
//

import SpriteKit

enum SpriteFactory {
    // MARK: - Functions
    static func sprite(type: SpriteType) -> SKSpriteNode {
        let sprite = type.node

        sprite.anchorPoint = type.anchorPoint
        sprite.size = type.size
        sprite.zPosition = type.zPosition
        sprite.zRotation = type.zRotation
        sprite.name = type.rawValue

        return sprite
    }
}
