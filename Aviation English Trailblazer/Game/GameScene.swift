//
//  GameScene.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 28/10/2021.
//

import Alamofire
import Foundation
import GameplayKit
import SpriteKit

protocol GameSceneDelegate: AnyObject {
    func gameSceneDidEnd(_ gameScene: GameScene)
}

class GameScene: SKScene {
    var plane: Plane!
    var map: SKNode!
    var actions: Path!

    weak var sceneDelegate: GameSceneDelegate?

    private var viewModel: LevelDetailViewModelRepresentable?

    var viewController: GameViewController?

    var stateMachine: GKStateMachine?

    func setViewModel(viewModel: LevelDetailViewModelRepresentable?) {
        self.viewModel = viewModel
    }

    var rasaData: RasaResponse?

    override func didMove(to view: SKView) {
        map = childNode(withName: "Map") as! SKSpriteNode

        actions = Path(airport: map, screenFrame: frame)

        plane = Plane()
        plane.node.position = actions.getSceneCGPoint(spawnPonit: .Terminal)

        addChild(plane.node)

        stateMachine = GameStateMachine(states: [GetSenderIDState(),
                                                 DepartureState(),
                                                 TaxiState(),
                                                 RequestTakeoffState(),
                                                 TakeoffState(),
                                                 RequestLandingState(),
                                                 LandingState(),
                                                 RequestTaxiState(),
                                                 TaxiState2()],
                                        viewController: viewController!)

        stateMachine?.enter(GetSenderIDState.self)
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        stateMachine?.update(deltaTime: currentTime)
    }
}

class GameStateMachine: GKStateMachine {
    let viewController: GameViewController

    init(states: [GKState], viewController: GameViewController) {
        self.viewController = viewController

        super.init(states: states)
    }
}

class GetSenderIDState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter get sender id state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        viewController.scenarioID = String(format: "%04d", (Int(viewController.scenarioID.prefix(4)) ?? 0) + 1) + "00"

        // Rasa get sender id
        var parameters = RasaRequest(message: "getid", sender: viewController.scenarioID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")
                    viewController.senderID = response.value?.text ?? ""
                    viewController.senderIDArr.append(response.value?.text ?? "")

                    // Rasa send empty string to get action
                    parameters = RasaRequest(message: "test", sender: viewController.senderID)

                    AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
                        switch response.result {
                            case .success(let JSON):
                                debugPrint("Response: \(JSON)")

                                if response.value!.action!.contains("departure") {
                                    self.stateMachine?.enter(DepartureState.self)
                                } else {
                                    self.stateMachine?.enter(RequestLandingState.self)
                                }

                            case .failure(let error):
                                debugPrint("Failure: \(error)")
                        }
                    }

                case .failure(let error):
                    debugPrint("Failure: \(error)")
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == DepartureState.self || stateClass == RequestLandingState.self
    }
}

class DepartureState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter departure state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        /// Rasa departure
        let parameters = RasaRequest(message: "departure", sender: viewController.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")

                    viewController.speechLogTextView.addColoredSpeech(speaker: response.value?.callsign ?? "", input: response.value?.text ?? "", color: .yellow)

                    DispatchQueue.global(qos: .userInitiated).async {
                        viewController.synthesisToSpeaker(response.value?.text ?? "")
                    }

                    viewController.atisTextView.update(action: response.value?.action ?? "", runway: response.value?.runway ?? "", degree: response.value?.degree ?? "", knot: response.value?.knot ?? "", information: response.value?.information ?? "")

                case .failure(let error):
                    debugPrint("Failure: \(error)")
            }
        }

        viewController.scene?.plane.node.position = (viewController.scene?.actions.getSceneCGPoint(spawnPonit: .Terminal))!
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TaxiState.self
    }
}

class TaxiState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter taxi state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        // Rasa send empty string to get action
        let parameters = RasaRequest(message: "test", sender: viewController.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")

                    if response.value?.runway == "28 RIGHT" {
                        viewController.scene?.plane.node.run((viewController.scene?.actions.terminalToB1StopBars)!) {
                            stateMachine.enter(RequestTakeoffState.self)
                        }
                    } else if response.value?.runway == "10 LEFT" {
                        viewController.scene?.plane.node.run((viewController.scene?.actions.terminalToB5StopBars)!) {
                            stateMachine.enter(RequestTakeoffState.self)
                        }
                    }

                case .failure(let error):
                    debugPrint("Failure: \(error)")
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == RequestTakeoffState.self
    }
}

