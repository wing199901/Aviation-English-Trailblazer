//
//  MenuScene.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 28/10/2021.
//

import GameplayKit
import SpriteKit

class MenuScene: SKScene {
    // private var btnEnter: SKSpriteNode?

    override func didMove(to view: SKView) {
        // self.btnEnter = self.childNode(withName: "//BtnEnter") as? SKSpriteNode
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touched = atPoint(touch.location(in: self))
            guard let name = touched.name else {
                return
            }
            switch name {
            case "BtnEnter":
                if let scene = SKScene(fileNamed: "LevelScene") {
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFit

                    let reveal = SKTransition.doorsOpenVertical(withDuration: 0.5)

                    // Present the scene
                    view?.presentScene(scene, transition: reveal)
                }
            default:
                break
            }
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
