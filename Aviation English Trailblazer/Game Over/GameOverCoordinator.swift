//
//  GameOverCoordinator.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

class GameOverCoordinator: Coordinator {
    func start() {
        
    }
    
    var coordinators: [Coordinator] = []
    weak var coordinatorDelegate: CoordinatorDelegate?

    private let navigator: NavigatorRepresentable

    init(navigator: NavigatorRepresentable) {
        self.navigator = navigator
    }

    func start(senderIDArr:[String]) {
        coordinatorDelegate?.coordinatorDidStart(self)
        navigator.transition(to: viewController(senderIDArr: senderIDArr), as: .push)
    }

    private func viewController(senderIDArr:[String]) -> GameOverViewController {
        let viewModel = GameOverViewModel(senderIDArr: senderIDArr)
        let viewController = GameOverViewController(viewModel: viewModel)
        viewController.navigationDelegate = self

        return viewController
    }
}

extension GameOverCoordinator: GameOverViewNavigationDelegate {
    func didPressBack(gameOverViewController: GameOverViewController) {
        let levelCoordinator = LevelCoordinator(navigator: navigator)
        levelCoordinator.coordinatorDelegate = self
        levelCoordinator.start()
    }
}
