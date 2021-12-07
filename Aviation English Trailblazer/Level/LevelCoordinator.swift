//
//  MenuCoordinator.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

class LevelCoordinator: Coordinator {
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

    private func viewController() -> LevelViewController {
        let viewModel = LevelViewModel()
        let viewController = LevelViewController(viewModel: viewModel)
        viewController.navigationDelegate = self

        return viewController
    }
}

extension LevelCoordinator: LevelViewNavigationDelegate {
    func didPressPlay(viewModel: LevelDetailViewModelRepresentable) {
        let gameCoordinator = GameCoordinator(navigator: navigator)
        gameCoordinator.coordinatorDelegate = self
        gameCoordinator.start(viewModel: viewModel)
    }
}
