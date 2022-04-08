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
    func showRasaSpeech(speaker: String, _ text: String)
    func atisUpdate(data: RasaResponse)
    func setPlanePosition(spawnPoint: SpawnPoint)
    func finishPlanePlusOne()
    func synthesisToSpeaker(_ text: String)
    func startActivityIndicatorView()
    func stopActivityIndicatorView()
}

class GameScene: SKScene {
    // MARK: - Sprites
    var plane: Plane!
    var npc: Plane!
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

        stateMachine = GKStateMachine(states: [
            GetSenderIDState(scene: self),
            DepartureState(scene: self),
            TaxiState(scene: self),
            RequestTakeoffState(scene: self),
            TakeoffState(scene: self),
            RequestLandingState(scene: self),
            LandingState(scene: self),
            RequestTaxiState(scene: self),
            TaxiState2(scene: self),
            RequestCrossState(scene: self),
        ]
        )

        stateMachine?.enter(GetSenderIDState.self)
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered

        /// Update plane position and rotation
        plane.update()
    }

    // MARK: - Functions
    func setViewModel(_ viewModel: LevelDetailViewModelRepresentable?) {
        self.viewModel = viewModel
    }

    /// Setup all sprite position and rotation
    func setupSprite() {
        map = childNode(withName: "Map") as! SKSpriteNode

        actions = Path(airport: map, screenFrame: frame)

        plane = Plane(type: .player)
        plane.node.position = actions.getSceneCGPoint(spawnPonit: .Terminal)
        plane.addCallSign("")

        npc = Plane(type: .npc)
        npc.node.position = actions.getSceneCGPoint(spawnPonit: .Eastern)
        npc.node.zRotation = CGFloat(80).degreesToRadians()

        npc.addCallSign("")
        npc.node.isHidden = true

        addChild(plane.node)
        addChild(npc.node)
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

        /// Each plane equal a scenrio id.
        /// Fisrt plane of level one = 001100
        /// 001 = level 1
        /// 100 = first plane
        scene.scenarioID = String(format: "%04d", (Int(scene.scenarioID.prefix(4)) ?? 0) + 1) + "00"

        /// Rasa get sender id by the scenario id
        var parameters = RasaRequest(message: "getid", sender: scene.scenarioID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                    debugPrint("Response: \(JSON)")
                    #endif

                    scene.senderID = response.value?.text ?? ""
                    /// Record all sender id for end game log
                    scene.senderIDArr.append(response.value?.text ?? "")

                    /// PSOT "information text" to RASA to get json with details
                    parameters = RasaRequest(message: "information text", sender: scene.senderID)

                    AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
                        switch response.result {
                            case .success(let JSON):
                                #if DEBUG
                                debugPrint("Response: \(JSON)")
                                #endif

                                /// Display call sign under plane sprite
                                scene.plane.updateCallSignText(response.value?.callsign_short ?? "")

                                /// Crossable decide npc hidden
                                if response.value?.crossable ?? false {
                                    scene.npc.node.isHidden = false
                                    /// taxi from J1 to 22L
                                    scene.npc.node.run(scene.actions.j1To22LStopBars)
                                }

                                /// Decide what state the plane gonna go
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

    override func willExit(to nextState: GKState) {
        /// Hide indicator view after get responce from server
        scene.sceneDelegate?.stopActivityIndicatorView()
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

                    /// Show the line from Rasa
                    scene.sceneDelegate?.showRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

                    DispatchQueue.global(qos: .userInitiated).async {
                        /// Speak the line from Rasa
                        scene.sceneDelegate?.synthesisToSpeaker(response.value?.text ?? "")
                    }

                    /// Update ATIS information
                    scene.sceneDelegate?.atisUpdate(data: response.value!)

                    /// Store Rasa Responce for next state use
                    scene.rasaData = response.value

                    /// Set postion when plane spawn
                    switch response.value?.spawn {
                        case "TERMINAL":
                            scene.sceneDelegate?.setPlanePosition(spawnPoint: .Terminal)
                        case "APRON":
                            scene.sceneDelegate?.setPlanePosition(spawnPoint: .Eastern)
                        default:
                            break
                    }

                    /// Set plane heading
                    scene.plane.node.zRotation = CGFloat(80).degreesToRadians()

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
                if (scene.rasaData?.crossable)! {
                    scene.plane.node.run(scene.actions.j1To04RStopBars) {
                        self.stateMachine?.enter(RequestCrossState.self)
                    }
                } else {
                    scene.plane.node.run(scene.actions.terminalToB5StopBars) {
                        self.stateMachine?.enter(RequestTakeoffState.self)
                    }
                }

            default:
                print(scene.rasaData?.runway ?? "")
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == RequestCrossState.self || stateClass == RequestTakeoffState.self
    }
}

class RequestCrossState: GKState {
    unowned let scene: GameScene

    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        #if DEBUG
        debugPrint("Enter request cross state")
        #endif

        /// NPC plane takeoff first
        scene.npc.node.run(scene.actions.takeoff22L)

        /// Rasa request cross
        let parameters = RasaRequest(message: "ready cross", sender: scene.senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                    debugPrint("Response: \(JSON)")
                    #endif

                    scene.sceneDelegate?.showRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

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
        stateClass == TaxiState2.self
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

                    scene.sceneDelegate?.showRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

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

                    scene.sceneDelegate?.showRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

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

                                scene.sceneDelegate?.showRasaSpeech(speaker: response.value?.callsign ?? "", response.value?.text ?? "")

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

        if (scene.rasaData?.crossable)! {
            scene.plane.node.run(scene.actions.taxiway04RStopBarsToB5StopBars) { [self] in
                stateMachine?.enter(RequestTakeoffState.self)
            }
        } else {
            switch scene.rasaData?.destination {
                case "TERMINAL":
                    scene.plane.node.run(scene.actions.b3ToTerminal) { [self] in
                        scene.sceneDelegate?.finishPlanePlusOne()
                        stateMachine?.enter(GetSenderIDState.self)
                    }
                case "APRON":
                    scene.plane.node.run(scene.actions.b3ToJ1) { [self] in
                        scene.sceneDelegate?.finishPlanePlusOne()
                        stateMachine?.enter(GetSenderIDState.self)
                    }
                default:
                    break
            }
        }
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == RequestTakeoffState.self || stateClass == GetSenderIDState.self
    }
}
