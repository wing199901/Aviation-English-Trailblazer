//
//  UIImage+addTextToImage.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 29/10/2021.
//

import UIKit.UIImage

extension UIImage {
    func addTextToImage(image: UIImage, text: String) -> UIImage? {
        let imageView = UIImageView(image: image)
        imageView.backgroundColor = .clear
        imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)

        let label = UILabel(frame: imageView.bounds)
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.textColor = .white
        label.text = text
        label.font = UIFont.systemFont(ofSize: 60)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true

        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let imageWithText = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithText
    }
}
