//
//  PlaneQtyLabel.swift
//  ATC
//
//  Created by Steven Siu  on 12/10/2020.
//  Copyright © 2020 Steven Siu . All rights reserved.
//

import UIKit.UITextView

/// A view that shows how many planes still remain.
class PlaneQtyLabel: UILabel {
    // MARK: Properties

    private var finishQty: Int = 0 { // The number of finished planes
//        willSet {
//            updateText()
//        }
        didSet {
            updateText()
        }
    }

    private var totalQty: Int = 0 // The number of total planes

    // MARK: Method

    /// Set the total number of plane and update the label
    func setTotal(total: Int) {
        totalQty = total
        updateText()
    }

    /// Updare the label
    func updateText() {
        DispatchQueue.main.async { [self] in
            attributedText = countString()
        }
    }

    /// Updare the label with remain number of plane.
//    func updateText(remain: Int) {
//        DispatchQueue.main.async { [self] in
//            finishPlaneQty = totalPlaneQty - remain
//            attributedText = countString()
//        }
//    }

    func getTotalQty() -> Int {
        totalQty
    }

    func getFinishQty() -> Int {
        finishQty
    }

    func finishQtyPlusOne() {
        finishQty += 1
    }

    /// PlaneQty
    func countString() -> NSMutableAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(named: "Plane Icon")
        let imageOffsetY: CGFloat = -5.0
        imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: imageAttachment.image!.size.width, height: imageAttachment.image!.size.height)
        /// Create string with attachment
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        /// Initialize mutable string
        let completeText = NSMutableAttributedString(string: "")
        /// Add image to mutable string
        completeText.append(attachmentString)
        /// Add your text to mutable string
        let textAfterIcon = NSAttributedString(string: String(format: " %d  /  %d", finishQty, totalQty))
        completeText.append(textAfterIcon)
        return completeText
    }
}
