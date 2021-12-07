//
//  NibLoadable.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 5/11/2021.
//

import UIKit

protocol NibLoadable {
    func loadNib()
}

extension NibLoadable where Self: UIView {
    func loadNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)

        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }

        view.frame = bounds
        addSubview(view)
    }
}

extension UIView: NibLoadable {}
