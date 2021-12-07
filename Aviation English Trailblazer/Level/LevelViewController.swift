//
//  LevelViewController.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

import iCarousel
import Sucrose
import UIKit

protocol LevelViewNavigationDelegate: AnyObject {
    func didPressPlay(viewModel: LevelDetailViewModelRepresentable)
}

class LevelViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    @IBOutlet var carousel: iCarousel!

    weak var navigationDelegate: LevelViewNavigationDelegate?

    var viewModel: LevelViewModelRepresentable

    init(viewModel: LevelViewModelRepresentable) {
        self.viewModel = viewModel

        // Get the view name
        super.init(nibName: LevelViewController.name, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        carousel.type = .rotary
    }

    func numberOfItems(in carousel: iCarousel) -> Int {
//        viewModel.source.count
        5
    }

    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let levelView = LevelView(viewModel: LevelDetailViewModel(level: viewModel.source[index]))
        levelView.delegate = self

        return levelView
    }

    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        print("Tapped view number: ", index)
    }
}

extension LevelViewController: LevelViewDelegate {
    func didPressPlay(levelView: LevelView) {
        navigationDelegate?.didPressPlay(viewModel: levelView.viewModel)
    }
}
