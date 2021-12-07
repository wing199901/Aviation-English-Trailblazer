//
//  GameCoordinator.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 8/11/2021.
//

class GameCoordinator: Coordinator {
    func start() {}

    var coordinators: [Coordinator] = []
    weak var coordinatorDelegate: CoordinatorDelegate?

    private let navigator: NavigatorRepresentable

    init(navigator: NavigatorRepresentable) {
        self.navigator = navigator
    }

    func start(viewModel: LevelDetailViewModelRepresentable) {
        coordinatorDelegate?.coordinatorDidStart(self)
        navigator.transition(to: viewController(viewModel: viewModel), as: .push)
    }

    private func viewController(viewModel: LevelDetailViewModelRepresentable) -> GameViewController {
        // let viewModel = GameViewModel()
        let viewcontroller = GameViewController(viewModel: viewModel)
        viewcontroller.navigationDelegate = self

        return viewcontroller
    }
}

extension GameCoordinator: GameViewControllerNavigation {
    func didPressExit(senderIDArr: [String]) {
        let gameOverCoordinator = GameOverCoordinator(navigator: navigator)
        gameOverCoordinator.coordinatorDelegate = self
        gameOverCoordinator.start(senderIDArr: senderIDArr)
    }
}
