//
//  SpeechLogTextView.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 29/11/2021.
//

import MicrosoftCognitiveServicesSpeech
import UIKit.UITextView

class SpeechLogTextView: UITextView {
    var log = NSMutableAttributedString()

    override var attributedText: NSAttributedString! {
        willSet {
            scrollToBottom()
        }
        didSet {
            scrollToBottom()
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Use this method to add colored text to the speech log.
    func addColoredSpeech(speaker: String, input: String, color: UIColor) {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timestamp = dateFormatter.string(from: now)

        let attributes = [NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.font: UIFont(name: "MyriadPro-Regular", size: 20)]
        let attributeStr = NSAttributedString(string: "[\(timestamp)] " + "<\(speaker)> " + input + "\n\n", attributes: attributes as [NSAttributedString.Key: Any])

        log.append(attributeStr)

        attributedText = log

        // print(attributeStr.string)
    }
}

extension SpeechLogTextView {
    func scrollToBottom() {
        let textCount: Int = text.count
        guard textCount >= 1 else { return }
        scrollRangeToVisible(NSRange(location: textCount - 2, length: 1))

        /// an iOS bug, see https://stackoverflow.com/a/20989956/971070
        isScrollEnabled = false
        isScrollEnabled = true
    }
}
