//
//  Coordinator.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

protocol Coordinator: CoordinatorDelegate {
    var coordinatorDelegate: CoordinatorDelegate? { get set }
    var coordinators: [Coordinator] { get set }

    func start()
}

protocol CoordinatorDelegate: AnyObject {
    func coordinatorDidStart(_ coordinator: Coordinator)
    func coordinatorDidEnd(_ coordinator: Coordinator)
}

extension Coordinator {
    func coordinatorDidStart(_ coordinator: Coordinator) {
        coordinators.append(coordinator)
    }

    func coordinatorDidEnd(_ coordinator: Coordinator) {
        coordinators = coordinators.filter { $0 !== coordinator }
    }
}
