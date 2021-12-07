//
//  Navigator.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

import UIKit

protocol NavigatorRepresentable {
    func root() -> UINavigationController
    func transition(to viewController: UIViewController, as type: NavigatorTransitionType)
    func dismiss()
    func pop()
}

struct Navigator: NavigatorRepresentable {
    private var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func root() -> UINavigationController {
        navigationController
    }

    func transition(to viewController: UIViewController, as type: NavigatorTransitionType) {
        switch type {
        case .root:
            navigationController.viewControllers = [viewController]
        case .push:
            navigationController.pushViewController(viewController, animated: true)
        case .modal:
            navigationController.present(viewController, animated: true, completion: nil)
        }
    }

    func dismiss() {
        navigationController.dismiss(animated: true, completion: nil)
    }

    func pop() {
        navigationController.popViewController(animated: true)
    }
}
