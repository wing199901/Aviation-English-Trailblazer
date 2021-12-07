//
//  AppCoordinator.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

import UIKit

class AppCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    weak var coordinatorDelegate: CoordinatorDelegate?

    private let navigator: NavigatorRepresentable

    init(window: UIWindow, navigator: NavigatorRepresentable) {
        window.rootViewController = navigator.root()
        window.makeKeyAndVisible()

        self.navigator = navigator
    }

    func start() {
        let menuCoordinator = MenuCoordinator(navigator: navigator)
        menuCoordinator.coordinatorDelegate = self
        menuCoordinator.start()
    }
}
