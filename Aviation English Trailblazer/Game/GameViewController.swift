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
    @IBOutlet private var skView: SKView!
    @IBOutlet private var exitButton: UIButton!
    @IBOutlet private var timerLabel: TimerLabel!
    @IBOutlet var planeQtyLabel: PlaneQtyLabel!
    @IBOutlet var atisTextView: ATISTextView!
    @IBOutlet private var speechRecognizeTextView: UITextView!
    @IBOutlet var speechLogTextView: SpeechLogTextView!

    weak var navigationDelegate: GameViewControllerNavigation?

    private var viewModel: LevelDetailViewModelRepresentable?

    var scene: GameScene?

    // Azure
    var sub: String!
    var region: String!

    // Speech to text
    var reco: SPXSpeechRecognizer?
    var inputStack = Stack()
    var isWordConfirmed: Bool = true

    // Text to speech
    var synthesizer: SPXSpeechSynthesizer?
    var voice: String = "en-US-GuyNeural"
    var isSpeaking: Bool = false

    // Rasa

    var scenarioID: String = "001000" // 001100

    var senderID: String = ""

    var senderIDArr = [String]()

    init(viewModel: LevelDetailViewModelRepresentable) {
        defer {
            self.viewModel = viewModel
        }

        // self.scene = GameScene(size: .zero, viewModel: viewModel)

        super.init(nibName: GameViewController.name, bundle: nil)

        scenarioID = scenarioID.replacingOccurrences(of: "1", with: String(viewModel.id))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSpriteKitView()

        timerLabel.resetTimer(seconds: 600)
        timerLabel.runTimer()

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
            if !timerLabel.isRunning() {
                timer.invalidate()
                /// Stop text to speech
                stopSynthesis()
                navigationDelegate?.didPressExit(senderIDArr: senderIDArr)
            }
        }

        planeQtyLabel.setTotal(total: viewModel!.planeQty)
