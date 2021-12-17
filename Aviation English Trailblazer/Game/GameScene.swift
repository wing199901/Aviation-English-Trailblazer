//
//  GameScene.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 28/10/2021.
//

import Alamofire
import GameplayKit
import SpriteKit

protocol GameSceneDelegate: AnyObject {
//    func gameSceneDidEnd(_ gameScene: GameScene)
    func addRasaSpeech(speaker: String, _ text: String)
    func atisUpdate(data: RasaResponse)
    func setPlanePosition(spawnPoint: SpawnPoint)
    func finishPlanePlusOne()
    func synthesisToSpeaker(_ text: String)
}

class GameScene: SKScene {
    // MARK: - Sprites
    var plane: Player!
    private var map: SKNode!
    var actions: Path!

    // MARK: - Properties
    weak var sceneDelegate: GameSceneDelegate?

    private var viewModel: LevelDetailViewModelRepresentable?

    var stateMachine: GKStateMachine?

    var rasaData: RasaResponse?

    // Rasa

    var scenarioID: String = "001000"

    var senderID: String = ""

    var senderIDArr = [String]()

    // MARK: - Life cycle
    override func didMove(to view: SKView) {
        /// init scenario ID = 001100
        scenarioID = scenarioID.replacingOccurrences(of: "1", with: String(viewModel!.id))

        setupSprite()

        stateMachine = GKStateMachine(states: [GetSenderIDState(scene: self),
                                               DepartureState(scene: self),
                                               TaxiState(scene: self),
                                               RequestTakeoffState(scene: self),
                                               TakeoffState(scene: self),
                                               RequestLandingState(scene: self),
                                               LandingState(scene: self),
                                               RequestTaxiState(scene: self),
                                               TaxiState2(scene: self)]
        )

        stateMachine?.enter(GetSenderIDState.self)
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered

        /// Update plane position and rotation
        plane.update()
    }

    // MARK: - Functions
    func setViewModel(viewModel: LevelDetailViewModelRepresentable?) {
        self.viewModel = viewModel
    }

    func setupSprite() {
        map = childNode(withName: "Map") as! SKSpriteNode

        actions = Path(airport: map, screenFrame: frame)

        plane = Player()
        plane.node.position = actions.getSceneCGPoint(spawnPonit: .Terminal)
        plane.addCallSign("")

        addChild(plane.node)
    }
}

class GetSenderIDState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter get sender id state")
        #endif

        /// Even plane equal a scenrio id
        scene.scenarioID = String(format: "%04d", (Int(scene.scenarioID.prefix(4)) ?? 0) + 1) + "00"

        /// Rasa get sender id
        var parameters = RasaRequest(message: "getid", sender: scene.scenarioID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                    debugPrint("Response: \(JSON)")
                    #endif

                    scene.senderID = response.value?.text ?? ""
                    scene.senderIDArr.append(response.value?.text ?? "")

                    // Rasa send empty string to get json with details
                    parameters = RasaRequest(message: "test", sender: scene.senderID)

                    AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
                        switch response.result {
                            case .success(let JSON):
                                #if DEBUG
                                debugPrint("Response: \(JSON)")
                                #endif

                                /// Add call sign to plane
                                scene.plane.updateCallSignText(response.value?.callsign ?? "")

                                if response.value!.action!.contains("departure") {
                                    stateMachine?.enter(DepartureState.self)
                                } else {
                                    stateMachine?.enter(RequestLandingState.self)
                                }

                            case .failure(let error):
                                #if DEBUG
                                debugPrint("Failure: \(error)")
                                #endif
                        }
                    }

                case .failure(let error):
                    #if DEBUG
                    debugPrint("Failure: \(error)")
                    #endif
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == DepartureState.self || stateClass == RequestLandingState.self
    }
}

class DepartureState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter departure state")
        #endif

        /// Rasa departure
        let parameters = RasaRequest(message: "departure", sender: scene.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                    debugPrint("Response: \(JSON)")
                    #endif

                    scene.sceneDelegate?.addRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

                    DispatchQueue.global(qos: .userInitiated).async {
                        scene.sceneDelegate?.synthesisToSpeaker(response.value?.text ?? "")
                    }

                    scene.sceneDelegate?.atisUpdate(data: response.value!)

                    scene.rasaData = response.value

                    scene.sceneDelegate?.setPlanePosition(spawnPoint: .Terminal)

                case .failure(let error):
                    #if DEBUG
                    debugPrint("Failure: \(error)")
                    #endif
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TaxiState.self
    }
}

