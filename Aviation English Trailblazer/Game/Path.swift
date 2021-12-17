//
//  Path.swift
//  ATC
//
//  Created by Steven Siu  on 7/8/2020.
//  Copyright © 2020 Steven Siu . All rights reserved.
//

/*
 Path is used to store all plane's movement
 */

import SpriteKit

/// X, Y from Adobe AI
enum SpawnPoint: CGPoint {
    case Terminal = "{1699.1188,1134.7714}"
    case Arrival28R = "{2406.9269,1565.2614}"
    case Arrival10L = "{-351.7793,661.4227}"
    case Eastern = "{1814.6407,884.9837}"
}

/// Make enum can return CGPoint
extension CGPoint: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self = NSCoder.cgPoint(for: value)
    }

    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self = NSCoder.cgPoint(for: value)
    }

    public init(unicodeScalarLiteral value: StringLiteralType) {
        self = NSCoder.cgPoint(for: value)
    }
}

struct Path {
    // MARK: - Properties

    var airport: SKNode
    var screenFrame: CGRect

    let path = UIBezierPath()

    // MARK: - Initialization

    init(airport: SKNode, screenFrame: CGRect) {
        self.airport = airport
        self.screenFrame = screenFrame
    }

    // MARK: - Method

    /// Convert the X from Adobe AI to Scene X
    func convertMapXToSceneX(map_ai_X: CGFloat) -> CGFloat {
        let x: CGFloat = map_ai_X * airport.xScale - (airport.frame.size.width / 2)

        return x
    }

    /// Convert the Y from Adobe AI to Scene Y
    func convertMapYToSceneY(map_ai_Y: CGFloat) -> CGFloat {
        let y: CGFloat = (airport.frame.size.height / 2) - map_ai_Y * airport.yScale

        return y
    }

