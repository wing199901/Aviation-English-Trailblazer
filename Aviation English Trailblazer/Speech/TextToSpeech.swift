//
//  TextToSpeech.swift
//  ATC
//
//  Created by Steven Siu  on 15/12/2020.
//  Copyright © 2020 Steven Siu . All rights reserved.
//

import MicrosoftCognitiveServicesSpeech

class TextToSpeech {
    // MARK: Properties

    static let shared = TextToSpeech()

    var sub: String!
    var region: String!
    var synthesizer = SPXSpeechSynthesizer()
    var speechConfig: SPXSpeechConfiguration?
    let audioConfig = SPXAudioConfiguration()

    var voice: String = "en-US-GuyNeural"

    var isSpeaking: Bool = false

    // MARK: - Initialization

    private init() {
        // load subscription information
        sub = "89b56f435e4b4586bf98288c2318aa59"
        region = "eastasia"

        do {
            try speechConfig = SPXSpeechConfiguration(subscription: sub, region: region)
        } catch {
            print("error \(error) happened")
            speechConfig = nil
            return
        }
    }

    // MARK: Method

    func synthesisToSpeaker(_ text: String) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            /// Set the synthesis language
            speechConfig?.speechSynthesisLanguage = String(voice.prefix(5))
            /// Set the voice name
            speechConfig?.speechSynthesisVoiceName = voice
            /// Set the synthesis output format
            speechConfig?.setSpeechSynthesisOutputFormat(.riff16Khz16BitMonoPcm)

            synthesizer = try! SPXSpeechSynthesizer(speechConfiguration: speechConfig!, audioConfiguration: audioConfig)

            if text.isEmpty {
                return
            }

            // Connect callbacks
            synthesizer.addSynthesisStartedEventHandler { _, _ in
                print("Synthesis started.")
                isSpeaking = true
            }

            synthesizer.addSynthesizingEventHandler { _, _ in
                print("Synthesizing.")
                isSpeaking = true
            }

            synthesizer.addSynthesisCompletedEventHandler { _, _ in
                print("Speech synthesis was completed.")
                isSpeaking = false
            }

            synthesizer.addSynthesisCanceledEventHandler { _, evt in
                let cancellationDetails = try! SPXSpeechSynthesisCancellationDetails(fromCanceledSynthesisResult: evt.result)
                print("CANCELED: ErrorCode= \(cancellationDetails.errorCode.rawValue)")
                print("CANCELED: ErrorDetails= \(cancellationDetails.errorDetails as String?)")
                print("CANCELED: Did you update the subscription info?")
                isSpeaking = false
            }

            synthesizer.addSynthesisWordBoundaryEventHandler { _, evt in
                print("Word boundary event received. Audio offset: \(evt.audioOffset / 10000), text offset: \(evt.textOffset), word length: \(evt.wordLength)")
                isSpeaking = true
            }

            // Start speaking
            do {
                while isSpeaking {
                    sleep(UInt32(0.5))
                }
//                try synthesizer.speakText(text.replacingOccurrences(matchingPattern: "\\d", replacementProvider: { numbers[$0] }))

                try synthesizer.speakText(text)

            } catch {
                print("error \(error) happened")
            }
        }
    }

    func stopSpeaking() {
        do {
            try synthesizer.stopSpeaking()
        } catch {
            print("error \(error) happened")
        }
    }

    func getNewVoice() {
        var newVoice = voice

        while newVoice == voice {
            newVoice = Voice.random().rawValue as String
            print("Old Voice: \(voice)")
            print("New Voice: \(newVoice)")
        }

        voice = newVoice
    }
}