class RequestTakeoffState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter request takeoff state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        /// Rasa request takeoff
        let parameters = RasaRequest(message: "ready takeoff", sender: viewController.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")

                    viewController.speechLogTextView.addColoredSpeech(speaker: response.value?.callsign ?? "", input: response.value?.text ?? "", color: .yellow)

                    DispatchQueue.global(qos: .userInitiated).async {
                        viewController.synthesisToSpeaker(response.value?.text ?? "")
                    }

                    viewController.scene?.rasaData = response.value

                case .failure(let error):
                    debugPrint("Failure: \(error)")
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TakeoffState.self
    }
}

class TakeoffState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter takeoff state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        if viewController.scene?.rasaData?.runway == "28 RIGHT" {
            viewController.scene?.plane.node.run((viewController.scene?.actions.takeoff28R)!) {
                viewController.planeQtyLabel.finished += 1
                stateMachine.enter(GetSenderIDState.self)
            }

        } else if viewController.scene?.rasaData?.runway == "10 LEFT" {
            viewController.scene?.plane.node.run((viewController.scene?.actions.takeoff10L)!) {
                viewController.planeQtyLabel.finished += 1
                stateMachine.enter(GetSenderIDState.self)
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == GetSenderIDState.self
    }
}

class RequestLandingState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter request landing state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        /// Rasa departure
        let parameters = RasaRequest(message: "landing", sender: viewController.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")

                    viewController.speechLogTextView.addColoredSpeech(speaker: response.value?.callsign ?? "", input: response.value?.text ?? "", color: .yellow)

                    DispatchQueue.global(qos: .userInitiated).async {
                        viewController.synthesisToSpeaker(response.value?.text ?? "")
                    }

                    viewController.atisTextView.update(action: response.value?.action ?? "", runway: response.value?.runway ?? "", degree: response.value?.degree ?? "", knot: response.value?.knot ?? "", information: response.value?.information ?? "")

                    viewController.scene?.rasaData = response.value

                case .failure(let error):
                    debugPrint("Failure: \(error)")
            }
        }

        viewController.scene?.plane.node.position = (viewController.scene?.actions.getSceneCGPoint(spawnPonit: .Arrival28R))!
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == LandingState.self
    }
}

class LandingState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter landing state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        viewController.scene?.plane.node.run((viewController.scene?.actions.landing28RExitB3)!) {
            stateMachine.enter(RequestTaxiState.self)
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == RequestTaxiState.self
    }
}

class RequestTaxiState: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter request taxi state")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        /// Rasa sends "Exit right on Bravo 3"
        var parameters = RasaRequest(message: "\(viewController.scene?.rasaData?.callsign ?? "") exit right on Bravo 3", sender: viewController.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")

//                    viewController.speechLogTextView.addColoredSpeech(speaker: response.value?.callsign ?? "", input: response.value?.text ?? "", color: .yellow)
//
//                    DispatchQueue.global(qos: .userInitiated).async {
//                        viewController.synthesisToSpeaker(response.value?.text ?? "")
//                    }

                    /// Rasa request taxi
                    parameters = RasaRequest(message: "ready taxi", sender: viewController.senderID)

                    AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
                        switch response.result {
                            case .success(let JSON):
                                debugPrint("Response: \(JSON)")

                                viewController.speechLogTextView.addColoredSpeech(speaker: response.value?.callsign ?? "", input: response.value?.text ?? "", color: .yellow)

                                DispatchQueue.global(qos: .userInitiated).async {
                                    viewController.synthesisToSpeaker(response.value?.text ?? "")
                                }

                            case .failure(let error):
                                debugPrint("Failure: \(error)")
                        }
                    }

                case .failure(let error):
                    debugPrint("Failure: \(error)")
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TaxiState2.self
    }
}

class TaxiState2: GKState {
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        debugPrint("Enter taxi state 2")

        guard let stateMachine = stateMachine as? GameStateMachine else {
            return
        }

        let viewController = stateMachine.viewController

        viewController.scene?.plane.node.run((viewController.scene?.actions.b3ToTerminal)!) {
            viewController.planeQtyLabel.finished += 1
            stateMachine.enter(GetSenderIDState.self)
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == GetSenderIDState.self
    }
}
