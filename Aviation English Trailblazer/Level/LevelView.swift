//
//  LevelView.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 5/11/2021.
//

import UIKit

protocol LevelViewDelegate: AnyObject {
    func didPressPlay(levelView: LevelView)
}

class LevelView: UIView {
    @IBOutlet var levelLabel: UILabel!

    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var planeQtyLabel: UILabel!
    @IBOutlet var difficultySegmentedControl: UISegmentedControl!

    let viewModel: LevelDetailViewModelRepresentable
    weak var delegate: LevelViewDelegate?

    init(viewModel: LevelDetailViewModelRepresentable) {
        self.viewModel = viewModel
        super.init(frame: CGRect(x: 0, y: 0, width: 440, height: 640))

        loadNib()
        setupLevelLabel()
        setupDescription()
        setupPlaneQty()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLevelLabel() {
        levelLabel.text?.append(String(viewModel.id))
    }

    private func setupDescription() {
        descriptionTextView.text = viewModel.description
    }

    private func setupPlaneQty() {
        planeQtyLabel.text = String(viewModel.planeQty)
    }

    @IBAction func playButtonAction(_ sender: UIButton) {
        delegate?.didPressPlay(levelView: self)
    }
}
