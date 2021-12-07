//
//  MenuViewController.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

import Sucrose
import UIKit

protocol MenuViewNavigationDelegate: AnyObject {
    func didPressEnter(menuViewController: MenuViewController)
}

class MenuViewController: UIViewController {
    @IBOutlet private var enterButton: UIButton!

    weak var navigationDelegate: MenuViewNavigationDelegate?

    private var viewModel: MenuViewModelRepresentable

    init(viewModel: MenuViewModelRepresentable) {
        self.viewModel = viewModel

        // Get the view name
        super.init(nibName: MenuViewController.name, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func enterButtonAction(_ sender: UIButton) {
        navigationDelegate?.didPressEnter(menuViewController: self)
    }
}
