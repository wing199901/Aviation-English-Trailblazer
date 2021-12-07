//
//  ATISTextView.swift
//  ATC
//
//  Created by Steven Siu  on 4/11/2020.
//  Copyright © 2020 Steven Siu . All rights reserved.
//

import UIKit.UITextView

/// Automatic Terminal Information Service (ATIS)
class ATISTextView: UITextView {
    // MARK: Properties
    
    var time: String = "" // The time show on the label.
    
    // MARK: - Initialization

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        textContainer?.maximumNumberOfLines = 5
        super.init(frame: frame, textContainer: textContainer)
        self.time = getTime()
//        textContainerInset = UIEdgeInsets(top: 15, left: 0, bottom: 0, right: 0)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Method
    /// Get current time and return to String.
    func getTime() -> String {
        let today = Date()
        let dateFormatter = DateFormatter()
        let timeZone = TimeZone(identifier: "UTC") // Aviation use UTC timezone
        
        dateFormatter.dateFormat = "HHmm"
        dateFormatter.timeZone = timeZone
        
        return dateFormatter.string(from: today)
    }
    
    // Update the label to newest information.
    func update(action: String, runway: String, degree: String, knot: String, information: String) {
        let action = action.removingCharacters(inCharacterSet: .decimalDigits).uppercased()
        
        var runway = runway
        if runway.contains("LEFT") {
            runway = runway.removingCharacters(inCharacterSet: .uppercaseLetters).trimmingCharacters(in: .whitespacesAndNewlines)
            runway += "L"
        } else if runway.contains("RIGHT") {
            runway = runway.removingCharacters(inCharacterSet: .uppercaseLetters).trimmingCharacters(in: .whitespacesAndNewlines)
            runway += "R"
        }
        
        attributedText = infoString(action: action, runway: runway, degree: degree, knot: knot, information: information)
    }
    
    
    
    func infoString(action: String, runway: String, degree: String, knot: String, information: String) -> NSMutableAttributedString {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center
        
        let titleAttribute: [NSAttributedString.Key: Any] = [
            .paragraphStyle: titleParagraphStyle,
            .font: UIFont(name: "MyriadPro-Regular", size: 28)!,
            .foregroundColor: UIColor.white
        ]
        
        let contentParagraphStyle = NSMutableParagraphStyle()
        contentParagraphStyle.alignment = .center
        
        let contentAttribute: [NSAttributedString.Key: Any] = [
            .paragraphStyle: contentParagraphStyle,
            .font: UIFont(name: "MyriadPro-Regular", size: 18)!,
            .foregroundColor: UIColor.white
        ]
        
        let completeText = NSMutableAttributedString(string: """
                                                     
                                                     ARCHERFIELD
                                                     \(action)\n
                                                     """,
                                                     attributes: titleAttribute)
        completeText.append(NSAttributedString(string: "INFO \(information) AT TIME \(time)\n", attributes: contentAttribute))
        completeText.append(NSAttributedString(string: "\(action) RUNWAY \(runway)\n", attributes: contentAttribute))
        completeText.append(NSAttributedString(string: "WIND \(degree) DEG \(knot) KT\n", attributes: contentAttribute))
        return completeText
    }
}
