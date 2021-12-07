//
//  MenuCoordinator.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

class MenuCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    weak var coordinatorDelegate: CoordinatorDelegate?

    private let navigator: NavigatorRepresentable

    init(navigator: NavigatorRepresentable) {
        self.navigator = navigator
    }

    func start() {
        coordinatorDelegate?.coordinatorDidStart(self)
        navigator.transition(to: viewController(), as: .push)
    }

    private func viewController() -> MenuViewController {
        let viewModel = MenuViewModel()
        let viewController = MenuViewController(viewModel: viewModel)
        viewController.navigationDelegate = self

        return viewController
    }
}

extension MenuCoordinator: MenuViewNavigationDelegate {
    func didPressEnter(menuViewController: MenuViewController) {
        let levelCoordinator = LevelCoordinator(navigator: navigator)
        levelCoordinator.coordinatorDelegate = self
        levelCoordinator.start()
    }
}