//        planeQtyLabel.isHidden = true

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
            if planeQtyLabel.finished == planeQtyLabel.total {
                timer.invalidate()
                /// Stop text to speech
                stopSynthesis()
                navigationDelegate?.didPressExit(senderIDArr: senderIDArr)
            }
        }

        atisTextView.layer.contents = UIImage(named: "ATIS Border")?.cgImage
        atisTextView.update(action: "", runway: "", degree: "", knot: "", information: "")

        setupSpeechRecognizeTextView()

        setupSpeechLogTextView()

        sub = "089b98e458c7445faa685d919a1c9ca8"
        region = "eastasia"

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

        // Text to speech

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

            self.isSpeaking = true
        }

        synthesizer!.addSynthesizingEventHandler { _, _ in
            print("Synthesizing.")

            self.isSpeaking = true
        }

        synthesizer!.addSynthesisCompletedEventHandler { _, _ in
            print("Speech synthesis was completed.")

            self.isSpeaking = false
        }

        synthesizer!.addSynthesisCanceledEventHandler { _, evt in
            let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: evt.result)
            print("CANCELED: ErrorCode= \(cancellationDetails.errorCode.rawValue)")
            print("CANCELED: ErrorDetails= \(cancellationDetails.errorDetails as String?)")
            print("CANCELED: Did you update the subscription info?")

            self.isSpeaking = false
        }

        synthesizer!.addSynthesisWordBoundaryEventHandler { _, evt in
            print("Word boundary event received. Audio offset: \(evt.audioOffset / 10000), text offset: \(evt.textOffset), word length: \(evt.wordLength)")

            self.isSpeaking = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

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

    // MARK: - Method

    /// Push To Talk Released.
    @objc func PTTRelease() {
        print("Released")

        stopRecognizeFromMic()

//        speechRecognizeTextView.text = "ALPHA SIERRA ROMEO 556 taxi via Hotel holding point of Bravo 1 expect runway 28 Right western departure"

        speechLogTextView.addColoredSpeech(speaker: "ATC", input: speechRecognizeTextView.text, color: .white)

        let parameters = RasaRequest(message: speechRecognizeTextView.text, sender: senderID)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")

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
                    debugPrint("Failure: \(error)")
            }
        }

        /// Empty text ready for next speech
        speechRecognizeTextView.text = ""
        inputStack.popAll()
    }

    /// Push To Talk Pushed.
    @objc func PTTPush() {
        print("Pushed")
//        if skView.scene!.name == "Base" || skView.scene!.name!.contains("Level") {
//        if SpeechToText.shared.state == .idle {
//            SpeechToText.shared.recognizeFromMic()
//        }
//        }

        // Empty text for next speech
        speechRecognizeTextView.text = ""
        inputStack.popAll()

        recognizeFromMic()
    }

    func recognizeFromMic() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            print("Listening...")

            // Start recording and append recording buffer to speech recognizer

            do {
                try reco!.startContinuousRecognition()
            } catch {
                print("error \(error) happened")
            }
        }
    }

    func stopRecognizeFromMic() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            print("Stop Recognizing...")

            do {
                try reco!.stopContinuousRecognition()
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

    func synthesisToSpeaker(_ text: String) {
        // Start speaking
        do {
            while isSpeaking {
                sleep(UInt32(0.5))
            }
            try synthesizer!.speakText(text.replacingOccurrences(matchingPattern: "\\d", replacementProvider: { numbers[$0] }))

//            try synthesizer!.speakText(text)

        } catch {
            print("error \(error) happened")
        }
    }

    func stopSynthesis() {
        do {
            try synthesizer!.stopSpeaking()
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
        scene.setViewModel(viewModel: viewModel)
        scene.viewController = self

        #if DEBUG
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsDrawCount = true
        #endif

        skView.presentScene(scene)

        // SpriteKit applies additional optimizations to improve rendering performance.
        skView.ignoresSiblingOrder = true
    }

    private func setupSpeechRecognizeTextView() {
        speechRecognizeTextView.layer.contents = UIImage(named: "Speech Recognize Border")?.cgImage
        speechRecognizeTextView.textContainer.maximumNumberOfLines = 1
        speechRecognizeTextView.textContainer.lineBreakMode = .byTruncatingHead
    }

    private func setupSpeechLogTextView() {
        speechLogTextView.layer.contents = UIImage(named: "Speech Log Border")?.cgImage
    }

    @IBAction func exitButtonAction(_ sender: UIButton) {
        navigationDelegate?.didPressExit(senderIDArr: senderIDArr)
    }
}

extension GameViewController: GameSceneDelegate {
    func gameSceneDidEnd(_ gameScene: GameScene) {
//        guard let viewModel = viewModel else { return }
//        animateScore(with: .disappearing)
//        navigationDelegate?.gameViewController(self, didEndGameWith: viewModel.score.value)
    }
}

let natoAlphabet = ["A": "Alpha", "B": "Bravo", "C": "Charlie", "D": "Delta", "E": "Echo", "F": "Foxtrot", "G": "Golf", "H": "Hotel", "I": "India", "J": "Juliett", "K": "Kilo", "L": "Lima", "M": "Mike", "N": "November", "O": "Oscar", "P": "Papa", "Q": "Quebec", "R": "Romeo", "S": "Sierra", "T": "Tango", "U": "Uniform", "V": "Victor", "W": "Whiskey", "X": "X-ray", "Y": "Yankee", "Z": "Zulu", "0": "0", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "6": "6", "7": "7", "8": "8", "9": "9"]

let numbers = ["0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six", "7": "seven", "8": "eight", "9": "niner"]

extension String {
    func nato(str: String) -> String {
        var newString = ""
        for char in str {
            char == " " || char.isNumber ? newString.append(char) : newString.append(natoAlphabet[String(char).uppercased()]! + " ")
        }
        return newString
    }

    func replacingOccurrences(matchingPattern pattern: String) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = expression.matches(in: self, options: [], range: NSRange(startIndex ..< endIndex, in: self))
        return matches.reversed().reduce(into: self) { current, result in
            let range = Range(result.range, in: current)!
            let token = String(current[range])
            let replacement = nato(str: token)
            current.replaceSubrange(range, with: replacement)
        }
    }

    func replacingOccurrences(matchingPattern pattern: String, replacementProvider: (String) -> String?) -> String {
        let expression = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = expression.matches(in: self, options: [], range: NSRange(startIndex ..< endIndex, in: self))
        return matches.reversed().reduce(into: self) { current, result in
            let range = Range(result.range, in: current)!
            let token = String(current[range])
            guard let replacement = replacementProvider(token) else { return }
            current.replaceSubrange(range, with: " " + replacement)
        }
    }
}
