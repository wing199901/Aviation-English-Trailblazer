//
//  GameViewController.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 8/11/2021.
//

import Alamofire
import AVFoundation
import GameplayKit
import MicrosoftCognitiveServicesSpeech
import SpriteKit
import UIKit

protocol GameViewControllerNavigation: AnyObject {
    func didPressExit(senderIDArr: [String])
}

class GameViewController: UIViewController, AVAudioRecorderDelegate {
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

    /// Speech to text
    private var reco: SPXSpeechRecognizer?
    private var inputStack = Stack()
    private var isWordConfirmed: Bool = true

    /// Text to speech
    private var synthesizer: SPXSpeechSynthesizer?
    // private var voice: String = "en-US-GuyNeural"
    private var isSynthesizerSpeaking: Bool = false

    private var speechConfig: SPXSpeechConfiguration!

    /// Audio record for pronunciation assessment
//    private var recordingSession: AVAudioSession = .sharedInstance()
//    private var audioRecorder: AVAudioRecorder?
//    private var numOfRecorder: Int = 0

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

        /// load subscription information
        sub = "089b98e458c7445faa685d919a1c9ca8"
        region = "eastasia"

        /// Setup UI
        setupSpriteKitView()

        setupTimerLabel()

        /// Start timer
        timerLabel.runTimer()

        /// Set total plane number for planeQtyLabel
        planeQtyLabel.setTotal(total: viewModel!.planeQty)

        setupATISLabel()

        setupSpeechRecognizeTextView()

        setupSpeechLogTextView()

        /// Setup recording session
//        do {

        /// Audio record for pronunciation assessment
//        try! recordingSession.setCategory(.playAndRecord, mode: .default)
//        try! recordingSession.setActive(true)
//            recordingSession.requestRecordPermission { [unowned self] allowed in
//                DispatchQueue.main.async {
//                    if allowed {
//                        //
//                    } else {
//                        // failed to record!
//                    }
//                }
//            }
//        } catch {
//            // failed to record!
//        }

        /// Create a timer and schedules it on the current run loop
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
            /// Game over with time out
            if !timerLabel.isRunning() {
                print("Time out")
                timer.invalidate()
                /// Stop text to speech
                stopSynthesis()
                /// Stop timer
                timerLabel.pauseTimer()
                navigationDelegate?.didPressExit(senderIDArr: scene!.senderIDArr)
            }

