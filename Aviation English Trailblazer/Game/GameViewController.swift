//
//  GameViewController.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 8/11/2021.
//

import Alamofire
import GameplayKit
import MicrosoftCognitiveServicesSpeech
import SpriteKit
import UIKit

protocol GameViewControllerNavigation: AnyObject {
    func didPressExit(senderIDArr: [String])
}

class GameViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private var skView: SKView!
    @IBOutlet private var exitButton: UIButton!
    @IBOutlet private var timerLabel: TimerLabel!
    @IBOutlet private var planeQtyLabel: PlaneQtyLabel!
    @IBOutlet private var atisTextView: ATISTextView!
    @IBOutlet private var speechRecognizeTextView: UITextView!
    @IBOutlet private var speechLogTextView: SpeechLogTextView!
    @IBOutlet private var activityIndicatorView: UIActivityIndicatorView!

    // MARK: - Properties
    weak var navigationDelegate: GameViewControllerNavigation?

    private var viewModel: LevelDetailViewModelRepresentable?

    private var scene: GameScene?

    /// Azure subcription information
    private var sub: String!
    private var region: String!

    // Speech to text
    private var reco: SPXSpeechRecognizer?
    private var inputStack = Stack()
    private var isWordConfirmed: Bool = true

    // Text to speech
    private var synthesizer: SPXSpeechSynthesizer?
    private var voice: String = "en-US-GuyNeural"
    private var isSynthesizerSpeaking: Bool = false

    // MARK: - Initialization
    init(viewModel: LevelDetailViewModelRepresentable) {
        defer {
            self.viewModel = viewModel
        }

        super.init(nibName: GameViewController.name, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSpriteKitView()

        setupTimerLabel()

        /// Start timer
        timerLabel.runTimer()

        /// Set total plane number for planeQtyLabel
        planeQtyLabel.setTotal(total: viewModel!.planeQty)

        setupATISLabel()

        setupSpeechRecognizeTextView()

        setupSpeechLogTextView()

        /// Setup Microsoft Cognitive Services Speech SDK
        sub = "089b98e458c7445faa685d919a1c9ca8"
        region = "eastasia"

        /// Game over by time out
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
            if !timerLabel.isRunning() {
                print("Time out")
                timer.invalidate()
                /// Stop text to speech
                stopSynthesis()
                /// Stop timer
                timerLabel.pauseTimer()
                navigationDelegate?.didPressExit(senderIDArr: scene!.senderIDArr)
            }
        }

        /// Game over by finish level
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
            if planeQtyLabel.getFinishQty() == planeQtyLabel.getTotalQty() {
                print("Level finished")
                timer.invalidate()
                /// Stop text to speech
                stopSynthesis()
                /// Stop timer
                timerLabel.pauseTimer()
                navigationDelegate?.didPressExit(senderIDArr: scene!.senderIDArr)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    /// Specifies whether the view controller prefers the status bar to be hidden or shown.
    override var prefersStatusBarHidden: Bool {
        true
    }

    /// The key commands that trigger actions on this responder.
    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(title: "Release", action: #selector(PTTRelease), input: "a"),
            UIKeyCommand(title: "Push", action: #selector(PTTPush), input: "b"),
        ]
    }

    // MARK: - Funtions
    /// Push To Talk Pushed.
    @objc func PTTPush() {
        print("Pushed")

        recognizeFromMic()
    }

    /// Push To Talk Released.
    @objc func PTTRelease() {
        print("Released")

        stopRecognizeFromMic()

        // speechRecognizeTextView.text = "ALPHA SIERRA ROMEO 556 taxi via Hotel holding point of Bravo 1 expect runway 28 Right western departure"

        speechLogTextView.addColoredSpeech(speaker: "ATC", input: speechRecognizeTextView.text, color: .white)

        let parameters = RasaRequest(message: speechRecognizeTextView.text, sender: scene!.senderID)

        /// Empty text ready for next speech
        speechRecognizeTextView.text = ""
        inputStack.popAll()

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                        debugPrint("Response: \(JSON)")
                    #endif

                    /// Add text to log view
                    speechLogTextView.addColoredSpeech(speaker: (response.value?.callsign)!, input: response.value!.text, color: .yellow)

                    DispatchQueue.global(qos: .userInitiated).async {
                        synthesisToSpeaker(response.value?.text ?? "")
                    }

                    if (response.value?.havepermission)! {
                        scene?.stateMachine?.enter(TaxiState.self)
                        scene?.stateMachine?.enter(TakeoffState.self)
                        scene?.stateMachine?.enter(LandingState.self)
                        scene?.stateMachine?.enter(TaxiState2.self)
                    }

                case .failure(let error):
                    #if DEBUG
                        debugPrint("Failure: \(error)")
                    #endif
            }
        }
    }

    func recognizeFromMic() {
        print("Listening...")

        var speechConfig: SPXSpeechConfiguration?

        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
            speechConfig?.endpointId = "8663d17c-cbe1-46a3-b72c-3c6d216afdcc"
            speechConfig?.speechRecognitionLanguage = "en-HK"
            speechConfig?.enableAudioLogging()
            speechConfig?.requestWordLevelTimestamps()
            speechConfig?.enableDictation()
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }

        reco = try! SPXSpeechRecognizer(speechConfiguration: speechConfig!, audioConfiguration: SPXAudioConfiguration())

        /// Connect callback
        reco!.addRecognizingEventHandler { [self] _, evt in

            print("RECOGNIZING: \(evt.result.text ?? "")")

            if isWordConfirmed {
                inputStack.push(evt.result.text ?? "")
                isWordConfirmed = false
            } else {
                _ = inputStack.pop()
                inputStack.push(evt.result.text ?? "")
            }

            updateLabel()
        }

        reco!.addRecognizedEventHandler { [self] _, evt in

            if evt.result.reason == .recognizedSpeech {
                print("RECOGNIZED: \(evt.result.text ?? "")")

                if isWordConfirmed {
                } else {
                    _ = inputStack.pop()
                    inputStack.push(evt.result.text ?? "")
                    isWordConfirmed = true

                    updateLabel()
                }

            } else if evt.result.reason == .noMatch {
                print("NOMATCH: Speech could not be recognized.")
            }
        }

        reco!.addSessionStoppedEventHandler { [self] _, _ in
            print("Session stopped event.")

            stopRecognizeFromMic()
        }

        reco!.addCanceledEventHandler { [self] _, evt in
            print("CANCELED: Reason= \(evt.reason)")

            if evt.reason == .error {
                print("CANCELED: ErrorCode= \(evt.errorCode)")
                print("CANCELED: ErrorDetails= \(evt.errorDetails as String?)")
                print("CANCELED: Did you update the subscription info?")
            }

            stopRecognizeFromMic()
        }

        do {
            try reco?.startContinuousRecognition()
        } catch {
            print("error \(error) happened")
        }
    }

    func stopRecognizeFromMic() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            print("Stop Recognizing...")

            do {
                try reco?.stopContinuousRecognition()
            } catch {
                print("error \(error) happened")
            }
        }
    }

    func updateLabel() {
        DispatchQueue.main.async { [self] in
            speechRecognizeTextView.text = inputStack.printAll()
        }
    }

    func stopSynthesis() {
        do {
            try synthesizer?.stopSpeaking()
        } catch {
            print("error \(error) happened")
        }
    }

    private func setupSpriteKitView() {
        guard let scene = GameScene(fileNamed: "GameScene") else { return }
        self.scene = scene

        scene.size = skView.bounds.size
        scene.scaleMode = .aspectFill

        scene.sceneDelegate = self
        scene.setViewModel(viewModel)

        #if DEBUG
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsDrawCount = true
        #endif

        // SpriteKit applies additional optimizations to improve rendering performance.
        skView.ignoresSiblingOrder = true

        skView.presentScene(scene)
    }

    private func setupTimerLabel() {
        /// Set timer to 10 minutes
        timerLabel.resetTimer(seconds: 9000)
    }

    private func setupATISLabel() {
        atisTextView.layer.contents = UIImage(named: "ATIS Border")?.cgImage

        /// Init ATIS text
        atisTextView.update(action: "", runway: "", degree: "", knot: "", information: "")
    }

    private func setupSpeechRecognizeTextView() {
        speechRecognizeTextView.textContainer.maximumNumberOfLines = 1
        speechRecognizeTextView.textContainer.lineBreakMode = .byTruncatingHead
        /// Add padding to textView
        speechRecognizeTextView.textContainerInset = UIEdgeInsets(top: 6, left: 15, bottom: 0, right: 25)
        /// Add background to textView
        speechRecognizeTextView.layer.contents = UIImage(named: "Speech Recognize Border")?.cgImage
    }

    private func setupSpeechLogTextView() {
        /// Add padding to textView
        speechLogTextView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 0, right: 5)
        /// Add background to textView
        speechLogTextView.layer.contents = UIImage(named: "Speech Log Border")?.cgImage
    }

    @IBAction func exitButtonAction(_ sender: UIButton) {
        print("Exit button pressed")
        /// Stop text to speech
        stopSynthesis()
        /// Stop timer
        timerLabel.pauseTimer()
        navigationDelegate?.didPressExit(senderIDArr: scene!.senderIDArr)
    }
}

