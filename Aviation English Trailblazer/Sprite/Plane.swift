//
//  Plane.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 1/11/2021.
//

import SpriteKit

struct Plane {
    // MARK: - Properties

    let node: SKSpriteNode

    let label: SKLabelNode

    // MARK: - Initialization

    init(type: SpriteType) {
        self.node = SpriteFactory.sprite(type: type)
        self.label = SKLabelNode(text: "")
    }

    // MARK: - Functions

    /// Shows the call sign under the plane
    func addCallSign(_ text: String) {
        label.text = text
        label.fontColor = .yellow
        label.fontName = "MyriadPro-SemiBold"
        label.fontSize = 18

        label.position = CGPoint(x: -35, y: 0)
        label.zRotation = CGFloat(280).degreesToRadians()
        label.zPosition = 100

        node.addChild(label)
    }

    /// Update call sign text
    func updateCallSignText(_ text: String) {
        label.text = text
    }

    /// Update the call sign's position and rotation.
    func update() {
        let piOver2 = CGFloat.pi / 2
        let deltaX: CGFloat = 35 * cos(-node.zRotation - piOver2)
        let deltaY: CGFloat = 35 * sin(-node.zRotation - piOver2)

        label.position = CGPoint(x: deltaX, y: deltaY)
        label.zRotation = -node.zRotation
    }
}
