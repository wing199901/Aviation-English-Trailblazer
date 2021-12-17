//
//  NPC.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 14/12/2021.
//

import SpriteKit

struct NPC {
    // MARK: - Properties
    
    let node: SKSpriteNode
    
    // MARK: - Initialization
    
    init(frame: CGRect) {
        self.node = SpriteFactory.sprite(type: .npc)
    }
    
    // MARK: - Functions
}