extension GameViewController: GameSceneDelegate {
    func gameSceneDidEnd(_ gameScene: GameScene) {
//        guard let viewModel = viewModel else { return }
//        navigationDelegate?.gameViewController(self, didEndGameWith: viewModel.score.value)
    }

    /// Add Rasa returned text to speechLogTextView
    func showRasaSpeech(speaker: String, _ text: String) {
        speechLogTextView.addColoredSpeech(speaker: speaker, input: text, color: .yellow)
    }

    /// Update ATIS by passed model
    func atisUpdate(data: RasaResponse) {
        atisTextView.update(action: data.action ?? "", runway: data.runway ?? "", degree: data.degree ?? "", knot: data.knot ?? "", information: data.information ?? "")
    }

    /// Set plane position to some spawn point
    func setPlanePosition(spawnPoint: SpawnPoint) {
        scene?.plane.node.position = scene?.actions.getSceneCGPoint(spawnPonit: spawnPoint) ?? CGPoint(x: 0, y: 0)
    }

    func finishPlanePlusOne() {
        planeQtyLabel.finishQtyPlusOne()
    }

    func synthesisToSpeaker(_ text: String) {
        if text.isEmpty {
            return
        }

        var speechConfig: SPXSpeechConfiguration?

        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
            /// Set the synthesis language
            speechConfig?.speechSynthesisLanguage = String(voice.prefix(5))
            /// Set the voice name
            speechConfig?.speechSynthesisVoiceName = voice
            /// Set the synthesis output format
            speechConfig?.setSpeechSynthesisOutputFormat(.riff16Khz16BitMonoPcm)
        } catch {
            print("error \(error) happened")
            speechConfig = nil
        }