            /// Game over with finish level
            if planeQtyLabel.getFinishQty() == planeQtyLabel.getTotalQty() {
                print("Level finished")
                timer.invalidate()
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
    /// Push To Talk button Pushed.
    @objc func PTTPush() {
        print("Pushed")

        /// Clear textVeiw text
        /// UI Update use main thread
        DispatchQueue.main.async { [self] in
            speechRecognizeTextView.text = ""
            inputStack.popAll()
        }

        /// Audio record for pronunciation assessment
//        DispatchQueue.main.async {
//            self.startAudioRecording()
//        }
        recognizeFromMic()
        // pronunciationAssessFromMic()
    }

    /// Push To Talk button Released.
    @objc func PTTRelease() {
        print("Released")

        stopRecognizeFromMic()
        /// Audio record for pronunciation assessment
//        stopAudioRecording()
//        DispatchQueue.global().async {
//            self.pronunciationAssessFromFile(reference: "Alpha Sierra Romeo 556, taxi via Hotel, holding point of Bravo 1, expect runway 28 Right, western departure")
//        }

        /// Add User Speech
        speechLogTextView.addColoredSpeech(speaker: "ATC", input: speechRecognizeTextView.text, color: .white)

        let parameters = RasaRequest(message: speechRecognizeTextView.text, sender: scene!.senderID)

        /// Clear text ready for next speech
        /// UI Update use main thread
        DispatchQueue.main.async { [self] in
            speechRecognizeTextView.text = ""
            inputStack.popAll()
        }

        /// Get Result from Rasa
        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/webhooks/rest/webhook", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                        debugPrint("Response: \(JSON)")
                    #endif

                    /// Add text to log view
                    speechLogTextView.addColoredSpeech(speaker: (response.value?.callsign)!, input: response.value!.text, color: .yellow)

                    /// Making sound
                    DispatchQueue.global(qos: .userInitiated).async {
                        synthesisToSpeaker(response.value?.text ?? "")
                    }

                    /// Get reference sentence form Rasa and do the pronunciation assessment
//                    DispatchQueue.global().async {
//                          self.pronunciationAssessFromFile(reference: "")
//                    }

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

    ///  Audio record for pronunciation assessment
//    func startAudioRecording() {
//        let audioFileURL = getDocumentsDirectory().appendingPathComponent("recording.wav")
//
//        let settings: [String: Any] = [
//            AVFormatIDKey: kAudioFormatLinearPCM,
//            AVSampleRateKey: 16000, // or 8000
//            AVNumberOfChannelsKey: 1,
//            AVLinearPCMBitDepthKey: 16,
//        ]
//
//        do {
//            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
//            audioRecorder?.delegate = self
//
//            print("Start audio recording")
//            audioRecorder?.record()
//
//        } catch {
//            print("Audio recording error: \(error)")
//            // Stop recording
//            stopAudioRecording()
//        }
//    }
//
//    ///  Audio record for pronunciation assessment
//    func stopAudioRecording() {
//        print("Stop audio recording")
//        audioRecorder?.stop()
//        audioRecorder = nil
//
//        let audioFileURL = getDocumentsDirectory().appendingPathComponent("recording.wav")
//
//        let audioAsset = AVURLAsset(url: audioFileURL)
//        print("Audio file size: \(audioAsset.fileSize ?? 0)")
//    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func pronunciationAssessFromFile(reference text: String) {
        let pronFile = getDocumentsDirectory().appendingPathComponent("recording.wav")

        guard let pronAudioSource = SPXAudioConfiguration(wavFileInput: pronFile.path) else { return }

        let speechConfig = try! SPXSpeechConfiguration(subscription: sub, region: region)
        speechConfig.speechRecognitionLanguage = "en-HK"
        // speechConfig.setPropertyTo("3000", by: .speechServiceConnectionEndSilenceTimeoutMs)

        let speechRecognizer = try! SPXSpeechRecognizer(speechConfiguration: speechConfig, audioConfiguration: pronAudioSource)

        /// Create pronunciation assessment config
        let pronunicationConfig = try! SPXPronunciationAssessmentConfiguration(text, gradingSystem: .hundredMark, granularity: .word, enableMiscue: true)

        try! pronunicationConfig.apply(to: speechRecognizer)
        print("Assessing")

        /// connect callback
        speechRecognizer.addRecognizedEventHandler { _, evt in
            let jsonResult = evt.result.properties?.getPropertyBy(.speechServiceResponseJsonResult)

            let jsonResultData = jsonResult?.data(using: .utf8)

            let pronunciationAssessmentResult = try? JSONDecoder().decode(PronunciationAssessmentResult.self, from: jsonResultData!)

            let words = pronunciationAssessmentResult?.nBest[0].words

            for word in words ?? [] {
                /// For-in loop requires '[Word]?' to conform to 'Sequence'; did you mean to unwrap optional?
                /// https://stackoverflow.com/questions/64404208/for-in-loop-requires-uservehicles-to-conform-to-sequence-did-you-mean-to/64404236#:~:text=for%20i%20in%20vehicleList%3F._embedded.userVehicles%20%3F%3F%20%5B%5D%20%7B%20%7D
                print(word)
            }

            // print(pronunciationAssessmentResult?.nBest[0].words[0].word ?? "")

            print()

            let pronunciationResult = SPXPronunciationAssessmentResult(evt.result)

            #if DEBUG
                print("""
                Received final result event.
                Recognition result: \(evt.result.text ?? "")
                Accuracy score: \(pronunciationResult?.accuracyScore ?? 0)
                Pronunciation score: \(pronunciationResult?.pronunciationScore ?? 0)
                Completeness Score: \(pronunciationResult?.completenessScore ?? 0)
                Fluency score: \(pronunciationResult?.fluencyScore ?? 0)
                """)
            #endif
        }

        var end = false

        speechRecognizer.addCanceledEventHandler { _, evt in
            let details: SPXCancellationDetails = try! SPXCancellationDetails(fromCanceledRecognitionResult: evt.result)
            #if DEBUG
                debugPrint("Pronunciation assessment was canceled: \(details.errorDetails ?? "")Did you pass the correct key/region combination?")
            #endif
            end = true
        }

        /// session stopped callback to recognize stream has ended
        speechRecognizer.addSessionStoppedEventHandler { _, evt in
            #if DEBUG
                debugPrint("Received session stopped event. SessionId: \(evt.sessionId)")
            #endif
            end = true
        }

        /// start recognizing
        try! speechRecognizer.startContinuousRecognition()

        /// wait until a session stopped event has been received
        while end == false {
            sleep(1)
        }

        try! speechRecognizer.stopContinuousRecognition()
    }

    // MARK: - SST Funtions
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

    // MARK: - Setup UI Funtions
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
        timerLabel.resetTimer(seconds: 1800)
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
        // guard let viewModel = viewModel else { return }
        // navigationDelegate?.gameViewController(self, didEndGameWith: viewModel.score.value)
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

    // MARK: - TTS Funtions
    func synthesisToSpeaker(_ text: String) {
        if text.isEmpty {
            return
        }

        var speechConfig: SPXSpeechConfiguration?

        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
            /// Set the synthesis language
            //            speechConfig?.speechSynthesisLanguage = String(voice.prefix(5))
            /// Set the voice name
            //            speechConfig?.speechSynthesisVoiceName = voice
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

        synthesizer!.addSynthesisWordBoundaryEventHandler { _, _ in
//            print("Word boundary event received. Audio offset: \(evt.audioOffset / 10000), text offset: \(evt.textOffset), word length: \(evt.wordLength)")

            self.isSynthesizerSpeaking = true
        }

        do {
            /// Make a 0.1s pause between two speech
            while isSynthesizerSpeaking {
                sleep(UInt32(0.1))
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
