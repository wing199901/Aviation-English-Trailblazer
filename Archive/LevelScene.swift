//
//  LevelScene.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 28/10/2021.
//

import GameplayKit
import iCarousel
import SpriteKit

class LevelScene: SKScene, iCarouselDataSource, iCarouselDelegate {
    private var carousel: iCarousel?

    override func didMove(to view: SKView) {
        carousel = iCarousel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        carousel?.delegate = self
        carousel?.dataSource = self
        carousel?.type = .rotary

        view.addSubview(carousel!)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touched = atPoint(touch.location(in: self))
            guard let name = touched.name else {
                return
            }
            switch name {
            case "BtnBack":
                if view != nil {
                    for view in view!.subviews {
                        view.removeFromSuperview()
                    }
                }

                if let scene = SKScene(fileNamed: "MenuScene") {
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

    func numberOfItems(in carousel: iCarousel) -> Int {
        5
    }

    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: size.width * 0.4, height: size.height * 0.8))

        let width = view.frame.width
        let height = view.frame.height

        let viewBorder = UIImageView(image: UIImage(named: "Level Border"))
        viewBorder.frame = view.bounds

        let title = UIImageView(image: UIImage().addTextToImage(image: UIImage(named: "Level Title")!, text: "Level \(index + 1)"))
        title.frame = CGRect(x: 0, y: 0, width: width * 0.8, height: height * 0.1)
        title.center = CGPoint(x: width * 0.5, y: height * 0.1)
        title.contentMode = .scaleAspectFit

        let description = UITextView(frame: CGRect(x: 0, y: 0, width: width * 0.8, height: height * 0.4))
        description.center = CGPoint(x: width * 0.5, y: height * 0.35)
        // description.text = descriptionModel[index]
        description.textColor = .white
        description.textAlignment = .left
        description.font = UIFont(name: "MyriadPro-Regular", size: 20)
        description.backgroundColor = .clear
        description.isEditable = false
        description.isSelectable = false
        description.showsHorizontalScrollIndicator = false

        let descriptionImage = UIImageView(image: UIImage(named: "Description Border"))
        descriptionImage.frame = description.frame
        descriptionImage.center = description.center

        let lblPlaneNum = UILabel(frame: CGRect(x: 0, y: 0, width: width * 0.8, height: height * 0.1))
        lblPlaneNum.center = CGPoint(x: width * 0.5, y: height * 0.6)
        lblPlaneNum.text = "Number of planes: "
        lblPlaneNum.textColor = .white
        lblPlaneNum.font = UIFont(name: "MyriadPro-Regular", size: 20)

        let planeNum = UILabel(frame: CGRect(x: 0, y: 0, width: width * 0.1, height: height * 0.1))
        planeNum.center = CGPoint(x: width * 0.85, y: height * 0.6)
        planeNum.textColor = .red
        planeNum.font = UIFont(name: "MyriadPro-Regular", size: 20)

        switch index + 1 {
        case 1:
            planeNum.text = "4"
        case 2:
            planeNum.text = "7"
        case 3:
            planeNum.text = "7"
        case 4:
            planeNum.text = "1"
        default:
            planeNum.text = "N/A"
        }

        let lblDifficulty = UILabel(frame: CGRect(x: 0, y: 0, width: width * 0.8, height: height * 0.1))
        lblDifficulty.center = CGPoint(x: width * 0.5, y: height * 0.7)
        lblDifficulty.text = "Difficulty: "
        lblDifficulty.textColor = .white
        lblDifficulty.font = UIFont(name: "MyriadPro-Regular", size: 20)

        let switchDiff = UISegmentedControl(items: ["Easy", "Hard"])
        switchDiff.center = CGPoint(x: width * 0.75, y: height * 0.7)
        switchDiff.selectedSegmentIndex = 0
        switchDiff.apportionsSegmentWidthsByContent = true
        switchDiff.selectedSegmentTintColor = UIColor(named: "UIGary")
        // Segmented Control Text Color
        switchDiff.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
        switchDiff.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        switchDiff.tag = index + 100 // Index start from 0.

        let btnStart = UIButton(frame: CGRect(x: 0, y: 0, width: width * 0.45, height: height * 0.2))
        btnStart.center = CGPoint(x: width * 0.5, y: height * 0.9)
        btnStart.setImage(UIImage(named: "Start Button"), for: .normal)
        btnStart.imageView?.contentMode = .scaleAspectFit
        btnStart.tag = index + 1
        btnStart.addTarget(self, action: #selector(enterLevel(_:)), for: .touchUpInside)

        view.addSubview(viewBorder)
        view.addSubview(title)
        view.addSubview(descriptionImage)
        view.addSubview(description)
        view.addSubview(lblPlaneNum)
        view.addSubview(planeNum)
        view.addSubview(lblDifficulty)
        view.addSubview(switchDiff)
        view.addSubview(btnStart)

        return view
    }

    @objc func enterLevel(_ sender: UIButton) {
        if view != nil {
            for view in view!.subviews {
                view.removeFromSuperview()
            }
        }

        print("Selected Level \(sender.tag)")

//        let diff = getDiff(sender: carousel.viewWithTag(sender.tag + 99) as! UISegmentedControl)
//
//        switch sender.tag {
//        case 1:
//            mainScene = Level1Scene(size: size, difficulty: diff)
//        case 2:
//            mainScene = Level2Scene(size: size, difficulty: diff)
//        case 3:
//            mainScene = Level3Scene(size: size, difficulty: diff)
//        case 4:
//            mainScene = Level9Scene(size: size, difficulty: diff)
//        default:
//            mainScene = Level1Scene(size: size, difficulty: diff)
//        }

        if let scene = SKScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFit

            let reveal = SKTransition.doorsOpenVertical(withDuration: 0.5)

            // Present the scene
            view?.presentScene(scene, transition: reveal)
        }
    }
}