    func getSceneCGPoint(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: convertMapXToSceneX(map_ai_X: x), y: convertMapYToSceneY(map_ai_Y: y))
    }

    func getSceneCGPoint(spawnPonit: SpawnPoint) -> CGPoint {
        CGPoint(x: convertMapXToSceneX(map_ai_X: spawnPonit.rawValue.x), y: convertMapYToSceneY(map_ai_Y: spawnPonit.rawValue.y))
    }

    /// UIBezierPath to SkAction with speed, timing mode.
    func pathToSKAction(path: CGPath, speed: CGFloat, timingMode: SKActionTimingMode) -> SKAction {
        let action = SKAction.follow(path, asOffset: false, orientToPath: true, speed: speed)
        action.timingMode = timingMode

        return action
    }

    // MARK: - Path

    var terminalToB1StopBars: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 1699.1188, y: 1134.7714))

        path.addLine(to: getSceneCGPoint(x: 1645.9936, y: 1125.0078))

        path.addCurve(to: getSceneCGPoint(x: 1619.5586, y: 1143.5666), controlPoint1: getSceneCGPoint(x: 1634.4709, y: 1122.89), controlPoint2: getSceneCGPoint(x: 1620.9808, y: 1132.066))

        path.addLine(to: getSceneCGPoint(x: 1617.2003, y: 1162.6374))

        path.addLine(to: getSceneCGPoint(x: 1615.0285, y: 1169.8382))

        path.addLine(to: getSceneCGPoint(x: 1596.9126, y: 1229.9068))

        return pathToSKAction(path: path.cgPath, speed: 20, timingMode: .linear)
    }

    var takeoff28R: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 1596.9126, y: 1229.9068))

        path.addLine(to: getSceneCGPoint(x: 1590.0664, y: 1252.6069))

        path.addCurve(to: getSceneCGPoint(x: 1555.1401, y: 1270.9901), controlPoint1: getSceneCGPoint(x: 1585.6011, y: 1267.4131), controlPoint2: getSceneCGPoint(x: 1569.8731, y: 1275.6914))

        path.addLine(to: getSceneCGPoint(x: 197.6596, y: 837.8182))

        path.addLine(to: getSceneCGPoint(x: -395.4591, y: 649.7441))

        return pathToSKAction(path: path.cgPath, speed: 100, timingMode: .easeIn)
    }

    var terminalToB5StopBars: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 1699.1188, y: 1134.7714))

        path.addLine(to: getSceneCGPoint(x: 1645.9936, y: 1125.0078))

        path.addCurve(to: getSceneCGPoint(x: 1619.5586, y: 1143.5666), controlPoint1: getSceneCGPoint(x: 1634.4709, y: 1122.89), controlPoint2: getSceneCGPoint(x: 1620.9808, y: 1132.066))

        path.addLine(to: getSceneCGPoint(x: 1617.2003, y: 1162.6374))

        path.addLine(to: getSceneCGPoint(x: 1615.0285, y: 1169.8382))

        // turn Bravo

        path.addCurve(to: getSceneCGPoint(x: 1593.9199, y: 1183.7382), controlPoint1: getSceneCGPoint(x: 1610.5852, y: 1184.5715), controlPoint2: getSceneCGPoint(x: 1601.6501, y: 1185.8863))

        // 04R StopBars

        path.addLine(to: getSceneCGPoint(x: 951.735, y: 977.2683))

        // to B5 StopBars

        path.addLine(to: getSceneCGPoint(x: 168.4891, y: 725.0474))

        path.addCurve(to: getSceneCGPoint(x: 157.4444, y: 732.3043), controlPoint1: getSceneCGPoint(x: 163.4, y: 723.2786), controlPoint2: getSceneCGPoint(x: 157.4444, y: 732.3043))

        path.addLine(to: getSceneCGPoint(x: 149.775, y: 756.364))

        return pathToSKAction(path: path.cgPath, speed: 50, timingMode: .linear)
    }

    var j1To04RStopBars: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 1814.6407, y: 884.9837))

        path.addLine(to: getSceneCGPoint(x: 1679.6407, y: 866.0105))

        // turn Hotel

        path.addCurve(to: getSceneCGPoint(x: 1650.4524, y: 893.7435), controlPoint1: getSceneCGPoint(x: 1659.0857, y: 863.2286), controlPoint2: getSceneCGPoint(x: 1652.4569, y: 877.5338))

        path.addLine(to: getSceneCGPoint(x: 1641.9252, y: 962.6983))

        // turn Echo

        path.addCurve(to: getSceneCGPoint(x: 1614.9439, y: 985.1715), controlPoint1: getSceneCGPoint(x: 1640.463, y: 975.3564), controlPoint2: getSceneCGPoint(x: 1631.4246, y: 981.4286))

        path.addLine(to: getSceneCGPoint(x: 1286.4019, y: 1060.1142))

        // turn Bravo

        path.addCurve(to: getSceneCGPoint(x: 1225.7005, y: 1065.3001), controlPoint1: getSceneCGPoint(x: 1272, y: 1063.4419), controlPoint2: getSceneCGPoint(x: 1240.7209, y: 1070.1315))

        // 04R StopBars

        path.addLine(to: getSceneCGPoint(x: 951.735, y: 977.2683))

        return pathToSKAction(path: path.cgPath, speed: 50, timingMode: .linear)
    }

    var taxiway04RStopBarsToB5StopBars: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 951.735, y: 977.2683))

        path.addLine(to: getSceneCGPoint(x: 168.4891, y: 725.0474))

        path.addCurve(to: getSceneCGPoint(x: 157.4444, y: 732.3043), controlPoint1: getSceneCGPoint(x: 163.4, y: 723.2786), controlPoint2: getSceneCGPoint(x: 157.4444, y: 732.3043))

        path.addLine(to: getSceneCGPoint(x: 149.775, y: 756.364))

        return pathToSKAction(path: path.cgPath, speed: 50, timingMode: .linear)
    }

    var takeoff10L: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 149.775, y: 756.364))

        path.addLine(to: getSceneCGPoint(x: 134.468, y: 804.3836))

        path.addCurve(to: getSceneCGPoint(x: 142.6723, y: 820.2717), controlPoint1: getSceneCGPoint(x: 132.3474, y: 811.0365), controlPoint2: getSceneCGPoint(x: 136.0201, y: 818.149))

        path.addLine(to: getSceneCGPoint(x: 1510.8806, y: 1256.8669))

        path.addLine(to: getSceneCGPoint(x: 2406.9269, y: 1565.2614))

        return pathToSKAction(path: path.cgPath, speed: 100, timingMode: .easeIn)
    }

    var landing28RExitB3: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 2326.3877, y: 1534.7138))

        path.addLine(to: getSceneCGPoint(x: 1555.1401, y: 1270.9901))

        path.addLine(to: getSceneCGPoint(x: 910.2824, y: 1065.216))

        path.addCurve(to: getSceneCGPoint(x: 898.8687, y: 1037.3463), controlPoint1: getSceneCGPoint(x: 901.1994, y: 1062.3177), controlPoint2: getSceneCGPoint(x: 895.3404, y: 1046.9183))

        path.addLine(to: getSceneCGPoint(x: 902.4403, y: 1026.1366))

        return pathToSKAction(path: path.cgPath, speed: 30, timingMode: .easeInEaseOut)
    }

    var landing10LExitB3: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: -351.7793, y: 661.4227))

        path.addLine(to: getSceneCGPoint(x: 179.6512, y: 832.0716))

        path.addLine(to: getSceneCGPoint(x: 869.8836, y: 1052.3248))

        path.addCurve(to: getSceneCGPoint(x: 898.8687, y: 1037.3463), controlPoint1: getSceneCGPoint(x: 880.9987, y: 1055.8716), controlPoint2: getSceneCGPoint(x: 896.7812, y: 1044.0324))

        path.addLine(to: getSceneCGPoint(x: 902.4403, y: 1026.1366))

        return pathToSKAction(path: path.cgPath, speed: 20, timingMode: .easeInEaseOut)
    }

    var b3ToTerminal: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 902.4403, y: 1026.1366))

        path.addLine(to: getSceneCGPoint(x: 916.9667, y: 980.2113))

        path.addCurve(to: getSceneCGPoint(x: 933.8221, y: 971.5), controlPoint1: getSceneCGPoint(x: 917.9866, y: 978.007), controlPoint2: getSceneCGPoint(x: 925.9171, y: 968.9544))

        path.addLine(to: getSceneCGPoint(x: 1593.9199, y: 1183.7382))

        path.addCurve(to: getSceneCGPoint(x: 1615.0285, y: 1169.8382), controlPoint1: getSceneCGPoint(x: 1601.6501, y: 1185.8863), controlPoint2: getSceneCGPoint(x: 1610.5852, y: 1184.5715))

        path.addLine(to: getSceneCGPoint(x: 1619.5586, y: 1143.5666))

        path.addCurve(to: getSceneCGPoint(x: 1649.6427, y: 1125.6784), controlPoint1: getSceneCGPoint(x: 1620.9808, y: 1132.066), controlPoint2: getSceneCGPoint(x: 1634.4709, y: 1122.89))

        path.addLine(to: getSceneCGPoint(x: 1699.1188, y: 1134.7714))

        return pathToSKAction(path: path.cgPath, speed: 50, timingMode: .linear)
    }

    var b3ToJ1: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 902.4403, y: 1026.1366))

        path.addLine(to: getSceneCGPoint(x: 916.9667, y: 980.2113))

        path.addCurve(to: getSceneCGPoint(x: 933.8221, y: 971.5), controlPoint1: getSceneCGPoint(x: 917.9866, y: 978.007), controlPoint2: getSceneCGPoint(x: 925.9171, y: 968.9544))

        // turn Delta

        path.addCurve(to: getSceneCGPoint(x: 1044.2572, y: 973.8), controlPoint1: getSceneCGPoint(x: 1018.0766, y: 998.5138), controlPoint2: getSceneCGPoint(x: 1022.5507, y: 992.4826))

        path.addLine(to: getSceneCGPoint(x: 1225.9285, y: 829.3982))

        // turn Foxtrot

        path.addCurve(to: getSceneCGPoint(x: 1262.0932, y: 823.7392), controlPoint1: getSceneCGPoint(x: 1235.7, y: 821.8799), controlPoint2: getSceneCGPoint(x: 1239.1715, y: 820.1572))

        path.addLine(to: getSceneCGPoint(x: 1635.2279, y: 874.0022))

        // cross to J1

        path.addLine(to: getSceneCGPoint(x: 1679.6407, y: 866.0105))

        // J1

        path.addLine(to: getSceneCGPoint(x: 1814.6407, y: 884.9837))

        return pathToSKAction(path: path.cgPath, speed: 50, timingMode: .linear)
    }

    var j1To22LStopBars: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 1814.6407, y: 884.9837))

        path.addLine(to: getSceneCGPoint(x: 1679.6407, y: 866.0105))

        // turn Hotel1

        path.addCurve(to: getSceneCGPoint(x: 1658.4925, y: 843.4693), controlPoint1: getSceneCGPoint(x: 1665.6492, y: 864.2635), controlPoint2: getSceneCGPoint(x: 1657.1281, y: 854.3269))

        path.addLine(to: getSceneCGPoint(x: 1723.1737, y: 444.1306))

        // turn Delta

        path.addCurve(to: getSceneCGPoint(x: 1732.2309, y: 423.0794), controlPoint1: getSceneCGPoint(x: 1724.0966, y: 437.6485), controlPoint2: getSceneCGPoint(x: 1727.9209, y: 427.7314))

        path.addLine(to: getSceneCGPoint(x: 1829.0334, y: 345.3934))

        // turn Delta1

        path.addCurve(to: getSceneCGPoint(x: 1827.257, y: 321.7715), controlPoint1: getSceneCGPoint(x: 1834.7883, y: 340.7749), controlPoint2: getSceneCGPoint(x: 1832.6982, y: 328.099))

        path.addLine(to: getSceneCGPoint(x: 1794.6582, y: 283.3256))

        return pathToSKAction(path: path.cgPath, speed: 50, timingMode: .linear)
    }

    var takeoff22L: SKAction {
        path.removeAllPoints()

        path.move(to: getSceneCGPoint(x: 1794.6582, y: 283.3256))

        path.addLine(to: getSceneCGPoint(x: 1778.1738, y: 263.8846))

        path.addCurve(to: getSceneCGPoint(x: 1759.1225, y: 262.0246), controlPoint1: getSceneCGPoint(x: 1773.3694, y: 258.2184), controlPoint2: getSceneCGPoint(x: 1764.9322, y: 257.3946))

        path.addLine(to: getSceneCGPoint(x: 904.0556, y: 943.461))

        path.addLine(to: getSceneCGPoint(x: -233.7974, y: 1865.8395))

        return pathToSKAction(path: path.cgPath, speed: 100, timingMode: .easeIn)
    }
}
