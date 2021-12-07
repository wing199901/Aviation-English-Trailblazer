//
//  Sprites.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 1/11/2021.
//

import SpriteKit

enum Sprites {
    static func sprite(type: SpriteType) -> SKSpriteNode {
        let sprite = type.node

        sprite.size = type.size
        //sprite.position = type.position(frame: frame)
        sprite.zPosition = type.zPosition
        sprite.zRotation = type.zRotation
        sprite.name = type.rawValue

        return sprite
    }
}
