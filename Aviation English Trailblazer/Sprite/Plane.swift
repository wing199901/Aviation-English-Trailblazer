//
//  Plane.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 1/11/2021.
//

import SpriteKit

struct Plane {
    let node: SKSpriteNode

    init() {
        self.node = Sprites.sprite(type: .plane)
    }
}