        synthesizer = try! SPXSpeechSynthesizer(speechConfiguration: speechConfig!, audioConfiguration: SPXAudioConfiguration())

        // Connect callbacks
        synthesizer!.addSynthesisStartedEventHandler { _, _ in
            print("Synthesis started.")

            self.isSynthesizerSpeaking = true
        }

        synthesizer!.addSynthesizingEventHandler { _, _ in
            print("Synthesizing.")

            self.isSynthesizerSpeaking = true
        }

        synthesizer!.addSynthesisCompletedEventHandler { _, _ in
            print("Speech synthesis was completed.")

            self.isSynthesizerSpeaking = false
        }

        synthesizer!.addSynthesisCanceledEventHandler { _, evt in
            let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: evt.result)
            print("CANCELED: ErrorCode= \(cancellationDetails.errorCode.rawValue)")
            print("CANCELED: ErrorDetails= \(cancellationDetails.errorDetails as String?)")
            print("CANCELED: Did you update the subscription info?")

            self.isSynthesizerSpeaking = false
        }

        synthesizer!.addSynthesisWordBoundaryEventHandler { _, evt in
            print("Word boundary event received. Audio offset: \(evt.audioOffset / 10000), text offset: \(evt.textOffset), word length: \(evt.wordLength)")

            self.isSynthesizerSpeaking = true
        }

        do {
            /// Make a 0.5s pause between two speech
            while isSynthesizerSpeaking {
                sleep(UInt32(0.5))
            }
            try synthesizer?.speakText(text.replacingOccurrences(matchingPattern: "\\d", replacementProvider: { numbers[$0] }))

            // try synthesizer!.speakText(text)

        } catch {
            print("error \(error) happened")
        }
    }

    func startActivityIndicatorView() {
        activityIndicatorView.startAnimating()
    }

    func stopActivityIndicatorView() {
        activityIndicatorView.stopAnimating()
    }
}