class TaxiState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter taxi state")
        #endif

        switch scene.rasaData?.runway {
            case "28 RIGHT":
                scene.plane.node.run(scene.actions.terminalToB1StopBars) {
                    self.stateMachine?.enter(RequestTakeoffState.self)
                }
            case "10 LEFT":
                scene.plane.node.run(scene.actions.terminalToB5StopBars) {
                    self.stateMachine?.enter(RequestTakeoffState.self)
                }
            default:
                print(scene.rasaData?.runway ?? "")
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == RequestTakeoffState.self
    }
}

class RequestTakeoffState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter request takeoff state")
        #endif

        /// Rasa request takeoff
        let parameters = RasaRequest(message: "ready takeoff", sender: scene.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                    debugPrint("Response: \(JSON)")
                    #endif

                    scene.sceneDelegate?.addRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

                    DispatchQueue.global(qos: .userInitiated).async {
                        scene.sceneDelegate?.synthesisToSpeaker(response.value?.text ?? "")
                    }

                    scene.rasaData = response.value

                case .failure(let error):
                    #if DEBUG
                    debugPrint("Failure: \(error)")
                    #endif
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TakeoffState.self
    }
}

class TakeoffState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter takeoff state")
        #endif

        switch scene.rasaData?.runway {
            case "28 RIGHT":
                scene.plane.node.run(scene.actions.takeoff28R) { [self] in
                    scene.sceneDelegate?.finishPlanePlusOne()
                    stateMachine?.enter(GetSenderIDState.self)
                }
            case "10 LEFT":
                scene.plane.node.run(scene.actions.takeoff10L) { [self] in
                    scene.sceneDelegate?.finishPlanePlusOne()
                    stateMachine?.enter(GetSenderIDState.self)
                }
            default:
                print(scene.rasaData?.runway ?? "")
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == GetSenderIDState.self
    }
}

class RequestLandingState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter request landing state")
        #endif

        /// Rasa request landing
        let parameters = RasaRequest(message: "landing", sender: scene.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                    debugPrint("Response: \(JSON)")
                    #endif

                    scene.sceneDelegate?.addRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

                    DispatchQueue.global(qos: .userInitiated).async {
                        scene.sceneDelegate?.synthesisToSpeaker(response.value?.text ?? "")
                    }

                    scene.sceneDelegate?.atisUpdate(data: response.value!)

                    scene.rasaData = response.value

                case .failure(let error):
                    #if DEBUG
                    debugPrint("Failure: \(error)")
                    #endif
            }
        }

        scene.plane.node.position = scene.actions.getSceneCGPoint(spawnPonit: .Arrival28R)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == LandingState.self
    }
}

class LandingState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter landing state")
        #endif

        scene.plane.node.run(scene.actions.landing28RExitB3) {
            self.stateMachine?.enter(RequestTaxiState.self)
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == RequestTaxiState.self
    }
}

class RequestTaxiState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter request taxi state")
        #endif

        /// Rasa sends "Exit right on Bravo 3"
        var parameters = RasaRequest(message: "\(scene.rasaData?.callsign ?? "") exit right on Bravo 3", sender: scene.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                    debugPrint("Response: \(JSON)")
                    #endif

                    /// Rasa request taxi
                    parameters = RasaRequest(message: "ready taxi", sender: scene.senderID)

                    AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
                        switch response.result {
                            case .success(let JSON):
                                #if DEBUG
                                debugPrint("Response: \(JSON)")
                                #endif

                                scene.sceneDelegate?.addRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

                                DispatchQueue.global(qos: .userInitiated).async {
                                    scene.sceneDelegate?.synthesisToSpeaker(response.value?.text ?? "")
                                }

                            case .failure(let error):
                                #if DEBUG
                                debugPrint("Failure: \(error)")
                                #endif
                        }
                    }

                case .failure(let error):
                    #if DEBUG
                    debugPrint("Failure: \(error)")
                    #endif
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TaxiState2.self
    }
}

class TaxiState2: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter taxi state 2")
        #endif

        scene.plane.node.run(scene.actions.b3ToTerminal) { [self] in
            scene.sceneDelegate?.finishPlanePlusOne()
            stateMachine?.enter(GetSenderIDState.self)
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == GetSenderIDState.self
    }
}
